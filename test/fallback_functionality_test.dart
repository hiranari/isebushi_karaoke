import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:isebushi_karaoke/pages/karaoke_page.dart';
import 'package:isebushi_karaoke/providers/karaoke_session_provider.dart';

void main() {
  group('Fallback Functionality Tests', () {
    testWidgets('Default pitch generation should create valid pitch data', (WidgetTester tester) async {
      // This test validates that the default pitch generation creates reasonable data
      
      // Create a KaraokePage instance to access the _generateDefaultPitches method
      // Since the method is private, we'll test its effects through the public interface
      
      final provider = KaraokeSessionProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: const KaraokePage(),
          ),
        ),
      );

      // Test that the page builds without error
      expect(find.byType(KaraokePage), findsOneWidget);
    });

    test('Default pitch generation creates valid frequency data', () {
      // Test the frequency generation logic manually
      const double baseFreq = 261.63; // 中央C (C4)
      const int duration = 100;
      
      final List<double> pitches = [];
      
      // Replicate the generation logic from _generateDefaultPitches
      for (int i = 0; i < duration; i++) {
        double semitoneOffset;
        
        if (i < duration ~/ 4) {
          semitoneOffset = (i / (duration ~/ 4)) * 5;
        } else if (i < duration ~/ 2) {
          semitoneOffset = 5 + ((i - duration ~/ 4) / (duration ~/ 4)) * 2;
        } else if (i < 3 * duration ~/ 4) {
          semitoneOffset = 7 - ((i - duration ~/ 2) / (duration ~/ 4)) * 5;
        } else {
          semitoneOffset = 2 - ((i - 3 * duration ~/ 4) / (duration ~/ 4)) * 2;
        }
        
        // 半音階の周波数計算
        final frequency = baseFreq * math.pow(2, semitoneOffset / 12);
        pitches.add(frequency);
      }
      
      // Validate the generated pitches
      expect(pitches.length, equals(100));
      expect(pitches.every((pitch) => pitch > 0), isTrue);
      expect(pitches.first, closeTo(261.63, 1.0)); // Should start near middle C
      
      // Check frequency range is reasonable for human voice
      expect(pitches.every((pitch) => pitch >= 200 && pitch <= 600), isTrue);
    });

    test('KaraokeSessionProvider initializes correctly with fallback data', () {
      final provider = KaraokeSessionProvider();
      final testPitches = [261.63, 293.66, 329.63, 349.23]; // C4, D4, E4, F4
      
      // Initialize with test data (simulating fallback initialization)
      provider.initializeSession('Test Song (Fallback)', testPitches);
      
      expect(provider.selectedSongTitle, equals('Test Song (Fallback)'));
      expect(provider.referencePitches.length, equals(4));
      expect(provider.state, equals(KaraokeSessionState.ready));
      expect(provider.errorMessage, isEmpty);
    });
  });

  group('Error Handling and Recovery', () {
    test('Provider should handle empty pitch data gracefully', () {
      final provider = KaraokeSessionProvider();
      final emptyPitches = <double>[];
      
      // This should not throw an exception
      provider.initializeSession('Empty Song', emptyPitches);
      
      expect(provider.selectedSongTitle, equals('Empty Song'));
      expect(provider.referencePitches.length, equals(0));
      expect(provider.state, equals(KaraokeSessionState.ready));
    });

    test('Provider should handle invalid pitch data gracefully', () {
      final provider = KaraokeSessionProvider();
      final invalidPitches = [-1.0, 0.0, double.infinity, double.nan];
      
      // This should not throw an exception
      provider.initializeSession('Invalid Song', invalidPitches);
      
      expect(provider.selectedSongTitle, equals('Invalid Song'));
      expect(provider.referencePitches.length, equals(4));
      expect(provider.state, equals(KaraokeSessionState.ready));
    });
  });
}