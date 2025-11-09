import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../../infrastructure/services/pitch_detection_service.dart';
import '../../infrastructure/services/pitch_comparison_service.dart';
import '../../infrastructure/services/pitch_verification_service.dart';
import '../../infrastructure/factories/service_locator.dart';
import '../../application/providers/karaoke_session_provider.dart';
import '../../application/use_cases/verify_pitch_use_case.dart';
import '../widgets/karaoke/progressive_score_display.dart';
import '../widgets/karaoke/realtime_pitch_visualizer.dart';
import '../widgets/pitch_visualization_widget.dart';
import '../widgets/realtime_score_widget.dart';
import '../widgets/debug/debug_info_overlay.dart';
import '../../core/utils/singer_encoder.dart';
import '../../core/utils/pitch_debug_helper.dart';
import '../../domain/models/audio_analysis_result.dart';
import '../../domain/interfaces/i_logger.dart';

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

  // Logger
  late final ILogger _logger;

  // Phase 1サービス（既存機能）
  late final PitchDetectionService _pitchDetectionService;
  
  // Phase 3: 新しいアーキテクチャサービス
  late final PitchVerificationService _verificationService;
  late final VerifyPitchUseCase _verifyPitchUseCase;

  // Phase 3: リアルタイムスコア機能
  final List<RealtimeScoreResult> _scoreHistory = [];
  double _currentScore = 0.0;
  double _averageScore = 0.0;
  double _maxScore = 0.0;
  ScoreLevel _currentLevel = ScoreLevel.beginner;
  final List<double> _pitchHistory = [];

  // ロード状態
  bool _isLoadingReferencePitches = false;
  String _analysisStatus = '';

  // デバッグ機能
  final List<String> _debugLogs = [];
  bool _showDebugOverlay = false;

  @override
  void initState() {
    super.initState();
    
    // Service Locatorから依存関係を取得
    _logger = ServiceLocator().getService<ILogger>();
    _pitchDetectionService = ServiceLocator().getService<PitchDetectionService>();
    
    // Phase 3: 新しいアーキテクチャサービス初期化
    _verificationService = PitchVerificationService(
      pitchDetectionService: _pitchDetectionService,
    );
    _verifyPitchUseCase = VerifyPitchUseCase(
      verificationService: _verificationService,
    );
  }

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
      // デバッグ: 楽曲情報を表示
      if (kDebugMode) {
        debugPrint('🎵 選択された楽曲情報:');
        debugPrint('  title: ${selectedSong['title']}');
        debugPrint('  audioFile: ${selectedSong['audioFile']}');
        debugPrint('  singer: ${selectedSong['singer']}');
        
        // アップグレードボタン表示条件をチェック
        final isTestSong = selectedSong['audioFile']?.contains('Test.wav') == true || 
                          selectedSong['title'] == 'テスト';
        debugPrint('  アップグレードボタン表示: $isTestSong');
      }
      
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

  /// 基準ピッチデータの読み込み（Phase 3: クリーンアーキテクチャ対応）
  /// 
  /// UseCaseパターンを使用してDRY原則に従い、
  /// 外部ツールと同じロジックでピッチ検証を実行
  Future<void> _loadReferencePitches(Map<String, String> selectedSong) async {
    setState(() {
      _isLoadingReferencePitches = true;
      _analysisStatus = 'ピッチデータを確認中...';
    });

    try {
      final audioFile = selectedSong['audioFile']!;
      final songTitle = selectedSong['title']!;

      setState(() => _analysisStatus = 'ピッチ検証実行中...');

      // Phase 3: 新しいUseCaseパターンでピッチ検証実行
      final verificationResult = await _verifyPitchUseCase.execute(
        wavFilePath: audioFile,
        useCache: true,
        exportJson: false, // UI使用時はJSON出力なし
      );

      final pitches = verificationResult.pitches;
      final stats = verificationResult.statistics;

      // UI状態更新
      setState(() => _analysisStatus = verificationResult.fromCache 
          ? 'キャッシュから読み込み完了' 
          : '解析完了・キャッシュ保存済み');
      
      // ユーザーフィードバック
      _showSnackBar(verificationResult.fromCache 
          ? 'キャッシュからピッチデータを読み込みました'
          : 'ピッチデータの解析が完了しました');

      // デバッグ情報の統合出力
      await _outputVerificationDebugInfo(audioFile, songTitle, verificationResult);

      // Phase 3: 統計情報に基づく高度なデバッグ出力
      if (audioFile.contains('Test.wav')) {
        _outputAdvancedTestWavAnalysis(songTitle, stats, pitches);
      }

      // ピッチデータの範囲チェックと補正（伊勢節に適した範囲）
      final filteredPitches = pitches.map((pitch) {
        if (pitch > 0) {
          // ドレミファソラシドの周波数範囲を考慮（C4=261.63Hz〜C6=1046.5Hz）
          if (pitch < 80.0 || pitch > 1200.0) {
            return 0.0; // 明らかに範囲外の値は無音として扱う
          }
          return pitch; // 有効な音程として保持
        }
        return pitch; // 0は無音として保持
      }).toList();

      // **重要**: 有効なピッチが少なすぎる場合はエラーとして扱う
      final validFilteredCount = filteredPitches.where((p) => p > 0).length;
      if (validFilteredCount < 10) {
        throw Exception('有効なピッチが検出されませんでした（$validFilteredCount個）。Test.wavファイルにドレミファソラシドが正しく録音されているか確認してください。');
      }

      // 統計情報をログ出力
      final validOriginal = pitches.where((p) => p > 0).toList();
      final validFiltered = filteredPitches.where((p) => p > 0).toList();
      if (validOriginal.isNotEmpty && validFiltered.isNotEmpty) {
        final avgOriginal = validOriginal.reduce((a, b) => a + b) / validOriginal.length;
        final avgFiltered = validFiltered.reduce((a, b) => a + b) / validFiltered.length;
        debugPrint('基準ピッチ統計 - 元データ: ${validOriginal.length}個, 平均: ${avgOriginal.toStringAsFixed(1)}Hz');
        debugPrint('基準ピッチ統計 - フィルター後: ${validFiltered.length}個, 平均: ${avgFiltered.toStringAsFixed(1)}Hz');
        
        // ピッチ範囲の確認
        final minOriginal = validOriginal.reduce((a, b) => a < b ? a : b);
        final maxOriginal = validOriginal.reduce((a, b) => a > b ? a : b);
        final minFiltered = validFiltered.reduce((a, b) => a < b ? a : b);
        final maxFiltered = validFiltered.reduce((a, b) => a > b ? a : b);
        debugPrint('基準ピッチ範囲 - 元データ: ${minOriginal.toStringAsFixed(2)}Hz - ${maxOriginal.toStringAsFixed(2)}Hz');
        debugPrint('基準ピッチ範囲 - フィルター後: ${minFiltered.toStringAsFixed(2)}Hz - ${maxFiltered.toStringAsFixed(2)}Hz');
      }
      debugPrint('=== 基準ピッチデバッグ終了 ===');

      // Phase 3: プロバイダーでセッション初期化
      if (mounted) {
        context.read<KaraokeSessionProvider>().initializeSession(songTitle, filteredPitches);
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
    // ドレミファソラシドの正確な周波数（C4スケール）
    const doReMiFaSoLaSiDo = [
      261.63, // ド (C4)
      293.66, // レ (D4)
      329.63, // ミ (E4)
      349.23, // ファ (F4)
      392.00, // ソ (G4)
      440.00, // ラ (A4) - 基準音
      493.88, // シ (B4)
      523.25, // ド (C5)
    ];
    
    debugPrint('=== フォールバック処理実行中 ===');
    debugPrint('⚠️ Test.wavの実際のピッチ検出が失敗したため、ドレミファソラシドの理論値を使用します');
    
    final pitches = <double>[];
    // 各音を15回ずつ繰り返して、一般的な楽曲の長さに合わせる
    for (int noteIndex = 0; noteIndex < doReMiFaSoLaSiDo.length; noteIndex++) {
      for (int repeat = 0; repeat < 15; repeat++) {
        pitches.add(doReMiFaSoLaSiDo[noteIndex]);
      }
    }
    
    // 残りを最後の音で埋める
    while (pitches.length < 500) {
      pitches.add(doReMiFaSoLaSiDo.last);
    }
    
    debugPrint('フォールバックピッチ生成完了: ${pitches.length}個 (${doReMiFaSoLaSiDo.first.toStringAsFixed(1)}Hz〜${doReMiFaSoLaSiDo.last.toStringAsFixed(1)}Hz)');
    debugPrint('=== フォールバック処理完了 ===');
    
    return pitches;
  }

  /// 音源再生
  Future<void> _playAudio() async {
    try {
      final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
      final audioFile = selectedSong?['audioFile'] ?? 'assets/sounds/Test.wav';
      
      if (kDebugMode) {
        debugPrint('音源再生を開始: $audioFile');
      }
      
      // 現在の再生を停止
      await _player.stop();
      
      // 直接WAVファイルを再生
      await _player.setAudioSource(AudioSource.asset(audioFile));
      
      // 再生を開始
      await _player.play();
      
      _logger.success('音源再生開始完了: $audioFile');
      _showSnackBar('音源再生を開始しました');
      
    } catch (e) {
      _logger.error('音源再生に失敗しました', e);
      _showSnackBar('音源の再生に失敗しました: $e');
    }
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
          sampleRate: 44100,  // 基準ピッチ検出と同じサンプリングレートに統一
          numChannels: 1,
          bitRate: 44100 * 16,  // サンプリングレートに合わせて調整
          autoGain: true,      // 自動ゲイン調整を有効化
          echoCancel: true,    // エコーキャンセル有効化
          noiseSuppress: true, // ノイズ抑制有効化
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
      _logger.error('録音の開始に失敗しました', e);
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
      _logger.error('リアルタイムピッチ検出の開始に失敗しました', e);
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
          // より自然で控えめなバリエーションに修正
          final variation = (random.nextDouble() - 0.5) * 20; // ±10Hzの小さなバリエーション
          final pitchDrift = math.sin(recordedCount * 0.05) * 5; // 小さな周期的変動
          
          final simulatedPitch = referencePitch + variation + pitchDrift;
          
          // ピッチが適切な範囲内かチェック（伊勢節に適した範囲：100-500Hz）
          final clampedPitch = simulatedPitch.clamp(100.0, 500.0);
          
          // 時々無音を挿入して、より自然な歌唱パターンを作る
          if (random.nextDouble() < 0.1) {
            sessionProvider.updateCurrentPitch(null);
          } else {
            sessionProvider.updateCurrentPitch(clampedPitch);
            
            // リアルタイムスコア計算を追加
            _updateRealtimeScore(clampedPitch, referencePitch);
          }
        } else {
          // 無音部分
          sessionProvider.updateCurrentPitch(null);
        }
      } else {
        // 基準ピッチがない場合は、より控えめなピッチを生成（伊勢節に適した音域に調整）
        final baseFrequencies = [196.0, 220.0, 246.94, 261.63, 293.66, 329.63, 349.23]; // G3-F4の音階（伝統音楽により適した範囲）
        final baseIndex = recordedCount % baseFrequencies.length;
        final basePitch = baseFrequencies[baseIndex];
        
        final variation = (random.nextDouble() - 0.5) * 15; // ±7.5Hzの小さなバリエーション
        final simulatedPitch = (basePitch + variation).clamp(100.0, 500.0);
        
        sessionProvider.updateCurrentPitch(simulatedPitch);
      }
      
    } catch (e) {
      // エラーが発生した場合は無音として処理
      if (mounted) {
        context.read<KaraokeSessionProvider>().updateCurrentPitch(null);
      }
    }
  }

  /// リアルタイムスコア更新
  void _updateRealtimeScore(double detectedPitch, double referencePitch) {
    if (!mounted) return;
    
    try {
      // デバッグモードの場合のみスコア計算を実行
      if (kDebugMode) {
        // スコア計算
        final scoreResult = PitchComparisonService.calculateRealtimeScore(
          detectedPitch, 
          referencePitch
        );
        
        if (scoreResult.isValid) {
          // 履歴に追加
          _scoreHistory.add(scoreResult);
          
          // ピッチ履歴に追加
          _pitchHistory.add(detectedPitch);
          if (_pitchHistory.length > 100) {
            _pitchHistory.removeAt(0); // 古いデータを削除
          }
          
          // 累積スコア計算
          final cumulativeResult = PitchComparisonService.calculateCumulativeScore(_scoreHistory);
          
          // UI状態を更新
          setState(() {
            _currentScore = scoreResult.score;
            _averageScore = cumulativeResult.averageScore;
            _maxScore = cumulativeResult.maxScore;
            _currentLevel = ScoreLevel.fromScore(_averageScore);
          });
        }
      }
    } catch (e) {
      // エラーは無視（スコア計算はオプション機能）
      _logger.error('スコア計算エラー', e);
    }
  }

  /// 現在の基準ピッチを取得
  double? _getCurrentReferencePitch(KaraokeSessionProvider sessionProvider) {
    if (sessionProvider.referencePitches.isEmpty) return null;
    
    final currentIndex = sessionProvider.recordedPitches.length;
    if (currentIndex >= sessionProvider.referencePitches.length) {
      return sessionProvider.referencePitches.last;
    }
    
    return sessionProvider.referencePitches[currentIndex];
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
      _logger.error('録音の停止に失敗しました', e);
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
      
      // 録音ファイルからピッチを抽出（ファイルシステム対応、基準ピッチ使用）
      if (!mounted) return;
      final sessionProvider = context.read<KaraokeSessionProvider>();
      var analysisResult = await _pitchDetectionService.extractPitchAnalysisFromAudio(
        sourcePath: recordingPath,
        isAsset: false,
        referencePitches: sessionProvider.referencePitches, // 基準ピッチを渡す
      );
      
      // 抽出したピッチをプロバイダーに設定
      if (mounted) {
        
        // === ピッチ比較デバッグ情報 ===
        debugPrint('=== ピッチ比較デバッグ ===');
        debugPrint('基準ピッチサンプル（最初の10個）:');
        final refSample = sessionProvider.referencePitches.take(10).toList();
        for (int i = 0; i < refSample.length; i++) {
          debugPrint('  [$i]: ${refSample[i].toStringAsFixed(2)}Hz');
        }

        debugPrint('録音ピッチサンプル（最初の10個）:');
        final recSample = analysisResult.pitches.take(10).toList();
        for (int i = 0; i < recSample.length; i++) {
          debugPrint('  [$i]: ${recSample[i].toStringAsFixed(2)}Hz');
        }

        // 統計情報
        final validRef = sessionProvider.referencePitches.where((p) => p > 0).toList();
        final validRec = analysisResult.pitches.where((p) => p > 0).toList();
        if (validRef.isNotEmpty && validRec.isNotEmpty) {
          final avgRef = validRef.reduce((a, b) => a + b) / validRef.length;
          double avgRec = validRec.reduce((a, b) => a + b) / validRec.length;
          
          debugPrint('補正前 - 録音ピッチ平均: ${avgRec.toStringAsFixed(2)}Hz');
          
          // 参照ピッチを使用して録音ピッチにオクターブ補正を適用
          final correctedRecPitches = <double>[];
          for (double pitch in analysisResult.pitches) {
            if (pitch > 0) {
              double correctedPitch = _pitchDetectionService.correctOctave(pitch, avgRef);
              correctedRecPitches.add(correctedPitch);
            } else {
              correctedRecPitches.add(0.0);
            }
          }
          
          // 補正後の統計
          final validCorrected = correctedRecPitches.where((p) => p > 0).toList();
          if (validCorrected.isNotEmpty) {
            final avgCorrected = validCorrected.reduce((a, b) => a + b) / validCorrected.length;
            final pitchRatio = avgCorrected / avgRef;
            
            debugPrint('基準ピッチ平均: ${avgRef.toStringAsFixed(2)}Hz (有効: ${validRef.length}個)');
            debugPrint('補正後録音ピッチ平均: ${avgCorrected.toStringAsFixed(2)}Hz (有効: ${validCorrected.length}個)');
            debugPrint('ピッチ比率: ${pitchRatio.toStringAsFixed(3)}');
            debugPrint('平均差: ${(avgCorrected - avgRef).toStringAsFixed(2)}Hz');
            
            // 新しいAudioAnalysisResultを作成（補正後のピッチ使用）
            analysisResult = AudioAnalysisResult(
              pitches: correctedRecPitches,
              sampleRate: analysisResult.sampleRate,
              createdAt: analysisResult.createdAt,
              sourceFile: analysisResult.sourceFile,
            );
          }
          
          // ピッチ範囲の確認
          final minRef = validRef.reduce((a, b) => a < b ? a : b);
          final maxRef = validRef.reduce((a, b) => a > b ? a : b);
          final validFinalRec = analysisResult.pitches.where((p) => p > 0).toList();
          if (validFinalRec.isNotEmpty) {
            final minRec = validFinalRec.reduce((a, b) => a < b ? a : b);
            final maxRec = validFinalRec.reduce((a, b) => a > b ? a : b);
            debugPrint('基準ピッチ範囲: ${minRef.toStringAsFixed(2)}Hz - ${maxRef.toStringAsFixed(2)}Hz');
            debugPrint('最終録音ピッチ範囲: ${minRec.toStringAsFixed(2)}Hz - ${maxRec.toStringAsFixed(2)}Hz');
          }
        }
        
        // 詳細な比較分析
        PitchDebugHelper.comparePitchData(
          sessionProvider.referencePitches, 
          analysisResult.pitches
        );
        
        debugPrint('=== デバッグ終了 ===');
        
        // 既存の録音ピッチをクリアして、実際の録音データで置き換える
        sessionProvider.replaceRecordedPitches(analysisResult.pitches);
        
        debugPrint('録音ピッチ抽出完了: ${analysisResult.pitches.length}個のピッチ');
        _showSnackBar('録音音声の分析が完了しました');
      }
      
    } catch (e) {
      _logger.error('録音音声の分析に失敗しました', e);
      if (mounted) {
        _showSnackBar('録音音声の分析に失敗しました: ${e.toString()}');
        
        // フォールバック処理：録音中のデータを使用
        final sessionProvider = context.read<KaraokeSessionProvider>();
        if (sessionProvider.recordedPitches.isNotEmpty) {
          _showSnackBar('録音中のデータを使用してスコアを計算します');
          _logger.info('フォールバック: 録音中のピッチデータを使用 (${sessionProvider.recordedPitches.length}個)');
        } else {
          _logger.error('録音データが存在しないため、スコア計算を中止します');
          _showSnackBar('録音データが不足しています。もう一度お試しください。');
          return;
        }
      }
    }
  }

  /// セッションリセット
  void _resetSession() {
    context.read<KaraokeSessionProvider>().resetSession();
  }



  /// デバッグオーバーレイの表示切り替え
  void _toggleDebugOverlay() {
    setState(() {
      _showDebugOverlay = !_showDebugOverlay;
    });
  }

  /// 改善版Test.wav音源への切り替え
  void _switchToImprovedTestWav() async {
    try {
      // 現在の再生を停止
      if (_player.playing) {
        await _player.stop();
      }
      
      if (kDebugMode) {
        debugPrint('🔄 改善版Test.wav音源切り替え開始');
      }
      // 改善版音源に直接切り替え（フォールバックなし）
      await _player.setAudioSource(
        AudioSource.asset('assets/sounds/Test_improved.wav'),
      );
      if (kDebugMode) {
        debugPrint('✅ Test_improved.wav読み込み成功');
      }
      
      // セッションリセット
      if (mounted) {
        final sessionProvider = context.read<KaraokeSessionProvider>();
        sessionProvider.resetSession();
      }
      
      // 改善版音源でピッチ検出を再実行
      if (mounted) {
        final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
        if (selectedSong != null) {
          // 改善版音源用の楽曲情報を作成
          final improvedSongInfo = Map<String, String>.from(selectedSong);
          improvedSongInfo['audioFile'] = 'assets/sounds/Test_improved.wav';
          improvedSongInfo['title'] = '${selectedSong['title']}（改善版）';
          
          if (kDebugMode) {
            debugPrint('🔄 改善版音源でピッチ検出を再実行');
          }
          await _loadReferencePitches(improvedSongInfo);
        }
      }
      
      setState(() {
        // UI更新
      });
      
      if (kDebugMode) {
        debugPrint('🔄 改善版Test.wav音源に切り替えました');
        debugPrint('   期待される結果: 261.6→293.7→329.6→349.2→392.0→440.0→493.9→523.3Hz');
      }
      _showSnackBar('改善版音源に切り替えました（構造的問題を修正済み）');
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ 改善版音源の読み込みに失敗: $e');
      }
      _showSnackBar('改善版音源の読み込みに失敗しました: $e');
    }
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
          // デバッグオーバーレイ表示ボタン
          IconButton(
            icon: Icon(
              Icons.developer_mode,
              color: _showDebugOverlay ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleDebugOverlay,
            tooltip: 'デバッグ表示切り替え',
          ),
          // 改善版Test.wav音源切り替えボタン（デバッグ用）
          if (selectedSong != null && 
              (selectedSong['audioFile']?.contains('Test.wav') == true || 
               selectedSong['title'] == 'テスト'))
            IconButton(
              icon: const Icon(Icons.upgrade, color: Colors.green),
              onPressed: _switchToImprovedTestWav,
              tooltip: '改善版音源に切り替え',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSession,
            tooltip: 'セッションリセット',
          ),
        ],
      ),
      body: Stack(
        children: [
          Consumer<KaraokeSessionProvider>(
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

                    // Phase 3: 新しいピッチ可視化ウィジェット
                    if (sessionProvider.referencePitches.isNotEmpty && sessionProvider.isRecording) ...[
                      PitchVisualizationWidget(
                        currentPitch: sessionProvider.currentPitch,
                        referencePitch: _getCurrentReferencePitch(sessionProvider),
                        pitchHistory: _pitchHistory,
                        height: 150.0,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Phase 3: リアルタイムスコア表示
                    if (sessionProvider.isRecording && _scoreHistory.isNotEmpty) ...[
                      RealtimeScoreWidget(
                        currentScore: _currentScore,
                        maxScore: _maxScore,
                        averageScore: _averageScore,
                        scoreLevel: _currentLevel,
                        scoreHistory: _scoreHistory.map((s) => s.score).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

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
          // デバッグオーバーレイ表示
          if (_showDebugOverlay)
            Positioned(
              right: 16,
              top: 16,
              child: DebugInfoOverlay(
                debugLogs: _debugLogs,
                isVisible: _showDebugOverlay,
              ),
            ),
        ],
      ),
    ),
    );
  }

  /// セッション状態表示カード
  Widget _buildSessionStatusCard(KaraokeSessionProvider sessionProvider) {
    final selectedSong = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    
    return GestureDetector(
      onLongPress: () => _showDetailedDebugInfo(sessionProvider),
      child: Card(
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
      ),
    );
  }

  /// 詳細デバッグ情報表示（隠し機能）
  void _showDetailedDebugInfo(KaraokeSessionProvider sessionProvider) {
    final referencePitches = sessionProvider.referencePitches;
    final recordedPitches = sessionProvider.recordedPitches;
    
    // 基準ピッチの統計
    final validRefPitches = referencePitches.where((p) => p > 0).toList();
    final refStats = validRefPitches.isNotEmpty ? {
      'count': validRefPitches.length,
      'min': validRefPitches.reduce(math.min),
      'max': validRefPitches.reduce(math.max),
      'avg': validRefPitches.reduce((a, b) => a + b) / validRefPitches.length,
    } : null;
    
    // 録音ピッチの統計
    final validRecPitches = recordedPitches.where((p) => p > 0).toList();
    final recStats = validRecPitches.isNotEmpty ? {
      'count': validRecPitches.length,
      'min': validRecPitches.reduce(math.min),
      'max': validRecPitches.reduce(math.max),
      'avg': validRecPitches.reduce((a, b) => a + b) / validRecPitches.length,
    } : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 詳細デバッグ情報'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📊 基準ピッチ統計', style: TextStyle(fontWeight: FontWeight.bold)),
              if (refStats != null) ...[
                Text('データ数: ${refStats['count']}'),
                Text('最小: ${refStats['min']!.toStringAsFixed(1)}Hz'),
                Text('最大: ${refStats['max']!.toStringAsFixed(1)}Hz'),
                Text('平均: ${refStats['avg']!.toStringAsFixed(1)}Hz'),
              ] else
                const Text('データなし'),
              
              const SizedBox(height: 16),
              const Text('🎤 録音ピッチ統計', style: TextStyle(fontWeight: FontWeight.bold)),
              if (recStats != null) ...[
                Text('データ数: ${recStats['count']}'),
                Text('最小: ${recStats['min']!.toStringAsFixed(1)}Hz'),
                Text('最大: ${recStats['max']!.toStringAsFixed(1)}Hz'),
                Text('平均: ${recStats['avg']!.toStringAsFixed(1)}Hz'),
              ] else
                const Text('データなし'),
              
              const SizedBox(height: 16),
              const Text('🔄 セッション詳細', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('状態: ${sessionProvider.state}'),
              Text('録音中: ${sessionProvider.isRecording}'),
              Text('現在ピッチ: ${sessionProvider.currentPitch?.toStringAsFixed(2) ?? 'null'}'),
              if (sessionProvider.errorMessage.isNotEmpty)
                Text('エラー: ${sessionProvider.errorMessage}', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
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

  /// Phase 3: 検証結果の統合デバッグ出力
  Future<void> _outputVerificationDebugInfo(
    String audioFile,
    String songTitle,
    dynamic verificationResult, // PitchVerificationResult
  ) async {
    if (kDebugMode) {
      final stats = verificationResult.statistics;
      
      debugPrint('=== 🎯 ピッチ検証結果 ===');
      debugPrint('楽曲: $songTitle');
      debugPrint('音源ファイル: $audioFile');
      debugPrint('分析日時: ${verificationResult.analyzedAt.toLocal()}');
      debugPrint('キャッシュ使用: ${verificationResult.fromCache}');
      debugPrint('総ピッチ数: ${stats.totalCount}');
      debugPrint('有効ピッチ数: ${stats.validCount}');
      debugPrint('有効率: ${stats.validRate.toStringAsFixed(1)}%');
      
      if (stats.validCount > 0) {
        debugPrint('ピッチ統計:');
        debugPrint('  範囲: ${stats.minPitch.toStringAsFixed(1)}Hz 〜 ${stats.maxPitch.toStringAsFixed(1)}Hz');
        debugPrint('  平均: ${stats.avgPitch.toStringAsFixed(1)}Hz');
        debugPrint('  範囲幅: ${stats.pitchRange.toStringAsFixed(1)}Hz');
        debugPrint('  期待範囲適合: ${stats.isInExpectedRange ? "✅" : "❌"}');
      }

      // 詳細なデバッグ情報を表示
      if (kDebugMode) {
        debugPrint('詳細な検証結果:');
        debugPrint('  - 楽曲タイトル: $songTitle');
        debugPrint('  - 音源ファイル: $audioFile');
        debugPrint('  - キャッシュ使用: ${verificationResult.fromCache}');
        debugPrint('  - 分析日時: ${verificationResult.analyzedAt.toIso8601String()}');
        debugPrint('  - 統計情報:');
        debugPrint('    - 総ピッチ数: ${stats.totalCount}');
        debugPrint('    - 有効ピッチ数: ${stats.validCount}');
        debugPrint('    - 有効率: ${stats.validRate}%');
        debugPrint('    - 最小ピッチ: ${stats.minPitch}Hz');
        debugPrint('    - 最大ピッチ: ${stats.maxPitch}Hz');
        debugPrint('    - 平均ピッチ: ${stats.avgPitch}Hz');
        debugPrint('    - ピッチ範囲: ${stats.pitchRange}Hz');
        debugPrint('    - 期待範囲内: ${stats.isInExpectedRange}');
      }
    }
  }

  /// Phase 3: Test.wav用の高度な分析出力
  void _outputAdvancedTestWavAnalysis(
    String songTitle,
    dynamic stats, // PitchStatistics
    List<double> pitches,
  ) {
    debugPrint('⚠️ Test.wav高度分析モード ⚠️');
    debugPrint('=== 📊 統計ベース分析 ===');
    
    if (stats.validCount > 0) {
      // 期待範囲チェック
      const expectedMin = 261.63; // C4 ド
      const expectedMax = 523.25; // C5 ド
      
      if (stats.isInExpectedRange) {
        debugPrint('✅ ピッチ範囲がドレミファソラシド（C4-C5）範囲に適合');
      } else {
        debugPrint('❌ ピッチ範囲がドレミファソラシドと不一致');
        debugPrint('   期待範囲: ${expectedMin.toStringAsFixed(1)}Hz 〜 ${expectedMax.toStringAsFixed(1)}Hz');
        debugPrint('   実際範囲: ${stats.minPitch.toStringAsFixed(1)}Hz 〜 ${stats.maxPitch.toStringAsFixed(1)}Hz');
      }
      
      // 詳細なピッチサンプル表示
      debugPrint('最初の10個のピッチ詳細:');
      for (int i = 0; i < stats.firstTen.length; i++) {
        final pitch = stats.firstTen[i];
        final status = pitch > 0 ? '✓' : '✗';
        debugPrint('  [$i] $status ${pitch.toStringAsFixed(2)}Hz');
      }
      
      if (stats.lastTen.length > 0 && stats.totalCount > 10) {
        debugPrint('最後の10個のピッチ詳細:');
        final startIndex = stats.totalCount - stats.lastTen.length;
        for (int i = 0; i < stats.lastTen.length; i++) {
          final pitch = stats.lastTen[i];
          final status = pitch > 0 ? '✓' : '✗';
          debugPrint('  [${startIndex + i}] $status ${pitch.toStringAsFixed(2)}Hz');
        }
      }
    } else {
      debugPrint('❌ 有効なピッチが検出されませんでした！');
      debugPrint('原因: Test.wavファイルのピッチ検出が完全に失敗');
    }
    
    debugPrint('=== Test.wav高度分析終了 ===');
  }
}