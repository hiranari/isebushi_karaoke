import 'package:flutter/material.dart';
import '../models/song_result.dart';

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
    // SongResultのfeedbackから改善提案を取得
    final suggestions = result.feedback;
    
    // スコアから励ましメッセージを生成
    final totalScore = result.totalScore;
    final encouragementMessage = _getEncouragementMessage(totalScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          _buildHeader(context),
          const SizedBox(height: 16),

          // 励ましメッセージ
          _buildEncouragementCard(context, encouragementMessage),
          const SizedBox(height: 16),

          // 改善提案セクション
          _buildSuggestionsSection(context, suggestions),
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

  Widget _buildEncouragementCard(BuildContext context, String message) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              color: Colors.green.shade700,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(
    BuildContext context,
    List<String> suggestions,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '改善のポイント',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (suggestions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '素晴らしい歌唱でした！\n現時点で特別な改善提案はありません。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              ...suggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final suggestion = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRestartSession,
            icon: const Icon(Icons.refresh),
            label: const Text('もう一度歌う'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onBackToAnalysis,
            icon: const Icon(Icons.analytics),
            label: const Text('詳細分析に戻る'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _getEncouragementMessage(double totalScore) {
    if (totalScore >= 90) {
      return '素晴らしい歌唱でした！あなたの歌声には人を感動させる力があります。';
    } else if (totalScore >= 80) {
      return 'とても上手に歌えています！細かい部分を調整すれば、さらに素晴らしい歌声になります。';
    } else if (totalScore >= 70) {
      return '良い調子です！基本はしっかりできているので、練習を続ければ確実に上達します。';
    } else if (totalScore >= 60) {
      return '基本的な歌唱力は身についています。提案された練習方法を試してみてください。';
    } else if (totalScore >= 50) {
      return '歌うことの楽しさを大切にしながら、基本から少しずつ上達していきましょう。';
    } else {
      return '歌に挑戦する気持ちが素晴らしいです！基本的な練習から始めて、一歩ずつ上達していきましょう。';
    }
  }
}
