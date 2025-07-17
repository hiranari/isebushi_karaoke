import 'package:flutter/material.dart';
import '../models/song_result.dart';
import '../providers/karaoke_session_provider.dart';

/// Phase 3: プログレッシブスコア表示ウィジェット
/// 
/// タップに応じて段階的にスコア情報を開示します:
/// 1. 総合スコアのみ
/// 2. 詳細分析（スコア内訳、グラフ）
/// 3. 実行可能なアドバイス
/// 
/// 単一責任の原則に従い、スコア表示のUIロジックのみを担当します。
class ProgressiveScoreDisplay extends StatelessWidget {
  final SongResult songResult;
  final ScoreDisplayMode displayMode;
  final VoidCallback onTap;

  const ProgressiveScoreDisplay({
    super.key,
    required this.songResult,
    required this.displayMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _getGradientForScore(songResult.totalScore),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildContent(context),
      ),
    );
  }

  /// 表示モードに応じたコンテンツを構築
  Widget _buildContent(BuildContext context) {
    switch (displayMode) {
      case ScoreDisplayMode.hidden:
        return const SizedBox.shrink();
      case ScoreDisplayMode.totalScore:
        return _buildTotalScoreView(context);
      case ScoreDisplayMode.detailedAnalysis:
        return _buildDetailedAnalysisView(context);
      case ScoreDisplayMode.feedback:
        return _buildFeedbackView(context);
    }
  }

  /// 総合スコア表示
  Widget _buildTotalScoreView(BuildContext context) {
    final score = songResult.totalScore;
    final grade = _getScoreGrade(score);
    
    return Column(
      children: [
        const Icon(
          Icons.star,
          size: 40,
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          '${score.toStringAsFixed(1)}点',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'グレード: $grade',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'タップして詳細を表示',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 詳細分析表示
  Widget _buildDetailedAnalysisView(BuildContext context) {
    final breakdown = songResult.scoreBreakdown;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 総合スコア
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              '総合スコア: ${songResult.totalScore.toStringAsFixed(1)}点',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // スコア内訳
        _buildScoreBreakdownItem(
          '音程精度',
          breakdown.pitchAccuracyScore,
          breakdown.pitchAccuracyWeight,
          Icons.music_note,
        ),
        const SizedBox(height: 12),
        _buildScoreBreakdownItem(
          '安定性',
          breakdown.stabilityScore,
          breakdown.stabilityWeight,
          Icons.waves,
        ),
        const SizedBox(height: 12),
        _buildScoreBreakdownItem(
          'タイミング',
          breakdown.timingScore,
          breakdown.timingWeight,
          Icons.timer,
        ),
        
        const SizedBox(height: 24),
        
        // 詳細統計
        _buildDetailedStats(),
        
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'タップしてアドバイスを表示',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  /// スコア内訳項目
  Widget _buildScoreBreakdownItem(String label, double score, double weight, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$label (${(weight * 100).toInt()}%)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${score.toStringAsFixed(1)}点',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: score / 100,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForScore(score),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 詳細統計表示
  Widget _buildDetailedStats() {
    final pitchAnalysis = songResult.pitchAnalysis;
    final stabilityAnalysis = songResult.stabilityAnalysis;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '詳細統計',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('正確な音程', '${pitchAnalysis.correctNotes}/${pitchAnalysis.totalNotes}'),
          _buildStatRow('平均音程ずれ', '${pitchAnalysis.averageDeviation.toStringAsFixed(1)}セント'),
          _buildStatRow('安定性', '${(stabilityAnalysis.stabilityRatio * 100).toStringAsFixed(1)}%'),
          _buildStatRow('平均変動', '${stabilityAnalysis.averageVariation.toStringAsFixed(1)}セント'),
        ],
      ),
    );
  }

  /// 統計行
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// フィードバック表示
  Widget _buildFeedbackView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              '改善アドバイス',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // フィードバックリスト
        ...songResult.feedback.map((feedback) => _buildFeedbackItem(feedback)),
        
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'タップして戻る',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  /// フィードバック項目
  Widget _buildFeedbackItem(String feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        feedback,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.white,
          height: 1.4,
        ),
      ),
    );
  }

  /// スコアに応じたグラデーション
  LinearGradient _getGradientForScore(double score) {
    if (score >= 90) {
      return const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (score >= 80) {
      return const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (score >= 70) {
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFFFF5722), Color(0xFFD84315)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// スコアに応じた色
  Color _getColorForScore(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return Colors.red;
  }

  /// スコアのグレード判定
  String _getScoreGrade(double score) {
    if (score >= 95) return 'S';
    if (score >= 90) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'D+';
    if (score >= 55) return 'D';
    return 'F';
  }
}