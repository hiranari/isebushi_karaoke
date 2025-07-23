import 'package:flutter/foundation.dart';
import '../../domain/models/song_result.dart';
import '../services/scoring_service.dart';
import '../services/feedback_service.dart';

/// カラオケセッションの状態管理
/// Phase 3: プログレッシブ UI ディスクロージャーのための状態管理
class KaraokeSessionNotifier extends ChangeNotifier {
  // 基本データ
  String? _songTitle;
  List<double> _recordedPitches = [];
  List<double> _referencePitches = [];
  
  // スコアリング結果
  SongResult? _currentResult;
  
  // UI状態管理
  KaraokeDisplayState _displayState = KaraokeDisplayState.recording;
  bool _isLoading = false;
  String? _errorMessage;

  // ゲッター
  String? get songTitle => _songTitle;
  List<double> get recordedPitches => List.unmodifiable(_recordedPitches);
  List<double> get referencePitches => List.unmodifiable(_referencePitches);
  SongResult? get currentResult => _currentResult;
  KaraokeDisplayState get displayState => _displayState;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 計算プロパティ
  bool get hasResults => _currentResult != null;
  bool get canShowDetailedAnalysis => hasResults && _displayState == KaraokeDisplayState.overallScore;
  bool get canShowImprovementSuggestions => hasResults && _displayState == KaraokeDisplayState.detailedAnalysis;

  /// セッションを初期化
  void initializeSession({
    required String songTitle,
    required List<double> referencePitches,
  }) {
    _songTitle = songTitle;
    _referencePitches = referencePitches;
    _recordedPitches.clear();
    _currentResult = null;
    _displayState = KaraokeDisplayState.recording;
    _errorMessage = null;
    notifyListeners();
  }

  /// 録音されたピッチを追加
  void addRecordedPitch(double pitch) {
    _recordedPitches.add(pitch);
    // リアルタイムでの状態更新は最小限に抑制
    // notifyListeners(); // パフォーマンスのため呼び出さない
  }

  /// 録音データをバッチで更新
  void updateRecordedPitches(List<double> pitches) {
    _recordedPitches = pitches;
    notifyListeners();
  }

  /// 録音終了と結果計算
  Future<void> finishRecordingAndCalculateResults() async {
    if (_recordedPitches.isEmpty || _referencePitches.isEmpty) {
      _setError('録音データまたは基準データが不足しています');
      return;
    }

    _setLoading(true);

    try {
      // スコア計算
      final songResult = ScoringService.calculateComprehensiveScore(
        recordedPitches: _recordedPitches,
        referencePitches: _referencePitches,
        songTitle: _songTitle!,
      );

      // フィードバック生成
      final feedback = FeedbackService.generateFeedback(songResult);

      // 結果を統合 - 新しいSongResultを作成してフィードバックを追加
      _currentResult = SongResult(
        songTitle: songResult.songTitle,
        timestamp: songResult.timestamp,
        totalScore: songResult.totalScore,
        scoreBreakdown: songResult.scoreBreakdown,
        pitchAnalysis: songResult.pitchAnalysis,
        timingAnalysis: songResult.timingAnalysis,
        stabilityAnalysis: songResult.stabilityAnalysis,
        feedback: feedback,
      );

      _displayState = KaraokeDisplayState.overallScore;
      _clearError();
    } catch (e) {
      _setError('結果の計算中にエラーが発生しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 詳細分析画面に遷移
  void showDetailedAnalysis() {
    if (!canShowDetailedAnalysis) return;
    _displayState = KaraokeDisplayState.detailedAnalysis;
    notifyListeners();
  }

  /// 改善提案画面に遷移
  void showImprovementSuggestions() {
    if (!canShowImprovementSuggestions) return;
    _displayState = KaraokeDisplayState.improvementSuggestions;
    notifyListeners();
  }

  /// 総合スコア画面に戻る
  void backToOverallScore() {
    if (!hasResults) return;
    _displayState = KaraokeDisplayState.overallScore;
    notifyListeners();
  }

  /// 詳細分析画面に戻る
  void backToDetailedAnalysis() {
    if (!hasResults) return;
    _displayState = KaraokeDisplayState.detailedAnalysis;
    notifyListeners();
  }

  /// 録音画面に戻る（新しいセッション開始）
  void restartSession() {
    _recordedPitches.clear();
    _currentResult = null;
    _displayState = KaraokeDisplayState.recording;
    _clearError();
    notifyListeners();
  }

  /// セッションリセット
  void resetSession() {
    _songTitle = null;
    _recordedPitches.clear();
    _referencePitches.clear();
    _currentResult = null;
    _displayState = KaraokeDisplayState.recording;
    _clearError();
    notifyListeners();
  }

  // プライベートメソッド
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// カラオケ画面の表示状態
enum KaraokeDisplayState {
  recording,               // 録音中
  overallScore,           // 総合スコア表示
  detailedAnalysis,       // 詳細分析表示
  improvementSuggestions, // 改善提案表示
}

/// 表示状態の拡張メソッド
extension KaraokeDisplayStateExtension on KaraokeDisplayState {
  String get displayName {
    switch (this) {
      case KaraokeDisplayState.recording:
        return '録音中';
      case KaraokeDisplayState.overallScore:
        return '総合スコア';
      case KaraokeDisplayState.detailedAnalysis:
        return '詳細分析';
      case KaraokeDisplayState.improvementSuggestions:
        return '改善提案';
    }
  }

  bool get isResultScreen {
    return this != KaraokeDisplayState.recording;
  }
}