import 'package:flutter/foundation.dart';
import '../../domain/models/song_result.dart';
import '../../domain/interfaces/i_logger.dart';
import '../../infrastructure/services/scoring_service.dart';
import '../../infrastructure/services/feedback_service.dart';
import '../../infrastructure/factories/service_locator.dart';

/// 歌唱セッション状態管理プロバイダー
/// 
/// カラオケセッション全体のライフサイクル管理と状態制御を担当します。
/// Providerパターンを使用し、UI層とビジネスロジック層を繋ぐ重要な役割を果たします。
/// 
/// 責任:
/// - セッション状態の管理（準備中→録音中→分析中→完了）
/// - 録音データの収集と管理（基準ピッチ、録音ピッチ）
/// - リアルタイムピッチ更新の通知
/// - スコア計算の制御と結果管理
/// - UI表示状態の制御（スコア表示モード等）
/// - エラー状態の管理と通知
/// 
/// アーキテクチャパターン:
/// - Provider Pattern: ChangeNotifierによる状態変更通知
/// - Observer Pattern: UI層への状態変更の自動通知
/// - State Pattern: セッション状態の遷移管理
/// - Command Pattern: 操作の実行と状態更新の分離
/// 
/// 状態遷移:
/// ```
/// ready → recording → analyzing → completed
///   ↑                              ↓
///   ←――――――――― reset ←――――――――――――――
/// ```
/// 
/// データフロー:
/// 1. UI操作（録音開始/停止）
/// 2. 状態変更とビジネスロジック実行
/// 3. 結果データの更新
/// 4. UI通知（notifyListeners）
/// 
/// 依存サービス:
/// - ScoringService: スコア計算処理
/// - FeedbackService: フィードバック生成
/// - DebugLogger: デバッグログ出力
/// 
/// 使用例:
/// ```dart
/// // Provider経由でのアクセス
/// final provider = Provider.of<KaraokeSessionProvider>(context);
/// 
/// // セッション開始
/// await provider.startSession('楽曲名', referencePitches);
/// 
/// // 録音制御
/// provider.startRecording();
/// provider.updateCurrentPitch(440.0);
/// await provider.stopRecording();
/// ```
/// 
/// 設計原則:
/// - Single Responsibility: セッション状態管理のみに特化
/// - Open/Closed: 新しい状態や操作の追加が容易
/// - Liskov Substitution: ChangeNotifierの契約を遵守
/// - Interface Segregation: 必要な機能のみをpublicに公開
/// - Dependency Inversion: 具象サービスではなく抽象に依存
/// 
/// パフォーマンス考慮:
/// - リアルタイムピッチ更新の効率化
/// - 大容量録音データの軽量な管理
/// - UI更新頻度の最適化
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#karaoke-session-provider)
class KaraokeSessionProvider extends ChangeNotifier {
  // Logger
  late final ILogger _logger;

  // セッション状態
  KaraokeSessionState _state = KaraokeSessionState.ready;
  String? _selectedSongTitle;
  final List<double> _referencePitches = [];
  final List<double> _recordedPitches = [];
  SongResult? _songResult;
  String _errorMessage = '';

  // UI表示状態
  ScoreDisplayMode _scoreDisplayMode = ScoreDisplayMode.hidden;
  bool _isRecording = false;
  double? _currentPitch;

  // コンストラクタ
  KaraokeSessionProvider() {
    _logger = ServiceLocator().getService<ILogger>();
  }

  // Getters
  KaraokeSessionState get state => _state;
  String? get selectedSongTitle => _selectedSongTitle;
  List<double> get referencePitches => List.unmodifiable(_referencePitches);
  List<double> get recordedPitches => List.unmodifiable(_recordedPitches);
  SongResult? get songResult => _songResult;
  String get errorMessage => _errorMessage;
  ScoreDisplayMode get scoreDisplayMode => _scoreDisplayMode;
  bool get isRecording => _isRecording;
  double? get currentPitch => _currentPitch;

