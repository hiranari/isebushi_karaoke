import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_result.dart';
import '../providers/song_result_provider.dart';

/// Phase 3: 段階的な結果表示を担当するウィジェット
/// 
/// UI分離原則: ロジックはProviderに委任し、UIは表示のみに専念
/// 段階的表示: 総合スコア → 詳細分析 → 改善提案
class SongResultWidget extends StatelessWidget {
  const SongResultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SongResultProvider>(
      builder: (context, provider, child) {
        if (provider.isProcessing) {
          return _buildProcessingWidget(provider.processingStatus);
        }

        if (provider.currentResult == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            if (provider.displayState.hasNext) {
              provider.advanceDisplayState();
            }
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider.currentResult!),
                const SizedBox(height: 16),
                _buildContent(provider),
                if (provider.displayState.hasNext) ...[ 
                  const SizedBox(height: 16),
                  _buildTapHint(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 処理中表示ウィジェット
  Widget _buildProcessingWidget(String status) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            status,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ヘッダー部分（楽曲情報）
  Widget _buildHeader(SongResult result) {
    return Row(
      children: [
        Icon(
          result.isExcellent ? Icons.star : Icons.music_note,
          color: result.isExcellent ? Colors.amber : Colors.blue,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.songTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${result.recordedAt.hour.toString().padLeft(2, '0')}:'
                '${result.recordedAt.minute.toString().padLeft(2, '0')} - '
                '${result.scoreLevel}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// コンテンツ部分（表示状態に応じて切り替え）
  Widget _buildContent(SongResultProvider provider) {
    switch (provider.displayState) {
      case ResultDisplayState.totalScore:
        return _buildTotalScoreView(provider.currentResult!);
      case ResultDisplayState.detailedAnalysis:
        return _buildDetailedAnalysisView(provider.currentResult!);
      case ResultDisplayState.actionableAdvice:
        return _buildActionableAdviceView(provider.currentResult!);
      case ResultDisplayState.none:
        return const SizedBox.shrink();
    }
  }

  /// 総合スコア表示
  Widget _buildTotalScoreView(SongResult result) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _getScoreColors(result.totalScore),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  result.totalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  '点',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          result.scoreLevel,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 詳細分析表示
  Widget _buildDetailedAnalysisView(SongResult result) {
    return Column(
      children: [
        _buildTotalScoreView(result),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          '詳細分析',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildScoreBreakdown(result.scoreBreakdown),
        const SizedBox(height: 16),
        _buildBasicStatistics(result),
      ],
    );
  }

  /// スコア内訳表示
  Widget _buildScoreBreakdown(ScoreBreakdown breakdown) {
    return Column(
      children: [
        _buildScoreBar('音程精度 (70%)', breakdown.pitchAccuracy, Colors.blue),
        const SizedBox(height: 8),
        _buildScoreBar('安定性 (20%)', breakdown.stability, Colors.green),
        const SizedBox(height: 8),
        _buildScoreBar('タイミング (10%)', breakdown.timing, Colors.orange),
      ],
    );
  }

  /// 個別スコアバー
  Widget _buildScoreBar(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('${score.toStringAsFixed(1)}点', 
                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 100.0,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  /// 基本統計情報表示
  Widget _buildBasicStatistics(SongResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分析結果',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('音程正確率: ${(result.pitchAnalysis.accuracyRatio * 100).toStringAsFixed(1)}%'),
        Text('音程変動: ${result.stabilityAnalysis.averageVariation.toStringAsFixed(1)}セント'),
        Text('タイミング正確率: ${((result.timingAnalysis.onTimeNotes / (result.timingAnalysis.onTimeNotes + result.timingAnalysis.earlyNotes + result.timingAnalysis.lateNotes)) * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  /// フィードバックリスト表示
  Widget _buildFeedbackList(List<String> feedback) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'フィードバック',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...feedback.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('• $item'),
        )),
      ],
    );
  }

  /// 改善提案表示
  Widget _buildActionableAdviceView(SongResult result) {
    return Column(
      children: [
        _buildDetailedAnalysisView(result),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          '改善提案',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeedbackList(result.feedback),
      ],
    );
  }

  /// タップヒント表示
  Widget _buildTapHint() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, color: Colors.grey[600], size: 16),
          const SizedBox(width: 8),
          Text(
            'タップして詳細を表示',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// スコアに応じた色の取得
  List<Color> _getScoreColors(double score) {
    if (score >= 90) {
      return [Colors.amber[600]!, Colors.amber[400]!]; // 優秀
    } else if (score >= 75) {
      return [Colors.green[600]!, Colors.green[400]!]; // 良好
    } else if (score >= 60) {
      return [Colors.blue[600]!, Colors.blue[400]!]; // 標準
    } else {
      return [Colors.orange[600]!, Colors.orange[400]!]; // 要練習
    }
  }
}