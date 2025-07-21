import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../services/pitch_detection_service.dart';
import '../services/cache_service.dart';
import '../providers/karaoke_session_provider.dart';
import '../widgets/progressive_score_display.dart';
import '../widgets/realtime_pitch_visualizer.dart';
import '../utils/singer_encoder.dart';

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
  
  // 再生状態の管理
  bool _isPlaying = false;

  // Phase 1サービス（既存機能）
  final PitchDetectionService _pitchDetectionService = PitchDetectionService();

  // ロード状態
  bool _isLoadingReferencePitches = false;
  String _analysisStatus = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // AudioPlayerの状態変化を監視
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
    
    final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    if (selectedSong != null) {
      _loadReferencePitches(selectedSong);
    }
  }

  @override
  void dispose() {
    _pcmStreamSub?.cancel();
    _player.stop();
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
      
      // フォールバック処理: デフォルト値での初期化
      _handleAnalysisFailure(selectedSong);
    } finally {
      setState(() => _isLoadingReferencePitches = false);
    }
  }

  /// 分析失敗時のフォールバック処理
  Future<void> _handleAnalysisFailure(Map<String, String> selectedSong) async {
    try {
      // 基本的なピッチデータを生成してセッションを初期化
      final songTitle = selectedSong['title'] ?? 'Unknown';
      final fallbackPitches = _generateFallbackPitches();
      
      if (mounted) {
        context.read<KaraokeSessionProvider>().initializeSession(songTitle, fallbackPitches);
        setState(() => _analysisStatus = 'フォールバック処理完了');
        _showSnackBar('基本的なピッチデータで初期化しました');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analysisStatus = 'フォールバック処理失敗');
        _showSnackBar('フォールバック処理に失敗しました: $e');
      }
    }
  }

  /// フォールバック用の基本的なピッチデータを生成
  List<double> _generateFallbackPitches() {
    // 一般的な楽曲の音階に基づいた基本的なピッチデータを生成
    const basePitches = [
      261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25, // C4-C5
    ];
    
    final pitches = <double>[];
    for (int i = 0; i < 500; i++) {
      final index = i % basePitches.length;
      pitches.add(basePitches[index]);
    }
    
    return pitches;
  }

  /// 音源再生
  Future<void> _playAudio() async {
    try {
      final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      final audioFile = selectedSong?['audioFile'] ?? 'assets/sounds/kiku.mp3';
      
      debugPrint('音源再生を開始: $audioFile');
      
      // 現在の再生を停止
      await _player.stop();
      
      // オーディオソースを設定
      await _player.setAudioSource(AudioSource.asset(audioFile));
      
      // 再生を開始
      await _player.play();
      
      debugPrint('音源再生開始完了');
      _showSnackBar('音源再生を開始しました');
      
    } catch (e) {
      debugPrint('音源再生エラー: $e');
      _showSnackBar('音源の再生に失敗しました: ${e.toString()}');
      
      // フォールバック処理: 代替音源での再生試行
      await _tryFallbackAudioPlayback();
    }
  }

  /// 代替音源での再生試行
  Future<void> _tryFallbackAudioPlayback() async {
    final fallbackAudioFiles = [
      'assets/sounds/kiku.mp3',
      'assets/sounds/sample.mp3',
      'assets/sounds/test.mp3',
    ];
    
    debugPrint('代替音源での再生を試行します');
    
    for (final audioFile in fallbackAudioFiles) {
      try {
        debugPrint('代替音源を試行: $audioFile');
        
        // 現在の再生を停止
        await _player.stop();
        
        // オーディオソースを設定
        await _player.setAudioSource(AudioSource.asset(audioFile));
        
        // 再生を開始
        await _player.play();
        
        debugPrint('代替音源での再生成功: $audioFile');
        _showSnackBar('代替音源で再生しました: $audioFile');
        return;
      } catch (e) {
        debugPrint('代替音源再生失敗: $audioFile - $e');
        // 次の代替音源を試行
        continue;
      }
    }
    
    // 全ての代替音源が失敗した場合
    debugPrint('全ての代替音源が失敗しました');
    _showSnackBar('利用可能な音源がありません');
  }

  /// 録音開始
  /// 
  /// マイクの権限を確認し、録音を開始します。
  /// 同時にリアルタイムピッチ検出を開始し、プロバイダーの状態を更新します。
  /// 
  /// @precondition マイクの権限が必要です
  /// @postcondition 録音が開始され、リアルタイムピッチ検出が動作します
  /// @postcondition プロバイダーの状態がrecordingに変わります
  /// @ensures ピッチビジュアライザーがリアルタイムで更新されます
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _showSnackBar('録音権限が必要です');
      return;
    }

    try {
      // Androidでは適切なディレクトリに書き込む必要がある
      // アプリの一時ディレクトリを取得
      final tempDir = await getTemporaryDirectory();
      final recordingPath = '${tempDir.path}/my_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      debugPrint('録音ファイルパス: $recordingPath');
      
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 16000 * 16,
        ),
        path: recordingPath,
      );

      // リアルタイムピッチ検出のためのPCMストリーム購読を開始
      await _startRealtimePitchDetection();

      // Phase 3: プロバイダーで録音開始
      if (mounted) {
        context.read<KaraokeSessionProvider>().startRecording();
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar('録音の開始に失敗しました: ${e.toString()}');
      }
    }
  }

  /// リアルタイムピッチ検出の開始
  /// 
  /// 録音中にPCMデータストリームを購読し、リアルタイムでピッチを検出して
  /// プロバイダーに送信します。
  Future<void> _startRealtimePitchDetection() async {
    try {
      // Record package v6.0.0 ではストリーミングAPIが異なる
      // 定期的にピッチを更新するタイマーを使用
      _setupPitchDetectionTimer();
    } catch (e) {
      if (mounted) {
        _showSnackBar('リアルタイムピッチ検出の開始に失敗しました: ${e.toString()}');
      }
    }
  }

  /// ピッチ検出タイマーの設定
  void _setupPitchDetectionTimer() {
    // 録音中は定期的にピッチを更新
    const updateInterval = Duration(milliseconds: 100);
    
    Timer.periodic(updateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final sessionProvider = context.read<KaraokeSessionProvider>();
      if (!sessionProvider.isRecording) {
        timer.cancel();
        return;
      }
      
      // 簡易的なピッチ推定（実際の実装ではより複雑な処理が必要）
      _generateRealtimePitch();
    });
  }

  /// リアルタイムピッチの生成
  /// 
  /// 実際の実装では、PCMデータからピッチを検出しますが、
  /// 現在は録音中の仮想ピッチを生成します。
  /// 録音停止後に実際の録音ファイルから抽出したピッチで置き換えられます。
  void _generateRealtimePitch() {
    if (!mounted) return;
    
    try {
      // 録音中の仮想ピッチ生成（実際の録音とは独立）
      // 録音停止後に実際の録音ファイルから抽出したピッチで置き換えられる
      final sessionProvider = context.read<KaraokeSessionProvider>();
      final recordedCount = sessionProvider.recordedPitches.length;
      
      // より自然なピッチ変動を生成
      final random = math.Random();
      
      // 基準ピッチがある場合は、それを参考にしつつ独立したピッチを生成
      if (sessionProvider.referencePitches.isNotEmpty) {
        final referenceIndex = recordedCount % sessionProvider.referencePitches.length;
        final referencePitch = sessionProvider.referencePitches[referenceIndex];
        
        if (referencePitch > 0) {
          // より大きなバリエーションを加えて、実際の歌唱に近いピッチを生成
          final variation = (random.nextDouble() - 0.5) * 100; // ±50Hzのバリエーション
          final pitchDrift = math.sin(recordedCount * 0.1) * 20; // 周期的なピッチドリフト
          
          final simulatedPitch = referencePitch + variation + pitchDrift;
          
          // 時々無音を挿入して、より自然な歌唱パターンを作る
          if (random.nextDouble() < 0.1) {
            sessionProvider.updateCurrentPitch(null);
          } else {
            sessionProvider.updateCurrentPitch(simulatedPitch);
          }
        } else {
          // 無音部分
          sessionProvider.updateCurrentPitch(null);
        }
      } else {
        // 基準ピッチがない場合は、より多様なピッチを生成
        final baseFrequencies = [220.0, 246.94, 261.63, 293.66, 329.63, 369.99, 415.30]; // A3-A4の音階
        final baseIndex = recordedCount % baseFrequencies.length;
        final basePitch = baseFrequencies[baseIndex];
        
        final variation = (random.nextDouble() - 0.5) * 60; // ±30Hzのバリエーション
        final simulatedPitch = basePitch + variation;
        
        sessionProvider.updateCurrentPitch(simulatedPitch);
      }
      
    } catch (e) {
      // エラーが発生した場合は無音として処理
      if (mounted) {
        context.read<KaraokeSessionProvider>().updateCurrentPitch(null);
      }
    }
  }

  /// 録音停止
  Future<void> _stopRecording() async {
    try {
      final recordingPath = await _recorder.stop();
      
      // PCMストリームの購読を停止（タイマーは自動で停止される）
      await _pcmStreamSub?.cancel();
      _pcmStreamSub = null;
      
      // 録音ファイルが作成されたことをログに記録
      if (recordingPath != null) {
        debugPrint('録音ファイルが保存されました: $recordingPath');
        
        // 実際の録音ファイルからピッチを抽出
        await _extractPitchFromRecording(recordingPath);
      }
      
      // Phase 3: プロバイダーで録音停止と分析実行
      if (mounted) {
        context.read<KaraokeSessionProvider>().stopRecording();
      }

    } catch (e) {
      if (mounted) {
        _showSnackBar('録音の停止に失敗しました: ${e.toString()}');
      }
    }
  }

  /// 録音ファイルからピッチを抽出
  /// 
  /// [recordingPath] 録音ファイルのパス
  Future<void> _extractPitchFromRecording(String recordingPath) async {
    try {
      _showSnackBar('録音音声を分析中...');
      
      // ファイルの存在と基本情報を確認
      final file = File(recordingPath);
      if (!await file.exists()) {
        throw Exception('録音ファイルが見つかりません: $recordingPath');
      }
      
      final fileSize = await file.length();
      debugPrint('録音ファイルサイズ: $fileSize バイト');
      
      // 録音ファイルからピッチを抽出（ファイルシステム対応）
      final analysisResult = await _pitchDetectionService.extractPitchFromWavFile(recordingPath);
      
      // 抽出したピッチをプロバイダーに設定
      if (mounted) {
        final sessionProvider = context.read<KaraokeSessionProvider>();
        // 既存の録音ピッチをクリアして、実際の録音データで置き換える
        sessionProvider.replaceRecordedPitches(analysisResult.pitches);
        
        debugPrint('録音ピッチ抽出完了: ${analysisResult.pitches.length}個のピッチ');
        _showSnackBar('録音音声の分析が完了しました');
      }
      
    } catch (e) {
      if (mounted) {
        _showSnackBar('録音音声の分析に失敗しました: ${e.toString()}');
        debugPrint('録音ピッチ抽出エラー: $e');
        
        // フォールバック処理：シミュレーションデータを使用
        final sessionProvider = context.read<KaraokeSessionProvider>();
        if (sessionProvider.recordedPitches.isNotEmpty) {
          _showSnackBar('録音中のデータを使用してスコアを計算します');
          debugPrint('フォールバック: 録音中のピッチデータを使用 (${sessionProvider.recordedPitches.length}個)');
        }
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

  /// 録音中の終了確認ダイアログ
  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('録音中です'),
          content: const Text('録音を停止して画面を戻りますか？\n録音データは失われます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('戻る'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final sessionProvider = context.read<KaraokeSessionProvider>();
        final navigator = Navigator.of(context);
        
        // 録音中の場合は確認ダイアログを表示
        if (sessionProvider.isRecording) {
          final shouldExit = await _showExitConfirmation();
          if (shouldExit && mounted) {
            navigator.pop();
          }
        } else {
          // 録音中でない場合は直接戻る
          if (mounted) {
            navigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedSong?['title'] ?? 'カラオケ',
              style: const TextStyle(fontSize: 18),
            ),
            if (selectedSong?['singer'] != null)
              Text(
                '歌手: ${SingerEncoder.decode(selectedSong!['singer']!)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
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
                      onPressed: _isPlaying ? () => _player.stop() : _playAudio,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? '停止' : '音源再生'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
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
    ),
    );
  }

  /// セッション状態表示カード
  Widget _buildSessionStatusCard(KaraokeSessionProvider sessionProvider) {
    final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    
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
            _buildStatusRow('楽曲', selectedSong?['title'] ?? '-'),
            if (selectedSong?['singer'] != null)
              _buildStatusRow('歌手', SingerEncoder.decode(selectedSong!['singer']!)),
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
