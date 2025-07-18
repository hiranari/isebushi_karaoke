import 'package:flutter/foundation.dart';
import '../models/song_result.dart';
import '../services/scoring_service.dart';
import '../services/feedback_service.dart';

/// Phase 3: 歌唱セッション状態管理
/// 
/// Providerパターンを使用し、歌唱セッションのライフサイクルと
/// 状態管理を担当します。単一責任の原則に従い、状態の更新と
/// 通知のみに責任を持ちます。
class KaraokeSessionProvider extends ChangeNotifier {
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

      // スコアリングサービスで分析実行
      final result = ScoringService.calculateComprehensiveScore(
        referencePitches: _referencePitches,
        recordedPitches: _recordedPitches,
        songTitle: _selectedSongTitle!,
      );

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