import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/providers/karaoke_session_provider.dart';
import 'package:isebushi_karaoke/services/scoring_service.dart';
import 'package:isebushi_karaoke/services/feedback_service.dart';

void main() {
  group('Integration Test - Conflict Resolution Verification', () {
    test('KaraokeSessionProvider should initialize correctly', () {
      // Arrange
      final provider = KaraokeSessionProvider();
      
      // Act & Assert
      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.selectedSongTitle, isNull);
      expect(provider.referencePitches, isEmpty);
      expect(provider.recordedPitches, isEmpty);
    });

    test('KaraokeSessionProvider should handle session initialization', () {
      // Arrange
      final provider = KaraokeSessionProvider();
      final testPitches = [440.0, 493.88, 523.25];
      
      // Act
      provider.initializeSession('Test Song', testPitches);
      
      // Assert
      expect(provider.selectedSongTitle, equals('Test Song'));
      expect(provider.referencePitches, equals(testPitches));
      expect(provider.state, KaraokeSessionState.ready);
    });

    test('ScoringService integration works correctly', () {
      // Arrange
      final referencePitches = [440.0, 493.88, 523.25];
      final recordedPitches = [440.0, 493.88, 523.25];
      
      // Act
      final result = ScoringService.calculateComprehensiveScore(
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
        songTitle: 'Test Song',
      );
      
      // Assert
      expect(result.songTitle, equals('Test Song'));
      expect(result.totalScore, greaterThan(0));
      expect(result.scoreBreakdown.pitchAccuracyScore, greaterThan(0));
    });

    test('FeedbackService integration works correctly', () {
      // Arrange
      final referencePitches = [440.0, 493.88, 523.25];
      final recordedPitches = [440.0, 493.88, 523.25];
      
      final result = ScoringService.calculateComprehensiveScore(
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
        songTitle: 'Test Song',
      );
      
      // Act
      final feedback = FeedbackService.generateFeedback(result);
      
      // Assert
      expect(feedback, isNotEmpty);
      expect(feedback.first, isA<String>());
    });

    test('Score display mode progression works correctly', () {
      // Arrange
      final provider = KaraokeSessionProvider();
      provider.initializeSession('Test Song', [440.0]);
      
      // Initially hidden
      expect(provider.scoreDisplayMode, ScoreDisplayMode.hidden);
      
      // Mock having a result
      final referencePitches = [440.0];
      final recordedPitches = [440.0];
      ScoringService.calculateComprehensiveScore(
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
        songTitle: 'Test Song',
      );
      
      // Simulate getting results (normally done internally)
      // Note: We can't easily test the private _songResult, 
      // but we can test the public interface behavior
      
      // Should be able to call toggle without errors
      provider.toggleScoreDisplay();
      // Since songResult is null, mode should remain unchanged
      expect(provider.scoreDisplayMode, ScoreDisplayMode.hidden);
    });

    test('Session reset works correctly', () {
      // Arrange
      final provider = KaraokeSessionProvider();
      provider.initializeSession('Test Song', [440.0]);
      provider.updateCurrentPitch(440.0);
      
      // Act
      provider.resetSession();
      
      // Assert
      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.recordedPitches, isEmpty);
      expect(provider.currentPitch, isNull);
      expect(provider.scoreDisplayMode, ScoreDisplayMode.hidden);
    });
  });
}