import 'package:flutter/material.dart';
import '../models/song_result.dart';

/// 詳細分析表示ウィジェット
/// Phase 3: プログレッシブディスクロージャーの第2段階 - 各スコア詳細と音程グラフ
class DetailedAnalysisWidget extends StatelessWidget {
  final SongResult result;
  final VoidCallback? onShowSuggestions;
  final VoidCallback? onBackToScore;

  const DetailedAnalysisWidget({
    super.key,
    required this.result,
    this.onShowSuggestions,
    this.onBackToScore,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          _buildHeader(context),
          const SizedBox(height: 24),

          // 詳細スコア
          _buildDetailedScores(context),
          const SizedBox(height: 24),

          // 音程グラフ
          _buildPitchGraph(context),
          const SizedBox(height: 24),

          // 統計情報
          _buildStatistics(context),
          const SizedBox(height: 24),

          // 強み・弱み
          _buildStrengthsAndWeaknesses(context),
          const SizedBox(height: 32),

          // アクションボタン
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '詳細分析',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              result.songTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedScores(BuildContext context) {
    final score = result.comprehensiveScore;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '詳細スコア',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildDetailedScoreItem(
              context,
              '音程精度',
              score.pitchAccuracy,
              '70%の重み',
              Colors.blue,
              Icons.music_note,
            ),
            const SizedBox(height: 12),
            
            _buildDetailedScoreItem(
              context,
              '安定性',
              score.stability,
              '20%の重み',
              Colors.green,
              Icons.timeline,
            ),
            const SizedBox(height: 12),
            
            _buildDetailedScoreItem(
              context,
              'タイミング',
              score.timing,
              '10%の重み',
              Colors.orange,
              Icons.schedule,
            ),
            
            const Divider(height: 32),
            
            // 総合スコア
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '総合スコア',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${score.overall.toStringAsFixed(1)}点',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedScoreItem(
    BuildContext context,
    String label,
    double score,
    String description,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '${score.toStringAsFixed(1)}点',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildPitchGraph(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '音程グラフ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 簡易的なグラフ表示（実際のグラフライブラリを使用する場合は置き換え）
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '音程の変化グラフ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '（グラフライブラリ実装予定）',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // グラフの説明
            Row(
              children: [
                _buildLegendItem('基準音程', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('録音音程', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final stats = result.detailedAnalysis.statistics;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '統計情報',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '歌唱カバレッジ',
                    '${((stats['songCoverage'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.percent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '音程精度',
                    '${((stats['goodPitchRatio'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.precision_manufacturing,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '平均誤差',
                    '${(stats['meanAbsoluteError'] ?? 0.0).toStringAsFixed(1)}Hz',
                    Icons.trending_down,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '音程変動',
                    '${(stats['averageVariation'] ?? 0.0).toStringAsFixed(1)}Hz',
                    Icons.waves,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStrengthsAndWeaknesses(BuildContext context) {
    final analysis = result.detailedAnalysis;
    
    return Column(
      children: [
        // 強み
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '良かった点',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...analysis.strengths.map((strength) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.green)),
                      Expanded(child: Text(strength)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 弱み
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '改善できる点',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...analysis.weaknesses.map((weakness) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.orange)),
                      Expanded(child: Text(weakness)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (onShowSuggestions != null)
          ElevatedButton.icon(
            onPressed: onShowSuggestions,
            icon: const Icon(Icons.tips_and_updates),
            label: const Text('具体的な改善提案を見る'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        
        const SizedBox(height: 12),
        
        if (onBackToScore != null)
          OutlinedButton.icon(
            onPressed: onBackToScore,
            icon: const Icon(Icons.arrow_back),
            label: const Text('総合スコアに戻る'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
      ],
    );
  }
}