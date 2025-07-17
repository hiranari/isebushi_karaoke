import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/pitch_detection_service.dart';
import '../services/cache_service.dart';

class KaraokePage extends StatefulWidget {
  const KaraokePage({super.key});
  @override
  State<KaraokePage> createState() => _KaraokePageState();
}

class _KaraokePageState extends State<KaraokePage> {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmStreamSub;
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
      final pitchService = PitchDetectionService();
      final stats = pitchService.getPitchStatistics(pitches);
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
      // 録音開始
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: 'my_voice.wav', // 必須パラメータを追加
      );

      // Timer を使用してピッチ検出を定期実行
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        if (!_isRecording) {
          timer.cancel();
          return;
        }

      try {
        // 現在の録音ストリームから振幅データを取得
        final amplitude = await _recorder.getAmplitude();
        
        // 実際のピッチ検出は録音停止後にファイルから行う
        // リアルタイム表示用のダミーピッチ（振幅ベース）
        if (amplitude.current > -30) { // ある程度の音量がある場合
          // 振幅から推定ピッチを計算（簡易実装）
          final estimatedPitch = _estimatePitchFromAmplitude(amplitude.current);
          setState(() {
            _currentPitch = estimatedPitch;
            if (_currentPitch != null && _currentPitch! > 0) {
              _recordedPitches.add(_currentPitch!);
            }
          });
        } else {
          setState(() => _currentPitch = null);
        }
      } catch (e) {
        // エラーは無視してタイマー継続
      }
    });

    setState(() => _isRecording = true);
    } catch (e) {
      _showSnackBar('録音の開始に失敗しました: $e');
    }
  }

  /// 振幅からピッチを推定（簡易実装）
/// 実際のピッチ検出はPhase 2で改善予定
double? _estimatePitchFromAmplitude(double amplitude) {
  // TODO: Phase 2でより正確なリアルタイムピッチ検出を実装
  // 現在は振幅ベースの簡易推定
  if (amplitude < -40) return null; // 音量が小さすぎる
  
  // 振幅を基にした簡易ピッチ推定（200-800Hzの範囲）
  final normalizedAmp = (amplitude + 60) / 60; // -60dB～0dBを0～1に正規化
  final estimatedPitch = 200 + (normalizedAmp * 600); // 200～800Hz
  
  return estimatedPitch.clamp(200.0, 800.0);
}

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        // TODO: Phase 2で録音ファイルからの正確なピッチ検出を実装
        _showSnackBar('録音を停止しました。ファイル: $path');
      }
    } catch (e) {
      _showSnackBar('録音の停止に失敗しました: $e');
    }
  }

  double _calculateScore() {
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
    double score = _calculateScore();
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSong?['title'] ?? 'カラオケ'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _clearCache, tooltip: 'キャッシュクリア'),
        ],
      ),
      body: Center(
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
            Text('スコア: ${score.toStringAsFixed(1)} 点'),
            const SizedBox(height: 10),
            Text('基準ピッチ数: ${_referencePitches.length}'),
            Text('録音ピッチ数: ${_recordedPitches.length}'),
          ],
        ),
      ),
    );
  }
}