  /// セッションの初期化
  /// 
  /// [songTitle] 選択された楽曲のタイトル
  /// [referencePitches] 基準ピッチデータ
  void initializeSession(String songTitle, List<double> referencePitches) {
    _selectedSongTitle = songTitle;
    _referencePitches.clear();
    _referencePitches.addAll(referencePitches);
    _recordedPitches.clear();
    _songResult = null;
    _errorMessage = '';
    _scoreDisplayMode = ScoreDisplayMode.hidden;
    _state = KaraokeSessionState.ready;
    notifyListeners();
  }

  /// 録音開始
  /// 
  /// 歌唱セッションの録音を開始します。
  /// 状態をrecordingに変更し、録音済みピッチをクリアします。
  /// 
  /// @precondition 状態がreadyである必要があります
  /// @postcondition 状態がrecordingになり、isRecordingがtrueになります
  /// @postcondition recordedPitchesがクリアされます
  /// @ensures notifyListeners() が呼び出され、UI に変更が反映される
  void startRecording() {
    if (_state != KaraokeSessionState.ready) return;
    
    _isRecording = true;
    _recordedPitches.clear();
    _state = KaraokeSessionState.recording;
    notifyListeners();
  }

  /// 録音停止と分析実行
  /// 
  /// 録音を停止し、収集したピッチデータの分析を開始します。
  /// 状態をanalyzingに変更し、非同期で分析を実行します。
  /// 
  /// @precondition 状態がrecordingである必要があります
  /// @postcondition 状態がanalyzingになり、isRecordingがfalseになります
  /// @postcondition 分析完了後、状態がcompletedまたはerrorになります
  /// @ensures notifyListeners() が呼び出され、UI に変更が反映される
  void stopRecording() {
    if (_state != KaraokeSessionState.recording) return;
    
    _isRecording = false;
    _state = KaraokeSessionState.analyzing;
    notifyListeners();
    
    // 非同期で分析を実行
    _performAnalysis();
  }

  /// リアルタイムピッチ更新
  /// 
  /// 録音中にリアルタイムで検出されたピッチ値を更新します。
  /// この方法により、UIのピッチビジュアライザーがリアルタイムで反映されます。
  /// 
  /// @param pitch 検出されたピッチ値(Hz)。null の場合は無音を表す
  /// @ensures notifyListeners() が呼び出され、UI に変更が反映される
  /// @ensures 録音中の場合はピッチがrecordedPitchesに記録される
  void updateCurrentPitch(double? pitch) {
    _currentPitch = pitch;
    
    // 録音中の場合はピッチを記録
    if (_isRecording && pitch != null && pitch > 0) {
      _recordedPitches.add(pitch);
    }
    
    notifyListeners();
  }

  /// 録音ピッチデータの置換
  /// 
  /// 実際の録音ファイルから抽出したピッチデータで、リアルタイムで生成された
  /// 一時的なピッチデータを置き換えます。
  /// 
  /// @param pitches 実際の録音から抽出されたピッチデータ
  void replaceRecordedPitches(List<double> pitches) {
    _recordedPitches.clear();
    _recordedPitches.addAll(pitches);
    _logger.info('録音ピッチデータを置換: ${pitches.length}個のピッチ');
    notifyListeners();
  }

  /// エラー状態の設定
  void setError(String message) {
    _errorMessage = message;
    _state = KaraokeSessionState.error;
    notifyListeners();
  }

  /// スコア表示モードの切り替え
  void toggleScoreDisplay() {
    if (_songResult == null) return;
    
    switch (_scoreDisplayMode) {
      case ScoreDisplayMode.hidden:
        _scoreDisplayMode = ScoreDisplayMode.totalScore;
        break;
      case ScoreDisplayMode.totalScore:
        _scoreDisplayMode = ScoreDisplayMode.detailedAnalysis;
        break;
      case ScoreDisplayMode.detailedAnalysis:
        _scoreDisplayMode = ScoreDisplayMode.feedback;
        break;
      case ScoreDisplayMode.feedback:
        _scoreDisplayMode = ScoreDisplayMode.totalScore;
        break;
    }
    
    notifyListeners();
  }

