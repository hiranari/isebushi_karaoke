import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/models/comprehensive_score.dart';
import 'package:isebushi_karaoke/models/song_result.dart';
import 'package:isebushi_karaoke/models/improvement_suggestion.dart';
import 'package:isebushi_karaoke/models/audio_analysis_result.dart';

/// Models（データ構造）の単体テスト
/// 
/// Phase 3で追加されたデータモデルの動作をテストします
void main() {
  group('Model Tests', () {
    group('ComprehensiveScore', () {
      test('スコアの基本プロパティ', () {
        const score = ComprehensiveScore(
          pitchAccuracy: 85.0,
          stability: 78.0,
          timing: 92.0,
          overall: 85.0,
          grade: 'A',
        );

        expect(score.pitchAccuracy, equals(85.0));
        expect(score.stability, equals(78.0));
        expect(score.timing, equals(92.0));
        expect(score.overall, equals(85.0));
        expect(score.grade, equals('A'));
      });

      test('スコアの境界値', () {
        const perfectScore = ComprehensiveScore(
          pitchAccuracy: 100.0,
          stability: 100.0,
          timing: 100.0,
          overall: 100.0,
          grade: 'S',
        );

        expect(perfectScore.pitchAccuracy, equals(100.0));
        expect(perfectScore.grade, equals('S'));

        const zeroScore = ComprehensiveScore(
          pitchAccuracy: 0.0,
          stability: 0.0,
          timing: 0.0,
          overall: 0.0,
          grade: 'F',
        );

        expect(zeroScore.overall, equals(0.0));
        expect(zeroScore.grade, equals('F'));
      });

      test('スコアの比較', () {
        const highScore = ComprehensiveScore(
          pitchAccuracy: 90.0,
          stability: 85.0,
          timing: 88.0,
          overall: 88.0,
          grade: 'A',
        );

        const lowScore = ComprehensiveScore(
          pitchAccuracy: 60.0,
          stability: 55.0,
          timing: 58.0,
          overall: 58.0,
          grade: 'D',
        );

        expect(highScore.overall, greaterThan(lowScore.overall));
        expect(highScore.pitchAccuracy, greaterThan(lowScore.pitchAccuracy));
      });
    });

    group('SongResult', () {
      test('SongResultの基本プロパティ', () {
        final timestamp = DateTime.now();
        
        final result = SongResult(
          songTitle: 'テスト楽曲',
          timestamp: timestamp,
          totalScore: 82.5,
          scoreBreakdown: const ScoreBreakdown(
            pitchAccuracyScore: 80.0,
            stabilityScore: 85.0,
            timingScore: 83.0,
          ),
          pitchAnalysis: const PitchAnalysis(
            averageDeviation: 15.2,
            maxDeviation: 45.0,
            correctNotes: 85,
            totalNotes: 100,
            pitchPoints: [],
            deviationHistory: [],
          ),
          timingAnalysis: const TimingAnalysis(
            averageLatency: 0.08,
            maxLatency: 0.25,
            earlyNotes: 5,
            lateNotes: 10,
            onTimeNotes: 85,
            latencyHistory: [],
          ),
          stabilityAnalysis: const StabilityAnalysis(
            averageVariation: 8.5,
            maxVariation: 25.0,
            stableNotes: 90,
            unstableNotes: 10,
            variationHistory: [],
          ),
          feedback: const ['良い調子です！', 'ピッチの安定性を向上させましょう'],
        );

        expect(result.songTitle, equals('テスト楽曲'));
        expect(result.timestamp, equals(timestamp));
        expect(result.totalScore, equals(82.5));
        expect(result.feedback.length, equals(2));
      });

      test('便利メソッドの動作確認', () {
        final excellentResult = SongResult(
          songTitle: '優秀なテスト',
          timestamp: DateTime.now(),
          totalScore: 95.0,
          scoreBreakdown: const ScoreBreakdown(
            pitchAccuracyScore: 95.0,
            stabilityScore: 95.0,
            timingScore: 95.0,
          ),
          pitchAnalysis: const PitchAnalysis(
            averageDeviation: 5.0,
            maxDeviation: 15.0,
            correctNotes: 95,
            totalNotes: 100,
            pitchPoints: [],
            deviationHistory: [],
          ),
          timingAnalysis: const TimingAnalysis(
            averageLatency: 0.02,
            maxLatency: 0.08,
            earlyNotes: 2,
            lateNotes: 3,
            onTimeNotes: 95,
            latencyHistory: [],
          ),
          stabilityAnalysis: const StabilityAnalysis(
            averageVariation: 3.0,
            maxVariation: 10.0,
            stableNotes: 98,
            unstableNotes: 2,
            variationHistory: [],
          ),
          feedback: const ['素晴らしい演奏です！'],
        );

        expect(excellentResult.isExcellent, isTrue);
        expect(excellentResult.scoreLevel, equals('S'));
      });

      test('低スコア結果の便利メソッド', () {
        final poorResult = SongResult(
          songTitle: '練習が必要なテスト',
          timestamp: DateTime.now(),
          totalScore: 45.0,
          scoreBreakdown: const ScoreBreakdown(
            pitchAccuracyScore: 40.0,
            stabilityScore: 45.0,
            timingScore: 50.0,
          ),
          pitchAnalysis: const PitchAnalysis(
            averageDeviation: 35.0,
            maxDeviation: 80.0,
            correctNotes: 40,
            totalNotes: 100,
            pitchPoints: [],
            deviationHistory: [],
          ),
          timingAnalysis: const TimingAnalysis(
            averageLatency: 0.15,
            maxLatency: 0.4,
            earlyNotes: 20,
            lateNotes: 25,
            onTimeNotes: 55,
            latencyHistory: [],
          ),
          stabilityAnalysis: const StabilityAnalysis(
            averageVariation: 25.0,
            maxVariation: 60.0,
            stableNotes: 45,
            unstableNotes: 55,
            variationHistory: [],
          ),
          feedback: const ['練習を続けましょう'],
        );

        expect(poorResult.isExcellent, isFalse);
        expect(poorResult.scoreLevel, equals('F'));
      });
    });

    group('ImprovementSuggestion', () {
      test('改善提案の基本プロパティ', () {
        const suggestion = ImprovementSuggestion(
          title: 'ピッチの安定性を向上させる',
          description: '息を深く吸って、一定のペースで歌ってみましょう',
          category: 'stability',
          priority: 1,
          specificAdvice: '腹式呼吸を意識して、4拍で息を吸い、4拍で歌ってください',
        );

        expect(suggestion.title, contains('ピッチの安定性'));
        expect(suggestion.category, equals('stability'));
        expect(suggestion.priority, equals(1));
        expect(suggestion.specificAdvice, isNotEmpty);
      });

      test('優先度による並び替え', () {
        const suggestions = [
          ImprovementSuggestion(
            title: '低優先度',
            description: 'description',
            category: 'timing',
            priority: 3,
            specificAdvice: 'specific advice',
          ),
          ImprovementSuggestion(
            title: '高優先度',
            description: 'description',
            category: 'pitch',
            priority: 1,
            specificAdvice: 'specific advice',
          ),
          ImprovementSuggestion(
            title: '中優先度',
            description: 'description',
            category: 'stability',
            priority: 2,
            specificAdvice: 'specific advice',
          ),
        ];

        final sortedSuggestions = List<ImprovementSuggestion>.from(suggestions)
          ..sort((a, b) => a.priority.compareTo(b.priority));

        expect(sortedSuggestions[0].priority, equals(1));
        expect(sortedSuggestions[1].priority, equals(2));
        expect(sortedSuggestions[2].priority, equals(3));
      });

      test('カテゴリー別のフィルタリング', () {
        const suggestions = [
          ImprovementSuggestion(
            title: 'ピッチ改善1',
            description: 'description',
            category: 'pitch',
            priority: 1,
            specificAdvice: 'specific advice',
          ),
          ImprovementSuggestion(
            title: '安定性改善1',
            description: 'description',
            category: 'stability',
            priority: 1,
            specificAdvice: 'specific advice',
          ),
          ImprovementSuggestion(
            title: 'ピッチ改善2',
            description: 'description',
            category: 'pitch',
            priority: 2,
            specificAdvice: 'specific advice',
          ),
        ];

        final pitchSuggestions = suggestions
            .where((s) => s.category == 'pitch')
            .toList();

        expect(pitchSuggestions.length, equals(2));
        expect(pitchSuggestions.every((s) => s.category == 'pitch'), isTrue);
      });
    });

    group('AudioAnalysisResult', () {
      test('音声解析結果の基本プロパティ', () {
        final timestamp = DateTime.now();
        const pitches = [440.0, 493.88, 523.25];
        
        final result = AudioAnalysisResult(
          pitches: pitches,
          sampleRate: 44100,
          createdAt: timestamp,
          sourceFile: '/path/to/audio.wav',
        );

        expect(result.pitches, equals(pitches));
        expect(result.sampleRate, equals(44100));
        expect(result.createdAt, equals(timestamp));
        expect(result.sourceFile, equals('/path/to/audio.wav'));
      });

      test('空のピッチデータでの解析結果', () {
        final result = AudioAnalysisResult(
          pitches: const [],
          sampleRate: 44100,
          createdAt: DateTime.now(),
          sourceFile: 'empty_file.wav',
        );

        expect(result.pitches, isEmpty);
        expect(result.sourceFile, equals('empty_file.wav'));
      });

      test('異なるサンプリングレートでの解析結果', () {
        final result1 = AudioAnalysisResult(
          pitches: const [440.0],
          sampleRate: 44100,
          createdAt: DateTime.now(),
          sourceFile: 'test1.wav',
        );

        final result2 = AudioAnalysisResult(
          pitches: const [440.0],
          sampleRate: 22050,
          createdAt: DateTime.now(),
          sourceFile: 'test2.wav',
        );

        expect(result1.sampleRate, equals(44100));
        expect(result2.sampleRate, equals(22050));
        expect(result1.sampleRate, isNot(equals(result2.sampleRate)));
      });
    });

    group('ScoreBreakdown', () {
      test('スコア内訳の基本プロパティ', () {
        const breakdown = ScoreBreakdown(
          pitchAccuracyScore: 85.0,
          stabilityScore: 78.0,
          timingScore: 92.0,
        );

        expect(breakdown.pitchAccuracyScore, equals(85.0));
        expect(breakdown.stabilityScore, equals(78.0));
        expect(breakdown.timingScore, equals(92.0));
      });

      test('完璧なスコア内訳', () {
        const perfectBreakdown = ScoreBreakdown(
          pitchAccuracyScore: 100.0,
          stabilityScore: 100.0,
          timingScore: 100.0,
        );

        expect(perfectBreakdown.pitchAccuracyScore, equals(100.0));
        expect(perfectBreakdown.stabilityScore, equals(100.0));
        expect(perfectBreakdown.timingScore, equals(100.0));
      });

      test('ゼロスコア内訳', () {
        const zeroBreakdown = ScoreBreakdown(
          pitchAccuracyScore: 0.0,
          stabilityScore: 0.0,
          timingScore: 0.0,
        );

        expect(zeroBreakdown.pitchAccuracyScore, equals(0.0));
        expect(zeroBreakdown.stabilityScore, equals(0.0));
        expect(zeroBreakdown.timingScore, equals(0.0));
      });
    });
  });
}
