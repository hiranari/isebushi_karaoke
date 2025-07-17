import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/services/improvement_suggestion_service.dart';
import 'package:isebushi_karaoke/models/song_result.dart';

void main() {
  group('ImprovementSuggestionService Tests', () {
    group('Suggestion Generation', () {
      test('should generate pitch suggestions for low pitch score', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 50.0, // 低いスコア
          stability: 80.0,
          timing: 70.0,
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
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 80.0,
          stability: 45.0, // 低い安定性
          timing: 70.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'averageVariation': 60.0}, // 大きな変動
        );
        
        final stabilitySuggestions = suggestions.where((s) => s.category == 'stability').toList();
        expect(stabilitySuggestions, isNotEmpty);
        
        final breathingSuggestion = stabilitySuggestions.firstWhere(
          (s) => s.title.contains('呼吸'),
          orElse: () => stabilitySuggestions.first,
        );
        expect(breathingSuggestion.priority, equals(1));
      });

      test('should generate timing suggestions for timing issues', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 80.0,
          stability: 75.0,
          timing: 40.0, // 低いタイミング
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'songCoverage': 0.5}, // 短い歌唱
        );
        
        final timingSuggestions = suggestions.where((s) => s.category == 'timing').toList();
        expect(timingSuggestions, isNotEmpty);
        
        final rhythmSuggestion = timingSuggestions.firstWhere(
          (s) => s.title.contains('リズム'),
          orElse: () => timingSuggestions.first,
        );
        expect(rhythmSuggestion.category, equals('timing'));
      });

      test('should limit suggestions per category', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 30.0, // 非常に低い
          stability: 30.0,     // 非常に低い
          timing: 30.0,        // 非常に低い
        );
        
        final allSuggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {
            'meanAbsoluteError': 80.0,
            'averageVariation': 80.0,
            'songCoverage': 0.3,
          },
        );
        
        final limitedSuggestions = ImprovementSuggestionService
            .limitSuggestionsByCategory(allSuggestions, maxPerCategory: 2);
        
        // 各カテゴリ最大2個まで
        final pitchCount = limitedSuggestions.where((s) => s.category == 'pitch').length;
        final stabilityCount = limitedSuggestions.where((s) => s.category == 'stability').length;
        final timingCount = limitedSuggestions.where((s) => s.category == 'timing').length;
        
        expect(pitchCount, lessThanOrEqualTo(2));
        expect(stabilityCount, lessThanOrEqualTo(2));
        expect(timingCount, lessThanOrEqualTo(2));
      });

      test('should prioritize suggestions correctly', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 30.0,
          stability: 80.0,
          timing: 70.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {'meanAbsoluteError': 80.0},
        );
        
        // 優先度順にソートされている
        for (int i = 1; i < suggestions.length; i++) {
          expect(suggestions[i].priority, greaterThanOrEqualTo(suggestions[i-1].priority));
        }
      });
    });

    group('Encouragement Messages', () {
      test('should return appropriate message for excellent score', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 95.0,
          stability: 90.0,
          timing: 85.0,
        );
        
        final message = ImprovementSuggestionService.generateEncouragementMessage(score);
        expect(message, contains('素晴らしい'));
      });

      test('should return appropriate message for poor score', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 40.0,
          stability: 35.0,
          timing: 30.0,
        );
        
        final message = ImprovementSuggestionService.generateEncouragementMessage(score);
        expect(message, contains('挑戦'));
      });

      test('should return appropriate message for mid-range score', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 75.0,
          stability: 70.0,
          timing: 65.0,
        );
        
        final message = ImprovementSuggestionService.generateEncouragementMessage(score);
        expect(message, contains('良い調子'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty statistics gracefully', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 60.0,
          stability: 60.0,
          timing: 60.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {}, // 空の統計
        );
        
        expect(suggestions, isNotEmpty); // 基本的な提案は生成される
      });

      test('should handle null statistics values', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 50.0,
          stability: 50.0,
          timing: 50.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {
            'meanAbsoluteError': 50.0,
            'averageVariation': null, // null値
            'songCoverage': 0.8,
          },
        );
        
        expect(suggestions, isNotEmpty);
      });

      test('should handle perfect scores', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 100.0,
          stability: 100.0,
          timing: 100.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {
            'meanAbsoluteError': 5.0,
            'averageVariation': 10.0,
            'songCoverage': 1.0,
          },
        );
        
        // 完璧なスコアでも細かい改善提案が生成される可能性
        expect(suggestions, isA<List<ImprovementSuggestion>>());
      });
    });

    group('Suggestion Content Quality', () {
      test('should generate meaningful suggestion titles', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 50.0,
          stability: 50.0,
          timing: 50.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        for (final suggestion in suggestions) {
          expect(suggestion.title, isNotEmpty);
          expect(suggestion.description, isNotEmpty);
          expect(suggestion.category, isIn(['pitch', 'stability', 'timing']));
          expect(suggestion.priority, isIn([1, 2, 3]));
        }
      });

      test('should generate different suggestions for different categories', () {
        final score = ComprehensiveScore.calculate(
          pitchAccuracy: 40.0,
          stability: 40.0,
          timing: 40.0,
        );
        
        final suggestions = ImprovementSuggestionService.generateSuggestions(
          score: score,
          statistics: {},
        );
        
        final categories = suggestions.map((s) => s.category).toSet();
        expect(categories.length, greaterThan(1)); // 複数カテゴリの提案が生成される
      });
    });
  });
}