import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/song_result.dart';
import '../utils/debug_logger.dart';
import '../services/scoring_service.dart';
import '../services/feedback_service.dart';

/// Phase 3: 歌唱結果の状態管理を担当するProvider
/// 
/// 責任: SongResultの生成と状態管理
/// ライフサイクル: 歌唱セッションごとに生成・破棄
/// 分離原則: UI状態とビジネスロジックを分離
class SongResultProvider extends ChangeNotifier {
  SongResult? _currentResult;
  bool _isProcessing = false;
  String _processingStatus = '';

  // Phase 3 要件: 段階的な結果表示の状態管理
  ResultDisplayState _displayState = ResultDisplayState.none;

  /// 現在の歌唱結果
  SongResult? get currentResult => _currentResult;

  /// 処理中フラグ
  bool get isProcessing => _isProcessing;

  /// 処理状況メッセージ
  String get processingStatus => _processingStatus;

  /// 表示状態
  ResultDisplayState get displayState => _displayState;

  /// 歌唱結果の計算と設定
  /// 
  /// [songTitle] 楽曲タイトル
  /// [recordedPitches] 録音されたピッチデータ
  /// [referencePitches] 基準ピッチデータ
  Future<void> calculateSongResult({
    required String songTitle,
    required List<double> recordedPitches,
    required List<double> referencePitches,
  }) async {
    _setProcessing(true, '結果を計算中...');

    try {
      // Phase 3: 段階的な処理
      
      // 1. スコア計算（包括的分析）
      _setProcessing(true, 'スコアを計算中...');
      final songResult = ScoringService.calculateComprehensiveScore(
        recordedPitches: recordedPitches,
        referencePitches: referencePitches,
        songTitle: songTitle,
      );

      // 2. フィードバック生成
      _setProcessing(true, 'フィードバックを生成中...');
      final feedbackList = FeedbackService.generateFeedback(songResult);

      // 3. フィードバックを結果に追加した新しいSongResultを作成
      _currentResult = SongResult(
        songTitle: songResult.songTitle,
        timestamp: songResult.timestamp,
        totalScore: songResult.totalScore,
        scoreBreakdown: songResult.scoreBreakdown,
        pitchAnalysis: songResult.pitchAnalysis,
        timingAnalysis: songResult.timingAnalysis,
        stabilityAnalysis: songResult.stabilityAnalysis,
        feedback: feedbackList,
      );

      // 表示状態をtotalScoreに設定
      _displayState = ResultDisplayState.totalScore;
      
    } catch (e) {
      DebugLogger.error('歌唱結果の計算中にエラーが発生しました', e);
      rethrow;
    } finally {
      _setProcessing(false, '');
    }
  }

  /// 表示状態を次のレベルに進める
  /// Phase 3 要件: タップで段階的に詳細を表示
  void advanceDisplayState() {
    switch (_displayState) {
      case ResultDisplayState.none:
      case ResultDisplayState.totalScore:
        _displayState = ResultDisplayState.detailedAnalysis;
        break;
      case ResultDisplayState.detailedAnalysis:
        _displayState = ResultDisplayState.actionableAdvice;
        break;
      case ResultDisplayState.actionableAdvice:
        // 最後の状態なので変更なし
        break;
    }
    notifyListeners();
  }

  /// 表示状態をリセット
  void resetDisplayState() {
    _displayState = ResultDisplayState.none;
    notifyListeners();
  }

  /// 結果をクリア
  void clearResult() {
    _currentResult = null;
    _displayState = ResultDisplayState.none;
    notifyListeners();
  }

  /// 処理状態の設定（内部メソッド）
  void _setProcessing(bool processing, String status) {
    _isProcessing = processing;
    _processingStatus = status;
    notifyListeners();
  }

  /// スコアレベルの取得（便利メソッド）
  String? get scoreLevel => _currentResult?.scoreLevel;

  /// 優秀な結果かどうかの判定（便利メソッド）
  bool get isExcellentResult => _currentResult?.isExcellent ?? false;

  /// 改善が最も必要な項目の取得（便利メソッド）
  List<String> get recommendedFocus {
    if (_currentResult == null) return [];
    return ScoringService.getRecommendedFocus(_currentResult!.scoreBreakdown);
  }
}

/// Phase 3 要件: 段階的な結果表示の状態
enum ResultDisplayState {
  none,              // 結果なし
  totalScore,        // 総合スコアのみ表示
  detailedAnalysis,  // 詳細分析も表示
  actionableAdvice,  // 改善提案も表示
}

/// 表示状態の拡張メソッド
extension ResultDisplayStateExtension on ResultDisplayState {
  /// 次の状態があるかどうか
  bool get hasNext {
    switch (this) {
      case ResultDisplayState.none:
      case ResultDisplayState.totalScore:
      case ResultDisplayState.detailedAnalysis:
        return true;
      case ResultDisplayState.actionableAdvice:
        return false;
    }
  }

  /// 状態の説明
  String get description {
    switch (this) {
      case ResultDisplayState.none:
        return '結果なし';
      case ResultDisplayState.totalScore:
        return '総合スコア表示中';
      case ResultDisplayState.detailedAnalysis:
        return '詳細分析表示中';
      case ResultDisplayState.actionableAdvice:
        return '改善提案表示中';
    }
  }
}