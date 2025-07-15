import 'package:flutter/material.dart';
import '../models/song_result.dart';
import '../services/scoring_service.dart';

/// 総合スコア表示ウィジェット
/// Phase 3: 歌唱直後の総合スコア表示（プログレッシブディスクロージャーの第1段階）
class OverallScoreWidget extends StatelessWidget {
  final SongResult result;
  final VoidCallback? onShowDetails;

  const OverallScoreWidget({
    super.key,
    required this.result,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final score = result.comprehensiveScore;
    final rank = ScoringService.getScoreRank(score.overall);
    final comment = ScoringService.getScoreComment(score.overall);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            Text(
              '歌唱結果',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              result.songTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // 総合スコア
            _buildScoreDisplay(context, score.overall, rank),
            
            const SizedBox(height: 16),

            // コメント
            Text(
              comment,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // スコア内訳（簡易版）
            _buildScoreBreakdown(context, score),

            const SizedBox(height: 24),

            // 詳細ボタン
            if (onShowDetails != null)
              ElevatedButton.icon(
                onPressed: onShowDetails,
                icon: const Icon(Icons.analytics),
                label: const Text('詳細分析を見る'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context, double score, String rank) {
    return Column(
      children: [
        // ランク表示
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRankColor(rank),
          ),
          child: Center(
            child: Text(
              rank,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // スコア数値
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              score.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getRankColor(rank),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '点',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown(BuildContext context, ComprehensiveScore score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'スコア内訳',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _buildScoreItem(
          context,
          '音程精度',
          score.pitchAccuracy,
          '70%',
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildScoreItem(
          context,
          '安定性',
          score.stability,
          '20%',
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildScoreItem(
          context,
          'タイミング',
          score.timing,
          '10%',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildScoreItem(
    BuildContext context,
    String label,
    double score,
    String weight,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$label ($weight)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 45,
          child: Text(
            '${score.toStringAsFixed(1)}点',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S':
        return Colors.purple;
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.orange;
      case 'C':
        return Colors.yellow[700]!;
      case 'D':
        return Colors.blue;
      case 'E':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}