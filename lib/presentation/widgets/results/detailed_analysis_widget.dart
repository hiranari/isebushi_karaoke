import 'package:flutter/material.dart';
import '../../../domain/models/song_result.dart';

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

          // 基本情報
          _buildBasicInfo(context),
          const SizedBox(height: 24),

          // 音程グラフ
          _buildPitchGraph(context),
          const SizedBox(height: 24),

          // 統計情報（分析データから）
          _buildStatistics(context),
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

  Widget _buildBasicInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '分析結果',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '総合スコア',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${result.totalScore.toStringAsFixed(1)}点',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 音程分析
            _buildAnalysisItem(
              context, 
              '音程分析', 
              result.pitchAnalysis.accuracyRatio * 100,
              '正確率: ${(result.pitchAnalysis.accuracyRatio * 100).toStringAsFixed(1)}%',
              Icons.music_note,
              Colors.blue
            ),
            
            const SizedBox(height: 12),
            
            // タイミング分析  
            _buildAnalysisItem(
              context,
              'タイミング分析',
              result.scoreBreakdown.timingScore,
              'スコア: ${result.scoreBreakdown.timingScore.toStringAsFixed(1)}点',
              Icons.schedule,
              Colors.orange
            ),
            
            const SizedBox(height: 12),
            
            // 安定性分析
            _buildAnalysisItem(
              context,
              '安定性分析', 
              result.stabilityAnalysis.stabilityRatio * 100,
              '変動: ${result.stabilityAnalysis.averageVariation.toStringAsFixed(1)}セント',
              Icons.timeline,
              Colors.green
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(
    BuildContext context,
    String label,
    double score,
    String description,
    IconData icon,
    Color color,
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
            
            // スコア内訳の統計
            _buildScoreBreakdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context) {
    return Column(
      children: [
        _buildStatItem(
          context,
          '音程精度',
          '${result.scoreBreakdown.pitchAccuracyScore.toStringAsFixed(1)}点',
          Icons.music_note,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildStatItem(
          context,
          'タイミング',
          '${result.scoreBreakdown.timingScore.toStringAsFixed(1)}点',
          Icons.schedule,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildStatItem(
          context,
          '安定性',
          '${result.scoreBreakdown.stabilityScore.toStringAsFixed(1)}点',
          Icons.timeline,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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