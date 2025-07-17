import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../services/pitch_detection_service.dart';
import '../services/cache_service.dart';
import '../services/karaoke_session_notifier.dart';
import '../widgets/overall_score_widget.dart';
import '../widgets/detailed_analysis_widget.dart';
import '../widgets/improvement_suggestions_widget.dart';

/// Phase 3統合カラオケページ
/// 従来の録音機能 + 新しい総合スコアリングシステム
class KaraokePage extends StatefulWidget {
  const KaraokePage({super.key});
  @override
  State<KaraokePage> createState() => _KaraokePageState();
}

class _KaraokePageState extends State<KaraokePage> {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmStreamSub;
  PitchDetector? _pitchDetector;
  bool _isRecording = false;
  bool _isLoadingReferencePitches = false;
  double? _currentPitch;
  final List<double> _recordedPitches = [];
  final List<double> _referencePitches = [];
  Map<String, String>? selectedSong;
  String _analysisStatus = '';

  // Phase 1で追加
  final PitchDetectionService _pitchDetectionService = PitchDetectionService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    _loadReferencePitches();
  }

  /// 基準ピッチデータの読み込み（Phase 1で自動化）
  Future<void> _loadReferencePitches() async {
    if (selectedSong == null) return;

    setState(() {
      _isLoadingReferencePitches = true;
      _analysisStatus = 'ピッチデータを確認中...';
    });

    try {
      final audioFile = selectedSong!['audioFile']!;

      // キャッシュから読み込み試行
      setState(() => _analysisStatus = 'キャッシュを確認中...');
      final cachedResult = await CacheService.loadFromCache(audioFile);

      List<double> pitches;
      if (cachedResult != null) {
        // キャッシュが存在する場合
        pitches = cachedResult.pitches;
        setState(() => _analysisStatus = 'キャッシュから読み込み完了');
        _showSnackBar('キャッシュからピッチデータを読み込みました');
      } else {
        // キャッシュが存在しない場合は新規解析
        setState(() => _analysisStatus = 'ピッチデータを解析中...');
        _showSnackBar('ピッチデータを解析中...');

        // ファイル拡張子をチェック
        final analysisResult = audioFile.toLowerCase().endsWith('.wav')
            ? await _pitchDetectionService.extractPitchFromWav(audioFile)
            : await _pitchDetectionService.extractPitchFromMp3(audioFile);

        pitches = analysisResult.pitches;

        // 結果をキャッシュに保存
        await CacheService.saveToCache(audioFile, analysisResult);
        setState(() => _analysisStatus = '解析完了・キャッシュ保存済み');
        _showSnackBar('ピッチデータの解析が完了しました');
      }

      setState(() {
        _referencePitches
          ..clear()
          ..addAll(pitches);
      });

      // Phase 3: セッション初期化
      if (mounted) {
        final sessionNotifier = Provider.of<KaraokeSessionNotifier>(context, listen: false);
        sessionNotifier.initializeSession(
          songTitle: selectedSong!['title']!,
          referencePitches: pitches,
        );
      }

      // 統計情報を表示
      final stats = PitchDetectionService.getPitchStatistics(pitches);
      print('ピッチ統計: $stats');
    } catch (e) {
      setState(() => _analysisStatus = '自動解析失敗・手動データ使用');
      print('自動解析エラー: $e');

      // フォールバック: 従来の手動JSONファイル読み込み
      await _loadPitchesFromJson();
      _showSnackBar('自動解析に失敗しました。手動データを使用します。');
    } finally {
      setState(() => _isLoadingReferencePitches = false);
    }
  }

  /// 従来のJSONファイルからピッチデータを読み込み（フォールバック用）
  Future<void> _loadPitchesFromJson() async {
    try {
      final pitchFile = selectedSong?['pitchFile'] ?? 'assets/pitch/kiku_pitches.json';
      final jsonStr = await rootBundle.loadString(pitchFile);
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      final pitches = jsonList.map((e) => (e as num).toDouble()).toList();

      setState(() {
        _referencePitches
          ..clear()
          ..addAll(pitches);
        _analysisStatus = '手動データ読み込み完了';
      });

      // Phase 3: セッション初期化
      if (mounted) {
        final sessionNotifier = Provider.of<KaraokeSessionNotifier>(context, listen: false);
        sessionNotifier.initializeSession(
          songTitle: selectedSong!['title']!,
          referencePitches: pitches,
        );
      }
    } catch (e) {
      setState(() => _analysisStatus = 'データ読み込み失敗');
      _showSnackBar('ピッチデータの読み込みに失敗しました');
    }
  }

  @override
  void dispose() {
    _pcmStreamSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    try {
      final audioFile = selectedSong?['audioFile'] ?? 'assets/sounds/kiku.mp3';
      await _player.setAudioSource(AudioSource.asset(audioFile));
      _player.play();
    } catch (e) {
      _showSnackBar('音源の再生に失敗しました');
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('録音権限が必要です');
      return;
    }

    try {
      await _recorder.start(
        config: const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16000 * 16,
        ),
        path: 'my_voice.wav',
      );

      _pitchDetector = PitchDetector(16000, 1024);

      final stream = await _recorder.recordStream();
      _pcmStreamSub = stream.listen((buffer) {
        if (_pitchDetector != null) {
          final samples = Int16List.view(buffer.buffer).map((e) => e.toDouble()).toList();
          final result = _pitchDetector!.getPitch(samples);
          setState(() {
            _currentPitch = result.pitched ? result.pitch : null;
            if (_isRecording && _currentPitch != null && _currentPitch! > 0) {
              _recordedPitches.add(_currentPitch!);
              
              // Phase 3: リアルタイムでピッチ追加
              final sessionNotifier = Provider.of<KaraokeSessionNotifier>(context, listen: false);
              sessionNotifier.addRecordedPitch(_currentPitch!);
            }
          });
        }
      });

      setState(() => _isRecording = true);
    } catch (e) {
      _showSnackBar('録音の開始に失敗しました');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      await _pcmStreamSub?.cancel();
      setState(() => _isRecording = false);

      // Phase 3: 録音終了と結果計算
      final sessionNotifier = Provider.of<KaraokeSessionNotifier>(context, listen: false);
      sessionNotifier.updateRecordedPitches(_recordedPitches);
      await sessionNotifier.finishRecordingAndCalculateResults();
    } catch (e) {
      _showSnackBar('録音の停止に失敗しました');
    }
  }

  /// SnackBarでメッセージを表示
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2))
      );
    }
  }

  /// キャッシュクリア機能
  Future<void> _clearCache() async {
    if (selectedSong == null) return;

    try {
      await CacheService.clearCache(selectedSong!['audioFile']!);
      _showSnackBar('キャッシュをクリアしました');

      // 再解析
      await _loadReferencePitches();
    } catch (e) {
      _showSnackBar('キャッシュクリアに失敗しました');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSong?['title'] ?? 'カラオケ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearCache,
            tooltip: 'キャッシュクリア',
          ),
        ],
      ),
      body: Consumer<KaraokeSessionNotifier>(
        builder: (context, sessionNotifier, child) {
          // Phase 3: プログレッシブディスクロージャー
          switch (sessionNotifier.displayState) {
            case KaraokeDisplayState.overallScore:
              return OverallScoreWidget(
                result: sessionNotifier.currentResult!,
                onShowDetails: sessionNotifier.showDetailedAnalysis,
              );
            
            case KaraokeDisplayState.detailedAnalysis:
              return DetailedAnalysisWidget(
                result: sessionNotifier.currentResult!,
                onShowSuggestions: sessionNotifier.showImprovementSuggestions,
                onBackToScore: sessionNotifier.backToOverallScore,
              );
            
            case KaraokeDisplayState.improvementSuggestions:
              return ImprovementSuggestionsWidget(
                result: sessionNotifier.currentResult!,
                onBackToAnalysis: sessionNotifier.backToDetailedAnalysis,
                onRestartSession: () {
                  sessionNotifier.restartSession();
                  _recordedPitches.clear();
                },
              );
            
            case KaraokeDisplayState.recording:
            default:
              return _buildRecordingView(context, sessionNotifier);
          }
        },
      ),
    );
  }

  Widget _buildRecordingView(BuildContext context, KaraokeSessionNotifier sessionNotifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ピッチデータ読み込み状態の表示
          if (_isLoadingReferencePitches)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Text(_analysisStatus),
                const SizedBox(height: 20),
              ],
            ),

          // Phase 1で追加: 解析状況表示
          if (!_isLoadingReferencePitches && _analysisStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text('状態: $_analysisStatus', style: TextStyle(color: Colors.blue[800])),
            ),

          ElevatedButton(onPressed: _playAudio, child: const Text('音源を再生')),

          const SizedBox(height: 10),

          if (!kIsWeb)
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
              ),
              child: Text(_isRecording ? '録音停止' : '録音開始'),
            ),

          if (kIsWeb) const Text('Webでは録音機能は利用できません'),

          const SizedBox(height: 20),
          Text('現在のピッチ: ${_currentPitch?.toStringAsFixed(2) ?? "-"} Hz'),
          const SizedBox(height: 20),
          
          // Phase 3: 簡単な録音状況表示
          Text('基準ピッチ数: ${_referencePitches.length}'),
          Text('録音ピッチ数: ${_recordedPitches.length}'),

          // エラー表示
          if (sessionNotifier.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                sessionNotifier.errorMessage!,
                style: TextStyle(color: Colors.red[800]),
              ),
            ),

          // ローディング表示
          if (sessionNotifier.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('結果を計算中...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}