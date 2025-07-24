import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/infrastructure/services/analysis_service.dart';
import 'package:isebushi_karaoke/domain/models/comprehensive_score.dart';

/// AnalysisServiceの単体テスト
/// 
/// 詳細分析機能をテストします
void main() {
  group('AnalysisService Tests', () {
    late List<double> testReferencePitches;
    late List<double> testRecordedPitches;
    late ComprehensiveScore testScore;

    setUp(() {
      testReferencePitches = [440.0, 493.88, 523.25, 587.33]; // A4, B4, C5, D5
      testRecordedPitches = [438.0, 495.0, 520.0, 590.0];      // 少しずれた値
      testScore = const ComprehensiveScore(
        pitchAccuracy: 85.0,
        stability: 78.0,
        timing: 92.0,
        overall: 85.0,
        grade: 'A',
      );
    });

    group('詳細分析の実行', () {
      test('基本的な詳細分析が実行される', () {
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: testRecordedPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        expect(analysis, isNotNull);
        expect(analysis.pitchAnalysis, isNotEmpty);
        expect(analysis.timingAnalysis, isNotEmpty);
        expect(analysis.stabilityAnalysis, isNotEmpty);
        expect(analysis.sectionScores, isNotEmpty);
      });

      test('空のピッチデータでの分析', () {
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: [],
          referencePitches: [],
          score: testScore,
        );

        expect(analysis, isNotNull);
        // 空のデータでも適切に処理される
        expect(analysis.pitchAnalysis, isA<Map<String, dynamic>>());
        expect(analysis.timingAnalysis, isA<Map<String, dynamic>>());
      });

      test('異なる長さのピッチデータでの分析', () {
        final shortRecorded = [440.0, 493.88];
        final longReference = [440.0, 493.88, 523.25, 587.33, 659.25];

        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: shortRecorded,
          referencePitches: longReference,
          score: testScore,
        );

        expect(analysis, isNotNull);
        // 長さが異なるデータでも適切に処理される
        expect(analysis.pitchAnalysis, isA<Map<String, dynamic>>());
      });
    });

    group('ピッチ分析', () {
      test('ピッチ精度の分析', () {
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: testRecordedPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        // ピッチ分析結果が適切に生成される
        expect(analysis.pitchAnalysis, isNotEmpty);
        
        // 分析データの基本的な構造を確認
        expect(analysis.pitchAnalysis, isA<Map<String, dynamic>>());
      });

      test('完璧なピッチでの分析', () {
        final perfectPitches = [440.0, 493.88, 523.25, 587.33];
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: perfectPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        expect(analysis.pitchAnalysis, isNotEmpty);
        // 完璧なピッチでも分析が実行される
      });

      test('大きくずれたピッチでの分析', () {
        final badPitches = [400.0, 450.0, 500.0, 550.0]; // 大きく外れた値
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: badPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        expect(analysis.pitchAnalysis, isNotEmpty);
        // 外れた値でも適切に分析される
      });
    });

    group('タイミング分析', () {
      test('タイミング精度の分析', () {
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: testRecordedPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        // タイミング分析結果が適切に生成される
        expect(analysis.timingAnalysis, isNotEmpty);
        
        // 分析データの基本的な構造を確認
        expect(analysis.timingAnalysis, isA<Map<String, dynamic>>());
      });

      test('短いデータでのタイミング分析', () {
        final shortData = [440.0];
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: shortData,
          referencePitches: [440.0],
          score: testScore,
        );

        expect(analysis.timingAnalysis, isA<Map<String, dynamic>>());
        // 短いデータでも適切に処理される
      });
    });

    group('安定性分析', () {
      test('安定性の分析', () {
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: testRecordedPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        // 安定性分析結果が適切に生成される
        expect(analysis.stabilityAnalysis, isNotEmpty);
        
        // 分析データの基本的な構造を確認
        expect(analysis.stabilityAnalysis, isA<Map<String, dynamic>>());
      });

      test('変動の激しいピッチでの安定性分析', () {
        final unstablePitches = [440.0, 500.0, 400.0, 600.0]; // 激しく変動
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: unstablePitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        expect(analysis.stabilityAnalysis, isNotEmpty);
        // 不安定なピッチでも分析が実行される
      });

      test('一定のピッチでの安定性分析', () {
        final stablePitches = [440.0, 440.0, 440.0, 440.0]; // 一定のピッチ
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: stablePitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        expect(analysis.stabilityAnalysis, isNotEmpty);
        // 安定したピッチでも分析が実行される
      });
    });

    group('セクション分析', () {
      test('セクション別スコアの分析', () {
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: testRecordedPitches,
          referencePitches: testReferencePitches,
          score: testScore,
        );

        // セクション分析結果が適切に生成される
        expect(analysis.sectionScores, isNotEmpty);
        
        // 各セクションスコアの基本的な構造を確認
        expect(analysis.sectionScores, isA<Map<String, double>>());
      });

      test('長いピッチデータでのセクション分析', () {
        final longPitches = List.generate(20, (index) => 440.0 + index * 10);
        final longReference = List.generate(20, (index) => 440.0 + index * 10);
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: longPitches,
          referencePitches: longReference,
          score: testScore,
        );

        expect(analysis.sectionScores, isNotEmpty);
        // 長いデータでも適切にセクション分割される
      });
    });

    group('パフォーマンステスト', () {
      test('大きなデータセットの処理性能', () {
        // 1000サンプルのテストデータ
        final largePitches = List.generate(1000, (index) => 440.0 + (index % 100));
        final largeReference = List.generate(1000, (index) => 440.0 + (index % 100));

        final stopwatch = Stopwatch()..start();
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: largePitches,
          referencePitches: largeReference,
          score: testScore,
        );
        
        stopwatch.stop();

        expect(analysis, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒以内
      });

      test('リアルタイム処理サイズでの性能', () {
        // リアルタイム処理で想定されるサイズ（約1秒分）
        final realtimePitches = List.generate(100, (index) => 440.0 + index);
        final realtimeReference = List.generate(100, (index) => 440.0 + index);

        final stopwatch = Stopwatch()..start();
        
        final analysis = AnalysisService.performDetailedAnalysis(
          recordedPitches: realtimePitches,
          referencePitches: realtimeReference,
          score: testScore,
        );
        
        stopwatch.stop();

        expect(analysis, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 500ms以内
      });
    });

    group('エラーハンドリング', () {
      test('無効なスコアでの分析', () {
        const invalidScore = ComprehensiveScore(
          pitchAccuracy: -10.0, // 無効な値
          stability: 150.0,     // 無効な値
          timing: 85.0,
          overall: 85.0,
          grade: 'A',
        );

        expect(
          () => AnalysisService.performDetailedAnalysis(
            recordedPitches: testRecordedPitches,
            referencePitches: testReferencePitches,
            score: invalidScore,
          ),
          returnsNormally, // エラーが発生しないことを確認
        );
      });

      test('極端なピッチ値での分析', () {
        final extremePitches = [0.0, 10000.0, -100.0, 20000.0];
        
        expect(
          () => AnalysisService.performDetailedAnalysis(
            recordedPitches: extremePitches,
            referencePitches: testReferencePitches,
            score: testScore,
          ),
          returnsNormally, // エラーが発生しないことを確認
        );
      });
    });
  });
}
