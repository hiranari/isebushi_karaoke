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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 楽曲タイトル
              Text(
                result.songTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // メインスコア表示
              _buildScoreDisplay(context, score, rank),
              const SizedBox(height: 16),

              // コメント
              Text(
                comment,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // スコア内訳
              _buildScoreBreakdown(context),
              const SizedBox(height: 24),

              // 詳細ボタン（コールバックが提供されている場合のみ）
              if (onShowDetails != null)
                ElevatedButton(
                  onPressed: onShowDetails,
                  child: const Text('詳細を見る'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// メインスコア表示ウィジェット
  Widget _buildScoreDisplay(BuildContext context, double score, String rank) {
    final color = _getScoreColor(score);
    
    return Column(
      children: [
        // スコア数値
        Text(
          score.toInt().toString(),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // ランク
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            rank,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// スコア内訳表示ウィジェット
  Widget _buildScoreBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'スコア内訳',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildScoreItem(
          context,
          '音程精度',
          result.scoreBreakdown.pitchAccuracyScore,
          Icons.music_note,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        
        _buildScoreItem(
          context,
          '安定性',
          result.scoreBreakdown.stabilityScore,
          Icons.graphic_eq,
          Colors.green,
        ),
        const SizedBox(height: 12),
        
        _buildScoreItem(
          context,
          'タイミング',
          result.scoreBreakdown.timingScore,
          Icons.access_time,
          Colors.orange,
        ),
      ],
    );
  }

  /// 個別スコア項目ウィジェット
  Widget _buildScoreItem(
    BuildContext context,
    String label,
    double score,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${score.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: score / 100,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// スコアに応じた色を取得
  Color _getScoreColor(double score) {
    if (score >= 90) return const Color(0xFFFFD700); // Gold color
    if (score >= 80) return Colors.green;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.amber;
    return Colors.red;
  }
}
