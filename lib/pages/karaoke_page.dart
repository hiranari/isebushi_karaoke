import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';

import '../services/pitch_detection_service.dart';
import '../services/cache_service.dart';
import '../providers/karaoke_session_provider.dart';
import '../widgets/progressive_score_display.dart';
import '../widgets/realtime_pitch_visualizer.dart';

/// Phase 3: 新しいアーキテクチャを使用したカラオケページ
/// 
/// 単一責任の原則に従い、UIの表示とユーザーインタラクションのみを担当します。
/// ビジネスロジックはサービスクラスとプロバイダーに委譲されています。
class KaraokePage extends StatefulWidget {
  const KaraokePage({super.key});
  @override
  State<KaraokePage> createState() => _KaraokePageState();
}

class _KaraokePageState extends State<KaraokePage> {
  // オーディオ関連
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmStreamSub;

  // Phase 1サービス（既存機能）
  final PitchDetectionService _pitchDetectionService = PitchDetectionService();

  // ロード状態
  bool _isLoadingReferencePitches = false;
  String _analysisStatus = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    if (selectedSong != null) {
      _loadReferencePitches(selectedSong);
    }
  }

  @override
  void dispose() {
    _pcmStreamSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// 基準ピッチデータの読み込み（Phase 1機能を維持）
  Future<void> _loadReferencePitches(Map<String, String> selectedSong) async {
    setState(() {
      _isLoadingReferencePitches = true;
      _analysisStatus = 'ピッチデータを確認中...';
    });

    try {
      final audioFile = selectedSong['audioFile']!;
      final songTitle = selectedSong['title']!;

      // キャッシュから読み込み試行
      setState(() => _analysisStatus = 'キャッシュを確認中...');
      final cachedResult = await CacheService.loadFromCache(audioFile);

      List<double> pitches;
      if (cachedResult != null) {
        pitches = cachedResult.pitches;
        setState(() => _analysisStatus = 'キャッシュから読み込み完了');
        _showSnackBar('キャッシュからピッチデータを読み込みました');
      } else {
        // 新規解析
        setState(() => _analysisStatus = 'ピッチデータを解析中...');
        _showSnackBar('ピッチデータを解析中...');

        final analysisResult = audioFile.toLowerCase().endsWith('.wav')
            ? await _pitchDetectionService.extractPitchFromWav(audioFile)
            : await _pitchDetectionService.extractPitchFromMp3(audioFile);

        pitches = analysisResult.pitches;
        await CacheService.saveToCache(audioFile, analysisResult);
        setState(() => _analysisStatus = '解析完了・キャッシュ保存済み');
        _showSnackBar('ピッチデータの解析が完了しました');
      }

      // Phase 3: プロバイダーでセッション初期化
      if (mounted) {
        context.read<KaraokeSessionProvider>().initializeSession(songTitle, pitches);
      }

    } catch (e) {
      setState(() => _analysisStatus = '解析失敗');
      _showSnackBar('ピッチデータの解析に失敗しました: $e');
      // TODO: フォールバック処理
    } finally {
      setState(() => _isLoadingReferencePitches = false);
    }
  }

  /// 音源再生
  Future<void> _playAudio() async {
    try {
      final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      final audioFile = selectedSong?['audioFile'] ?? 'assets/sounds/kiku.mp3';
      await _player.setAudioSource(AudioSource.asset(audioFile));
      _player.play();
    } catch (e) {
      _showSnackBar('音源の再生に失敗しました');
    }
  }

  /// 録音開始
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('録音権限が必要です');
      return;
    }

    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16000 * 16,
        ),
        path: 'my_voice.wav',
      );

      // 簡略化されたピッチ検出（リアルタイム処理を削除）
      // Phase 3: プロバイダーで録音開始
      if (mounted) {
        context.read<KaraokeSessionProvider>().startRecording();
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar('録音の開始に失敗しました');
      }
    }
  }

  /// 録音停止
  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      await _pcmStreamSub?.cancel();
      
      // Phase 3: プロバイダーで録音停止と分析実行
      if (mounted) {
        context.read<KaraokeSessionProvider>().stopRecording();
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar('録音の停止に失敗しました');
      }
    }
  }

  /// セッションリセット
  void _resetSession() {
    context.read<KaraokeSessionProvider>().resetSession();
  }

  /// SnackBar表示
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSong?['title'] ?? 'カラオケ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSession,
            tooltip: 'セッションリセット',
          ),
        ],
      ),
      body: Consumer<KaraokeSessionProvider>(
        builder: (context, sessionProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ピッチデータ読み込み状態
                if (_isLoadingReferencePitches) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(_analysisStatus),
                  const SizedBox(height: 20),
                ],

                // 解析状況表示
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

                // リアルタイムピッチ可視化
                if (sessionProvider.referencePitches.isNotEmpty)
                  RealtimePitchVisualizer(
                    currentPitch: sessionProvider.currentPitch,
                    referencePitches: sessionProvider.referencePitches,
                    recordedPitches: sessionProvider.recordedPitches,
                    isRecording: sessionProvider.isRecording,
                  ),

                const SizedBox(height: 20),

                // コントロールボタン
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
                        onPressed: sessionProvider.isRecording ? _stopRecording : _startRecording,
                        icon: Icon(sessionProvider.isRecording ? Icons.stop : Icons.mic),
                        label: Text(sessionProvider.isRecording ? '録音停止' : '録音開始'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sessionProvider.isRecording ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),

                if (kIsWeb) ...[
                  const SizedBox(height: 10),
                  const Text('Webでは録音機能は利用できません'),
                ],

                const SizedBox(height: 20),

                // セッション状態表示
                _buildSessionStatusCard(sessionProvider),

                const SizedBox(height: 20),

                // Phase 3: プログレッシブスコア表示
                if (sessionProvider.songResult != null)
                  ProgressiveScoreDisplay(
                    songResult: sessionProvider.songResult!,
                    displayMode: sessionProvider.scoreDisplayMode,
                    onTap: () => sessionProvider.toggleScoreDisplay(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// セッション状態表示カード
  Widget _buildSessionStatusCard(KaraokeSessionProvider sessionProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'セッション状態',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildStatusRow('状態', _getStateText(sessionProvider.state)),
            _buildStatusRow('現在のピッチ', 
                sessionProvider.currentPitch?.toStringAsFixed(2) ?? '-'),
            _buildStatusRow('基準ピッチ数', '${sessionProvider.referencePitches.length}'),
            _buildStatusRow('録音ピッチ数', '${sessionProvider.recordedPitches.length}'),
            if (sessionProvider.errorMessage.isNotEmpty)
              Text(
                'エラー: ${sessionProvider.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  /// ステータス行
  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// 状態テキスト取得
  String _getStateText(KaraokeSessionState state) {
    switch (state) {
      case KaraokeSessionState.ready:
        return '準備完了';
      case KaraokeSessionState.recording:
        return '録音中';
      case KaraokeSessionState.analyzing:
        return '分析中';
      case KaraokeSessionState.completed:
        return '完了';
      case KaraokeSessionState.error:
        return 'エラー';
    }
  }
}
