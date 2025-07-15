import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import '../services/pitch_detection_service.dart';
import '../services/cache_service.dart';
import '../providers/song_result_provider.dart';
import '../widgets/song_result_widget.dart';

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

      setState(() {
        _referencePitches
          ..clear()
          ..addAll(jsonList.map((e) => (e as num).toDouble()));
        _analysisStatus = '手動データ読み込み完了';
      });
    } catch (e) {
      setState(() => _analysisStatus = 'データ読み込み失敗');
      _showSnackBar('ピッチデータの読み込みに失敗しました');
    }
  }

  /// SnackBarでメッセージを表示
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
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
      
      // Phase 3: 歌唱終了後、詳細な分析とスコア計算を実行
      await _calculateSongResult();
    } catch (e) {
      _showSnackBar('録音の停止に失敗しました');
    }
  }

  /// Phase 3: 包括的な歌唱結果の計算
  Future<void> _calculateSongResult() async {
    if (_referencePitches.isEmpty || _recordedPitches.isEmpty) {
      _showSnackBar('録音データまたは基準データが不足しています');
      return;
    }

    final provider = Provider.of<SongResultProvider>(context, listen: false);
    
    try {
      // 楽曲の推定時間（ピッチデータから推定）
      const double frameRate = 10.0; // 仮定: 10fps
      final duration = Duration(
        milliseconds: (_referencePitches.length / frameRate * 1000).round(),
      );

      await provider.calculateSongResult(
        songTitle: selectedSong?['title'] ?? '不明な楽曲',
        recordedPitches: List.from(_recordedPitches),
        referencePitches: List.from(_referencePitches),
        songDuration: duration,
      );
    } catch (e) {
      _showSnackBar('結果の計算中にエラーが発生しました: $e');
    }
  }

  /// Phase 2との互換性のための従来スコア計算（デバッグ用）
  double _calculateLegacyScore() {
    if (_referencePitches.isEmpty || _recordedPitches.isEmpty) return 0;

    final minLen = _referencePitches.length < _recordedPitches.length
        ? _referencePitches.length
        : _recordedPitches.length;

    int matchCount = 0;
    for (int i = 0; i < minLen; i++) {
      if ((_referencePitches[i] - _recordedPitches[i]).abs() < 30) {
        matchCount++;
      }
    }
    return (matchCount / minLen) * 100;
  }

  @override
  Widget build(BuildContext context) {
    // Phase 2との互換性のための従来スコア（デバッグ情報として残す）
    double legacyScore = _calculateLegacyScore();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSong?['title'] ?? 'カラオケ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), 
            onPressed: _clearCache, 
            tooltip: 'キャッシュクリア'
          ),
          // Phase 3: 結果リセット機能
          Consumer<SongResultProvider>(
            builder: (context, provider, child) {
              if (provider.currentResult != null) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => provider.clearResult(),
                  tooltip: '結果をクリア',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // コントロール部分
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        '状態: $_analysisStatus', 
                        style: TextStyle(color: Colors.blue[800]),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // 操作ボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _playAudio,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('音源再生'),
                      ),
                      
                      if (!kIsWeb)
                        ElevatedButton.icon(
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? '録音停止' : '録音開始'),
                        ),
                    ],
                  ),

                  if (kIsWeb) 
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Text(
                        'Webでは録音機能は利用できません',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // リアルタイムピッチ表示
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '現在のピッチ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_currentPitch?.toStringAsFixed(2) ?? "---"} Hz',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // デバッグ情報（開発用）
                  if (kDebugMode)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'デバッグ情報',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('従来スコア: ${legacyScore.toStringAsFixed(1)} 点'),
                          Text('基準ピッチ数: ${_referencePitches.length}'),
                          Text('録音ピッチ数: ${_recordedPitches.length}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Phase 3: 歌唱結果表示ウィジェット
            const SongResultWidget(),
          ],
        ),
      ),
    );
  }
}
