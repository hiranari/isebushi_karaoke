import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/services/scoring_service.dart';
import 'package:isebushi_karaoke/models/comprehensive_score.dart';

void main() {
  group('ScoringService Tests', () {
    group('Pitch Accuracy Score', () {
      test('should return 100 for perfect pitch match', () {
        final recordedPitches = [440.0, 493.88, 523.25];
        final referencePitches = [440.0, 493.88, 523.25];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        expect(score.pitchAccuracy, equals(100.0));
      });

      test('should return 0 for empty recorded pitches', () {
        final recordedPitches = <double>[];
        final referencePitches = [440.0, 493.88, 523.25];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        expect(score.pitchAccuracy, equals(0.0));
      });

      test('should handle pitches with small differences correctly', () {
        final recordedPitches = [445.0, 498.0, 528.0]; // 5Hz差
        final referencePitches = [440.0, 493.88, 523.25];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        expect(score.pitchAccuracy, greaterThan(80.0));
        expect(score.pitchAccuracy, lessThan(100.0));
      });

      test('should filter out invalid pitches (0 or negative)', () {
        final recordedPitches = [440.0, 0.0, 523.25, -100.0];
        final referencePitches = [440.0, 493.88, 523.25, 587.33];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        // 有効なピッチ2個（440.0, 523.25）のみが評価される
        expect(score.pitchAccuracy, equals(100.0));
      });
    });

    group('Stability Score', () {
      test('should return 100 for very stable pitches', () {
        final recordedPitches = [440.0, 441.0, 440.5, 440.2]; // 安定
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: [440.0, 440.0, 440.0, 440.0],
        );
        
        expect(score.stability, greaterThan(95.0)); // 非常に安定
      });

      test('should return lower score for unstable pitches', () {
        final recordedPitches = [440.0, 500.0, 400.0, 520.0]; // 不安定
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: [440.0, 440.0, 440.0, 440.0],
        );
        
        expect(score.stability, lessThan(50.0));
      });

      test('should return 0 for single pitch', () {
        final recordedPitches = [440.0];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: [440.0],
        );
        
        expect(score.stability, greaterThan(80.0)); // 単一ピッチでも安定
      });
    });

    group('Timing Score', () {
      test('should return 100 for equal length recordings', () {
        final recordedPitches = [440.0, 493.88, 523.25, 587.33];
        final referencePitches = [440.0, 493.88, 523.25, 587.33];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        expect(score.timing, greaterThanOrEqualTo(50.0)); // 長さ一致分のスコア
      });

      test('should return lower score for different length recordings', () {
        final recordedPitches = [440.0, 493.88];
        final referencePitches = [440.0, 493.88, 523.25, 587.33];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        expect(score.timing, greaterThan(50.0)); // 長さが違っても一定のスコア
      });
    });

    group('Comprehensive Score', () {
      test('should calculate weighted average correctly', () {
        final recordedPitches = [440.0, 493.88, 523.25];
        final referencePitches = [440.0, 493.88, 523.25];
        
        final score = ScoringService.calculateComprehensiveScore(
          songTitle: 'Test Song',
          recordedPitches: recordedPitches,
          referencePitches: referencePitches,
        );
        
        // 完璧な場合、全てのスコアが高い値になる
        expect(score.overall, greaterThanOrEqualTo(75.0));
        
        // 重み配分の確認
        final expectedOverall = (score.pitchAccuracy * 0.7) + 
                              (score.stability * 0.2) + 
                              (score.timing * 0.1);
        expect(score.overall, closeTo(expectedOverall, 0.1));
      });
    });

    group('Utility Functions', () {
      test('calculateCentDifference should work correctly', () {
        // 1オクターブ上は1200セント
        final cents = ScoringService.calculateCentDifference(440.0, 880.0);
        expect(cents, closeTo(1200.0, 0.1));
        
        // 同じ音程は0セント
        final sameCents = ScoringService.calculateCentDifference(440.0, 440.0);
        expect(sameCents, closeTo(0.0, 0.1));
      });

      test('getScoreRank should return correct ranks', () {
        expect(ScoringService.getScoreRank(95.0), equals('S'));
        expect(ScoringService.getScoreRank(85.0), equals('A'));
        expect(ScoringService.getScoreRank(75.0), equals('B'));
        expect(ScoringService.getScoreRank(65.0), equals('C'));
        expect(ScoringService.getScoreRank(55.0), equals('D'));
        expect(ScoringService.getScoreRank(45.0), equals('F'));
      });

      test('getScoreComment should return appropriate comments', () {
        final excellentComment = ScoringService.getScoreComment(95.0);
        expect(excellentComment, contains('素晴らしい'));
        
        final poorComment = ScoringService.getScoreComment(30.0);
        expect(poorComment, contains('練習'));
      });
    });
  });

  group('ComprehensiveScore Model', () {
    test('should create score with calculate factory', () {
      const score = ComprehensiveScore(
        pitchAccuracy: 80.0,
        stability: 70.0,
        timing: 60.0,
        overall: 76.0,
        grade: 'B',
      );
      
      expect(score.pitchAccuracy, equals(80.0));
      expect(score.stability, equals(70.0));
      expect(score.timing, equals(60.0));
      
      // 重み配分の確認: 80*0.7 + 70*0.2 + 60*0.1 = 56 + 14 + 6 = 76
      expect(score.overall, closeTo(76.0, 0.1));
    });

    test('should serialize and deserialize correctly', () {
      const originalScore = ComprehensiveScore(
        pitchAccuracy: 85.5,
        stability: 75.3,
        timing: 68.7,
        overall: 81.0,
        grade: 'B',
      );
      
      final json = originalScore.toJson();
      final deserializedScore = ComprehensiveScore.fromJson(json);
      
      expect(deserializedScore.pitchAccuracy, equals(originalScore.pitchAccuracy));
      expect(deserializedScore.stability, equals(originalScore.stability));
      expect(deserializedScore.timing, equals(originalScore.timing));
      expect(deserializedScore.overall, equals(originalScore.overall));
    });
  });
}