  /// セッションのリセット
  void resetSession() {
    _state = KaraokeSessionState.ready;
    _recordedPitches.clear();
    _songResult = null;
    _errorMessage = '';
    _scoreDisplayMode = ScoreDisplayMode.hidden;
    _isRecording = false;
    _currentPitch = null;
    notifyListeners();
  }

  /// 歌唱分析の実行
  Future<void> _performAnalysis() async {
    try {
      if (_selectedSongTitle == null) {
        throw Exception('楽曲が選択されていません');
      }

      debugPrint('=== 歌唱分析開始 ===');
      debugPrint('楽曲: $_selectedSongTitle');
      debugPrint('基準ピッチ数: ${_referencePitches.length}');
      debugPrint('録音ピッチ数: ${_recordedPitches.length}');
      
      // 基準ピッチと録音ピッチの統計情報をログ出力
      if (_referencePitches.isNotEmpty) {
        final refAvg = _referencePitches.reduce((a, b) => a + b) / _referencePitches.length;
        debugPrint('基準ピッチ平均: ${refAvg.toStringAsFixed(2)}Hz');
      }
      
      if (_recordedPitches.isNotEmpty) {
        final recAvg = _recordedPitches.reduce((a, b) => a + b) / _recordedPitches.length;
        debugPrint('録音ピッチ平均: ${recAvg.toStringAsFixed(2)}Hz');
      }

      // スコアリングサービスで分析実行
      final result = ScoringService.calculateComprehensiveScore(
        referencePitches: _referencePitches,
        recordedPitches: _recordedPitches,
        songTitle: _selectedSongTitle!,
      );

      debugPrint('総合スコア: ${result.totalScore.toStringAsFixed(1)}');
      debugPrint('ピッチ精度: ${result.scoreBreakdown.pitchAccuracyScore.toStringAsFixed(1)}');
      debugPrint('安定性: ${result.scoreBreakdown.stabilityScore.toStringAsFixed(1)}');
      debugPrint('タイミング: ${result.scoreBreakdown.timingScore.toStringAsFixed(1)}');
      debugPrint('=== 歌唱分析完了 ===');

      // フィードバック生成
      final feedback = FeedbackService.generateFeedback(result);
      _songResult = SongResult(
        songTitle: result.songTitle,
        timestamp: result.timestamp,
        totalScore: result.totalScore,
        scoreBreakdown: result.scoreBreakdown,
        pitchAnalysis: result.pitchAnalysis,
        timingAnalysis: result.timingAnalysis,
        stabilityAnalysis: result.stabilityAnalysis,
        feedback: feedback,
      );

      _state = KaraokeSessionState.completed;
      _scoreDisplayMode = ScoreDisplayMode.totalScore;
      
    } catch (e) {
      _logger.error('歌唱分析中にエラーが発生しました', e);
      setError('分析中にエラーが発生しました: $e');
    }
    
    notifyListeners();
  }

  /// デバッグ用: セッション状態の詳細情報
  Map<String, dynamic> getSessionInfo() {
    return {
      'state': _state.toString(),
      'songTitle': _selectedSongTitle,
      'referencePitchCount': _referencePitches.length,
      'recordedPitchCount': _recordedPitches.length,
      'hasResult': _songResult != null,
      'scoreDisplayMode': _scoreDisplayMode.toString(),
      'isRecording': _isRecording,
      'currentPitch': _currentPitch,
      'errorMessage': _errorMessage,
    };
  }
}

/// 歌唱セッションの状態
enum KaraokeSessionState {
  ready,      // 準備完了
  recording,  // 録音中
  analyzing,  // 分析中
  completed,  // 完了
  error,      // エラー
}

/// スコア表示モード
enum ScoreDisplayMode {
  hidden,            // 非表示
  totalScore,        // 総合スコアのみ
  detailedAnalysis,  // 詳細分析
  feedback,          // フィードバック
}