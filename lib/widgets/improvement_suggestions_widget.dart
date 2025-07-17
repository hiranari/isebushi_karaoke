import 'package:flutter/material.dart';
import '../models/song_result.dart';
import '../services/improvement_suggestion_service.dart';

/// 改善提案表示ウィジェット
/// Phase 3: プログレッシブディスクロージャーの第3段階 - 具体的改善提案
class ImprovementSuggestionsWidget extends StatelessWidget {
  final SongResult result;
  final VoidCallback? onBackToAnalysis;
  final VoidCallback? onRestartSession;

  const ImprovementSuggestionsWidget({
    super.key,
    required this.result,
    this.onBackToAnalysis,
    this.onRestartSession,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = result.improvementSuggestions;
    final encouragementMessage = ImprovementSuggestionService
        .generateEncouragementMessage(result.comprehensiveScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          _buildHeader(context),
          const SizedBox(height: 24),

          // 励ましメッセージ
          _buildEncouragementMessage(context, encouragementMessage),
          const SizedBox(height: 24),

          // カテゴリ別改善提案
          _buildCategorizedSuggestions(context, suggestions),
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
              '改善提案',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              result.songTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'あなたの歌唱をより良くするための具体的なアドバイスです',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncouragementMessage(BuildContext context, String message) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.blue[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorizedSuggestions(
    BuildContext context,
    List<ImprovementSuggestion> suggestions,
  ) {
    // カテゴリ別にグループ化
    final Map<String, List<ImprovementSuggestion>> categorizedSuggestions = {};
    for (final suggestion in suggestions) {
      categorizedSuggestions
          .putIfAbsent(suggestion.category, () => [])
          .add(suggestion);
    }

    return Column(
      children: [
        // 音程精度
        if (categorizedSuggestions.containsKey('pitch'))
          _buildCategorySection(
            context,
            '音程精度の改善',
            Icons.music_note,
            Colors.blue,
            categorizedSuggestions['pitch']!,
          ),

        // 安定性
        if (categorizedSuggestions.containsKey('stability'))
          _buildCategorySection(
            context,
            '安定性の改善',
            Icons.timeline,
            Colors.green,
            categorizedSuggestions['stability']!,
          ),

        // タイミング
        if (categorizedSuggestions.containsKey('timing'))
          _buildCategorySection(
            context,
            'タイミングの改善',
            Icons.schedule,
            Colors.orange,
            categorizedSuggestions['timing']!,
          ),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String categoryTitle,
    IconData icon,
    Color color,
    List<ImprovementSuggestion> suggestions,
  ) {
    // 優先度順にソート
    final sortedSuggestions = List<ImprovementSuggestion>.from(suggestions)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // カテゴリヘッダー
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    categoryTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 提案リスト
              ...sortedSuggestions.map((suggestion) => 
                _buildSuggestionItem(context, suggestion)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    ImprovementSuggestion suggestion,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getPriorityColor(suggestion.priority),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提案タイトルと優先度
          Row(
            children: [
              Expanded(
                child: Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPriorityBadge(context, suggestion.priority),
            ],
          ),
          const SizedBox(height: 8),

          // 提案内容
          Text(
            suggestion.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, int priority) {
    String label;
    Color color;

    switch (priority) {
      case 1:
        label = '重要';
        color = Colors.red;
        break;
      case 2:
        label = '推奨';
        color = Colors.orange;
        break;
      case 3:
        label = '参考';
        color = Colors.blue;
        break;
      default:
        label = '参考';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red[200]!;
      case 2:
        return Colors.orange[200]!;
      case 3:
        return Colors.blue[200]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // もう一度歌うボタン
        if (onRestartSession != null)
          ElevatedButton.icon(
            onPressed: onRestartSession,
            icon: const Icon(Icons.mic),
            label: const Text('もう一度歌ってみる'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),

        const SizedBox(height: 12),

        // 詳細分析に戻るボタン
        if (onBackToAnalysis != null)
          OutlinedButton.icon(
            onPressed: onBackToAnalysis,
            icon: const Icon(Icons.arrow_back),
            label: const Text('詳細分析に戻る'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

        const SizedBox(height: 24),

        // 注意書き
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '※ 提案された練習方法は一般的なアドバイスです。'
            '個人差がありますので、無理をせず自分のペースで練習してください。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}