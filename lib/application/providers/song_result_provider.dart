import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/song_result.dart';
import '../../core/utils/debug_logger.dart';
import '../../infrastructure/services/scoring_service.dart';
import '../../infrastructure/services/feedback_service.dart';

/// 歌唱結果の状態管理とUIレンダリング制御プロバイダー
/// 
/// ChangeNotifierを継承し、歌唱結果データの状態変更と
/// UI層への通知機能を提供するアプリケーション層のプロバイダーです。
/// Providerパターンによる宣言的状態管理を実現します。
/// 
/// アーキテクチャ位置:
/// ```
/// Presentation層
///     ↓ (Widget → Provider監視)
/// Application層 ← SongResultProvider
///     ↓ (Domain Model管理)
/// Domain層 (SongResult, ScoreBreakdown等)
/// ```
/// 
/// 責任範囲:
/// - 歌唱結果データの中央集権的状態管理
/// - UI層への変更通知とリアクティブ更新
/// - ドメインモデル（SongResult）のライフサイクル管理
/// - 結果表示・非表示の制御状態
/// - 複数ウィジェット間のデータ共有
/// 
/// 状態フロー:
/// ```
/// 初期状態 → 結果計算中 → 結果表示 → 結果非表示 → 次回準備
///    ↓          ↓         ↓        ↓         ↓
/// null     loading    result   hidden    cleared
/// ```
/// 
/// 主要機能:
/// 1. **結果設定**: setResult(SongResult) - 新しい歌唱結果の保存
/// 2. **表示制御**: showResult()/hideResult() - UI表示状態の管理  
/// 3. **状態クリア**: clearResult() - 次回セッション準備
/// 4. **リアクティブ通知**: notifyListeners() - UI自動更新
/// 
/// 使用例:
/// ```dart
/// // Widget内での使用
/// class ResultDisplayWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Consumer<SongResultProvider>(
///       builder: (context, provider, child) {
///         if (provider.currentResult == null) {
///           return Text('結果がありません');
///         }
///         return ResultCard(result: provider.currentResult!);
///       },
///     );
///   }
/// }
/// 
/// // 結果の設定
/// final provider = Provider.of<SongResultProvider>(context, listen: false);
/// provider.setResult(calculatedResult);
/// provider.showResult();
/// ```
/// 
/// 状態管理パターン:
/// - **Observer Pattern**: ChangeNotifier実装による監視機能
/// - **Singleton Pattern**: 単一インスタンスでのグローバル状態
/// - **Command Pattern**: 状態変更メソッドの統一インターフェース
/// 
/// Thread Safety:
/// - Flutterのシングルスレッドモデルに準拠
/// - UIスレッドでの同期実行保証
/// - ChangeNotifierの内部同期機能活用
/// 
/// メモリ管理:
/// - 適切なdispose()実装
/// - 循環参照の防止
/// - WeakReference使用検討
/// 
/// デバッグ支援:
/// - 状態変更ログ出力
/// - デバッグ用状態ダンプ機能
/// - 開発者向け状態監視
/// 
/// 将来拡張:
/// - 結果履歴管理（複数結果保持）
/// - 統計データ集計
/// - 結果比較機能
/// - エクスポート/インポート機能
/// 
/// 設計原則:
/// - Single Responsibility: 歌唱結果状態管理のみ
/// - Open/Closed: 新機能追加が容易
/// - Liskov Substitution: ChangeNotifier互換性
/// - Interface Segregation: 用途別メソッド分離
/// - Dependency Inversion: 抽象化への依存
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#song-result-provider)
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