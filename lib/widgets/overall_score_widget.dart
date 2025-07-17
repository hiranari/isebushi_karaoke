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
    final score = result.totalScore;
    final rank = ScoringService.getScoreRank(score);
    final comment = ScoringService.getScoreComment(score);

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
                        // メインスコア表示
            _buildScoreDisplay(context, score, rank),
            
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

            // 基本情報表示
            _buildBasicInfo(context),

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

  /// 基本情報表示
  Widget _buildBasicInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '楽曲',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                result.songTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'スコア',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${result.totalScore.toStringAsFixed(1)}点',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
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