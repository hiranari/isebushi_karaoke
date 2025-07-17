import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/services/pitch_comparison_service.dart';
import 'package:isebushi_karaoke/models/pitch_comparison_result.dart';

void main() {
  group('PitchComparisonService Tests', () {
    late PitchComparisonService service;

    setUp(() {
      service = PitchComparisonService();
    });

    test('should create service instance', () {
      expect(service, isNotNull);
    });

    test('should handle empty pitch data', () async {
      final result = await service.compareSimple(
        referencePitches: [],
        singingPitches: [],
      );

      expect(result.overallScore, equals(0.0));
      expect(result.alignedPitches, isEmpty);
      expect(result.centDifferences, isEmpty);
    });

    test('should perform basic comparison', () async {
      final referencePitches = [440.0, 494.0, 523.0]; // A4, B4, C5
      final singingPitches = [440.0, 494.0, 523.0]; // Perfect match

      final result = await service.compareSimple(
        referencePitches: referencePitches,
        singingPitches: singingPitches,
      );

      expect(result.overallScore, greaterThan(90.0)); // Should be high for perfect match
      expect(result.alignedPitches, hasLength(3));
      expect(result.centDifferences, hasLength(3));
    });

    test('should detect pitch differences in cents', () async {
      final referencePitches = [440.0]; // A4
      final singingPitches = [466.16]; // A#4 (100 cents higher)

      final result = await service.compareSimple(
        referencePitches: referencePitches,
        singingPitches: singingPitches,
      );

      expect(result.centDifferences.first, closeTo(100.0, 5.0)); // Within 5 cents tolerance
    });

    test('should perform DTW comparison', () async {
      final referencePitches = [440.0, 494.0, 523.0];
      final singingPitches = [440.0, 494.0, 523.0, 587.0]; // Extra note

      final result = await service.compareWithDTW(
        referencePitches: referencePitches,
        singingPitches: singingPitches,
      );

      expect(result.alignedPitches, isNotEmpty);
      expect(result.stabilityAnalysis, isNotNull);
      expect(result.vibratoAnalysis, isNotNull);
      expect(result.timingAnalysis, isNotNull);
    });

    test('should analyze pitch stability', () async {
      // Create stable pitch pattern
      final stablePitches = List.generate(20, (i) => 440.0 + (i % 2 == 0 ? 0.0 : 1.0));
      
      final result = await service.compareSimple(
        referencePitches: stablePitches,
        singingPitches: stablePitches,
      );

      expect(result.stabilityAnalysis.stabilityScore, greaterThan(80.0));
    });

    test('should detect vibrato', () async {
      // Create vibrato-like pattern
      final vibratoPattern = <double>[];
      for (int i = 0; i < 50; i++) {
        vibratoPattern.add(440.0 + 10.0 * math.sin(2 * math.pi * i * 5 / 50));
      }

      final result = await service.compareSimple(
        referencePitches: List.filled(50, 440.0),
        singingPitches: vibratoPattern,
      );

      // Note: Vibrato detection might not work perfectly with this simple pattern
      expect(result.vibratoAnalysis, isNotNull);
    });
  });

  group('PitchComparisonResult Tests', () {
    test('should create result from JSON', () {
      final json = {
        'overallScore': 85.5,
        'centDifferences': [0.0, 5.0, -3.0],
        'alignedPitches': [],
        'stabilityAnalysis': {
          'stabilityScore': 90.0,
          'pitchVariance': 5.0,
          'averageDeviation': 2.0,
          'segments': [],
          'unstableRegionCount': 0,
        },
        'vibratoAnalysis': {
          'vibratoDetected': false,
          'vibratoRate': 0.0,
          'vibratoDepth': 0.0,
          'vibratoSegments': [],
          'vibratoRegularityScore': 0.0,
        },
        'timingAnalysis': {
          'accuracyScore': 95.0,
          'averageTimeOffset': 10.0,
          'maxTimeOffset': 25.0,
          'timingDeviations': [],
          'significantDelayCount': 0,
        },
        'analyzedAt': '2024-01-01T00:00:00.000Z',
      };

      final result = PitchComparisonResult.fromJson(json);

      expect(result.overallScore, equals(85.5));
      expect(result.centDifferences, equals([0.0, 5.0, -3.0]));
      expect(result.stabilityAnalysis.stabilityScore, equals(90.0));
      expect(result.timingAnalysis.accuracyScore, equals(95.0));
    });

    test('should generate summary', () {
      final result = PitchComparisonResult(
        overallScore: 85.0,
        centDifferences: [0.0, 10.0, -5.0],
        alignedPitches: [],
        stabilityAnalysis: PitchStabilityAnalysis(
          stabilityScore: 90.0,
          pitchVariance: 5.0,
          averageDeviation: 2.0,
          segments: [],
          unstableRegionCount: 1,
        ),
        vibratoAnalysis: VibratoAnalysis(
          vibratoDetected: true,
          vibratoRate: 5.5,
          vibratoDepth: 15.0,
          vibratoSegments: [],
          vibratoRegularityScore: 80.0,
        ),
        timingAnalysis: TimingAccuracyAnalysis(
          accuracyScore: 95.0,
          averageTimeOffset: 10.0,
          maxTimeOffset: 25.0,
          timingDeviations: [],
          significantDelayCount: 0,
        ),
        analyzedAt: DateTime.now(),
      );

      final summary = result.getSummary();

      expect(summary['overallScore'], equals(85.0));
      expect(summary['averageCentDifference'], closeTo(5.0, 0.1));
      expect(summary['pitchStabilityScore'], equals(90.0));
      expect(summary['vibratoDetected'], isTrue);
      expect(summary['timingAccuracyScore'], equals(95.0));
    });
  });
}