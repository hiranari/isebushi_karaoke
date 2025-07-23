import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/infrastructure/services/improvement_suggestion_service.dart';
import 'package:isebushi_karaoke/domain/models/comprehensive_score.dart';

void main() {
  group('ImprovementSuggestionService Tests', () {
    group('Suggestion Generation', () {
      test('should generate pitch suggestions for low pitch score', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 50.0, // 低いスコア
          stability: 80.0,
          timing: 70.0,
          overall: 60.0,
          grade: 'D',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'meanAbsoluteError': 60.0}, // 大きな誤差
        );
        
        final pitchSuggestions = suggestions.where((s) => s.category == 'pitch').toList();
        expect(pitchSuggestions, isNotEmpty);
        expect(pitchSuggestions.first.priority, equals(1)); // 重要度高
      });

      test('should generate stability suggestions for unstable performance', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 80.0,
          stability: 45.0, // 低い安定性
          timing: 75.0,
          overall: 70.0,
          grade: 'C',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'standardDeviation': 25.0}, // 高い標準偏差
        );
        
        final stabilitySuggestions = suggestions.where((s) => s.category == 'stability').toList();
        expect(stabilitySuggestions, isNotEmpty);
        expect(stabilitySuggestions.first.priority, equals(1)); // 重要度高
      });

      test('should generate timing suggestions for poor timing', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 75.0,
          stability: 80.0,
          timing: 40.0, // 低いタイミング
          overall: 65.0,
          grade: 'D',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'averageLatency': 0.15}, // 高い遅延
        );
        
        final timingSuggestions = suggestions.where((s) => s.category == 'timing').toList();
        expect(timingSuggestions, isNotEmpty);
        expect(timingSuggestions.first.priority, equals(1)); // 重要度高
      });

      test('should generate general improvement suggestions for overall poor performance', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 40.0,
          stability: 35.0,
          timing: 45.0,
          overall: 40.0,
          grade: 'F',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        expect(suggestions.length, greaterThan(1)); // 複数の改善提案
        expect(suggestions.any((s) => s.category == 'pitch'), isTrue);
        expect(suggestions.any((s) => s.category == 'stability'), isTrue);
        expect(suggestions.any((s) => s.category == 'timing'), isTrue);
      });
    });

    group('Suggestion Prioritization', () {
      test('should prioritize most critical areas first', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 30.0, // 最も低い
          stability: 60.0,
          timing: 55.0,
          overall: 45.0,
          grade: 'F',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        final sortedSuggestions = suggestions..sort((a, b) => a.priority.compareTo(b.priority));
        expect(sortedSuggestions.first.category, equals('pitch')); // 最も低いスコアの分野が最優先
      });

      test('should handle balanced performance correctly', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 85.0,
          stability: 83.0,
          timing: 87.0,
          overall: 85.0,
          grade: 'A',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        // 良いパフォーマンスには少ない提案、または高レベルの改善提案
        expect(suggestions.length, lessThanOrEqualTo(3));
        if (suggestions.isNotEmpty) {
          expect(suggestions.first.priority, greaterThanOrEqualTo(1)); // 優先度は1以上
        }
      });

      test('should provide specific feedback based on statistics', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 60.0,
          stability: 70.0,
          timing: 65.0,
          overall: 63.0,
          grade: 'D',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {
            'meanAbsoluteError': 45.0,
            'standardDeviation': 20.0,
            'averageLatency': 0.08,
          },
        );
        
        expect(suggestions.isNotEmpty, isTrue);
        expect(suggestions.any((s) => s.description.contains('音程') || s.description.contains('発声')), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle perfect scores', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 100.0,
          stability: 100.0,
          timing: 100.0,
          overall: 100.0,
          grade: 'S',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        // 完璧なスコアには改善提案がないか、非常に高レベルな提案のみ
        expect(suggestions.length, lessThanOrEqualTo(2));
      });

      test('should handle missing statistics gracefully', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 70.0,
          stability: 65.0,
          timing: 75.0,
          overall: 70.0,
          grade: 'C',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {}, // 空の統計
        );
        
        expect(suggestions, isNotEmpty);
        // 統計がなくてもスコアベースの基本的な提案は生成される
      });

      test('should handle invalid statistics gracefully', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 70.0,
          stability: 65.0,
          timing: 75.0,
          overall: 70.0,
          grade: 'C',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {
            'meanAbsoluteError': -10.0, // 無効な値
            'standardDeviation': 999.0, // 異常な値
            'averageVariation': 0.0, // 正常値に修正
          },
        );
        
        expect(suggestions, isNotEmpty);
        // 無効な統計値でもエラーにならず、基本的な提案は生成される
      });
    });

    group('Suggestion Content Quality', () {
      test('should provide actionable suggestions', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 55.0,
          stability: 60.0,
          timing: 50.0,
          overall: 55.0,
          grade: 'D',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        for (final suggestion in suggestions) {
          expect(suggestion.description, isNotEmpty);
          expect(suggestion.category, isNotEmpty);
          expect(suggestion.priority, inInclusiveRange(1, 5));
        }
      });

      test('should provide category-specific suggestions', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 45.0, // 低いピッチ精度
          stability: 85.0,
          timing: 80.0,
          overall: 65.0,
          grade: 'D',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'meanAbsoluteError': 50.0},
        );
        
        final pitchSuggestions = suggestions.where((s) => s.category == 'pitch').toList();
        expect(pitchSuggestions, isNotEmpty);
        expect(pitchSuggestions.first.description, contains('音程'));
      });

      test('should consider statistical context in suggestions', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 60.0,
          stability: 40.0, // 低い安定性
          timing: 70.0,
          overall: 58.0,
          grade: 'D',
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'standardDeviation': 30.0}, // 高い標準偏差
        );
        
        final stabilitySuggestions = suggestions.where((s) => s.category == 'stability').toList();
        expect(stabilitySuggestions, isNotEmpty);
        // 統計情報に基づいた具体的な提案内容をチェック
        expect(stabilitySuggestions.first.description, contains('安定'));
      });
    });
  });
}
