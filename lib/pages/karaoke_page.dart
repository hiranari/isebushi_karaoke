import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/pitch_detection_service.dart';
import '../services/cache_service.dart';
import '../services/pitch_comparison_service.dart';
import '../models/pitch_comparison_result.dart';

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
  
  // Phase 2で追加
  final PitchComparisonService _pitchComparisonService = PitchComparisonService();
  PitchComparisonResult? _lastComparisonResult;

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
    } catch (e) {
      _showSnackBar('録音の停止に失敗しました');
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

  /// Phase 2: 高精度ピッチ比較の実行
  Future<void> _performDetailedComparison() async {
    if (_referencePitches.isEmpty || _recordedPitches.isEmpty) {
      _showSnackBar('比較するデータが不足しています');
      return;
    }

    setState(() => _analysisStatus = 'high precision 精密ピッチ比較中...');

    try {
      final result = await _pitchComparisonService.compareWithDTW(
        referencePitches: _referencePitches,
        singingPitches: _recordedPitches,
      );

      setState(() {
        _lastComparisonResult = result;
        _analysisStatus = '精密比較完了';
      });

      _showSnackBar('精密ピッチ比較が完了しました');
    } catch (e) {
      setState(() => _analysisStatus = '精密比較エラー');
      _showSnackBar('精密比較でエラーが発生しました: $e');
      print('精密比較エラー: $e');
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

              // 基本コントロール
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

              // Phase 2: 精密比較ボタン
              if (_referencePitches.isNotEmpty && _recordedPitches.isNotEmpty)
                ElevatedButton(
                  onPressed: _performDetailedComparison,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('精密ピッチ比較'),
                ),

              const SizedBox(height: 20),

              // 基本情報表示
              _buildBasicInfoCard(score),

              const SizedBox(height: 20),

              // Phase 2: 詳細比較結果表示
              if (_lastComparisonResult != null) ...[
                _buildDetailedComparisonResults(),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 基本情報カード
  Widget _buildBasicInfoCard(double score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '基本情報',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text('現在のピッチ: ${_currentPitch?.toStringAsFixed(2) ?? "-"} Hz'),
            Text('基本スコア: ${score.toStringAsFixed(1)} 点'),
            Text('基準ピッチ数: ${_referencePitches.length}'),
            Text('録音ピッチ数: ${_recordedPitches.length}'),
          ],
        ),
      ),
    );
  }

  /// Phase 2: 詳細比較結果表示
  Widget _buildDetailedComparisonResults() {
    final result = _lastComparisonResult!;
    final summary = result.getSummary();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '精密比較結果 (Phase 2)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 15),

            // 総合スコア
            _buildScoreRow('総合スコア', result.overallScore, Colors.blue),
            
            // ピッチ精度
            _buildScoreRow('平均セント差', summary['averageCentDifference'], Colors.orange),
            
            // 安定性
            _buildScoreRow('ピッチ安定性', result.stabilityAnalysis.stabilityScore, Colors.green),
            
            // タイミング
            _buildScoreRow('タイミング精度', result.timingAnalysis.accuracyScore, Colors.purple),

            const SizedBox(height: 15),

            // ビブラート情報
            _buildVibratoInfo(result.vibratoAnalysis),

            const SizedBox(height: 15),

            // 詳細統計
            _buildDetailedStats(result),
          ],
        ),
      ),
    );
  }

  /// スコア行表示
  Widget _buildScoreRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ビブラート情報表示
  Widget _buildVibratoInfo(VibratoAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: analysis.vibratoDetected ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: analysis.vibratoDetected ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                analysis.vibratoDetected ? Icons.music_note : Icons.music_off,
                color: analysis.vibratoDetected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'ビブラート ${analysis.vibratoDetected ? "検出" : "未検出"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: analysis.vibratoDetected ? Colors.green[800] : Colors.grey[600],
                ),
              ),
            ],
          ),
          if (analysis.vibratoDetected) ...[
            const SizedBox(height: 8),
            Text('レート: ${analysis.vibratoRate.toStringAsFixed(1)} Hz'),
            Text('深さ: ${analysis.vibratoDepth.toStringAsFixed(1)} cents'),
            Text('規則性: ${analysis.vibratoRegularityScore.toStringAsFixed(1)}%'),
          ],
        ],
      ),
    );
  }

  /// 詳細統計表示
  Widget _buildDetailedStats(PitchComparisonResult result) {
    return ExpansionTile(
      title: const Text('詳細統計'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('アライメント済みピッチ数: ${result.alignedPitches.length}'),
              Text('不安定区間数: ${result.stabilityAnalysis.unstableRegionCount}'),
              Text('最大セント差: ${result.centDifferences.isEmpty ? "N/A" : result.centDifferences.map((d) => d.abs()).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}'),
              Text('タイミング遅延数: ${result.timingAnalysis.significantDelayCount}'),
              Text('最大時間ずれ: ${result.timingAnalysis.maxTimeOffset.toStringAsFixed(1)} ms'),
              const SizedBox(height: 8),
              Text('解析日時: ${result.analyzedAt.toString().substring(0, 19)}'),
            ],
          ),
        ),
      ],
    );
  }
}
