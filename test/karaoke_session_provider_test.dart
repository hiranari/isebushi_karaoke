import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/providers/karaoke_session_provider.dart';
import 'package:isebushi_karaoke/models/song_result.dart';

void main() {
  group('KaraokeSessionProvider Tests', () {
    late KaraokeSessionProvider provider;

    setUp(() {
      provider = KaraokeSessionProvider();
    });

    group('Session Initialization', () {
      test('should initialize session with correct parameters', () {
        const songTitle = 'Test Song';
        
        provider.initializeSession(songTitle, [220.0, 230.0, 240.0]);
        
        expect(provider.selectedSongTitle, equals(songTitle));
        expect(provider.referencePitches, equals([220.0, 230.0, 240.0]));
        expect(provider.state, equals(KaraokeSessionState.ready));
        expect(provider.recordedPitches, isEmpty);
        final expected = [220.0, 230.0, 240.0];
      });

      test('should clear previous session data on reinitialization', () {
        final referencePitches = [220.0, 230.0, 240.0];
        provider.initializeSession('First Song', referencePitches);
        
        // Simulate some recorded data
        provider.startRecording();
        provider.updateCurrentPitch(250.0);
        provider.stopRecording();
        
        // Reinitialize with different data
        final newReferencePitches = [300.0, 310.0, 320.0];
        provider.initializeSession('Second Song', newReferencePitches);
        
        expect(provider.selectedSongTitle, equals('Second Song'));
        expect(provider.referencePitches, equals(newReferencePitches));
        expect(provider.recordedPitches, isEmpty);
        expect(provider.state, equals(KaraokeSessionState.ready));
      });
    });

    group('Recording Management', () {
      test('should start recording when ready', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        
        provider.startRecording();
        
        expect(provider.isRecording, isTrue);
        expect(provider.state, equals(KaraokeSessionState.recording));
      });

      test('should not start recording when not ready', () {
        provider.startRecording();
        
        expect(provider.isRecording, isFalse);
        expect(provider.state, equals(KaraokeSessionState.ready));
      });

      test('should stop recording and enter analyzing state', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        provider.startRecording();
        
        provider.stopRecording();
        
        expect(provider.isRecording, isFalse);
        expect(provider.state, equals(KaraokeSessionState.analyzing));
      });
    });

    group('Pitch Updates', () {
      test('should update current pitch', () {
        const testPitch = 440.0;
        
        provider.updateCurrentPitch(testPitch);
        
        expect(provider.currentPitch, equals(testPitch));
      });

      test('should record pitch during recording', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        provider.startRecording();
        
        provider.updateCurrentPitch(250.0);
        provider.updateCurrentPitch(260.0);
        
        expect(provider.recordedPitches, equals([250.0, 260.0]));
      });

      test('should not record pitch when not recording', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        
        provider.updateCurrentPitch(250.0);
        
        expect(provider.recordedPitches, isEmpty);
      });

      test('should not record invalid pitches', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        provider.startRecording();
        
        provider.updateCurrentPitch(0.0);
        provider.updateCurrentPitch(-10.0);
        provider.updateCurrentPitch(250.0);
        
        expect(provider.recordedPitches, equals([250.0]));
      });
    });

    group('Error Handling', () {
      test('should set error state with message', () {
        const errorMessage = 'Test error message';
        
        provider.setError(errorMessage);
        
        expect(provider.state, equals(KaraokeSessionState.error));
        expect(provider.errorMessage, equals(errorMessage));
      });
    });

    group('Score Display Management', () {
      test('should toggle score display modes', () {
        // Create a mock song result
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        
        // Initially hidden
        expect(provider.scoreDisplayMode, equals(ScoreDisplayMode.hidden));
        
        // Should not toggle if no result
        provider.toggleScoreDisplay();
        expect(provider.scoreDisplayMode, equals(ScoreDisplayMode.hidden));
      });
    });

    group('Session Reset', () {
      test('should reset session to initial state', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        provider.startRecording();
        provider.updateCurrentPitch(250.0);
        provider.setError('Test error');
        
        provider.resetSession();
        
        expect(provider.state, equals(KaraokeSessionState.ready));
        expect(provider.recordedPitches, isEmpty);
        expect(provider.songResult, isNull);
        expect(provider.errorMessage, isEmpty);
        expect(provider.scoreDisplayMode, equals(ScoreDisplayMode.hidden));
        expect(provider.isRecording, isFalse);
        expect(provider.currentPitch, isNull);
      });
    });

    group('Session Info', () {
      test('should return correct session information', () {
        provider.initializeSession('Test Song', [220.0, 230.0, 240.0]);
        
        final info = provider.getSessionInfo();
        
        expect(info['state'], contains('ready'));
        expect(info['songTitle'], equals('Test Song'));
        expect(info['referencePitchCount'], equals(3));
        expect(info['recordedPitchCount'], equals(0));
        expect(info['hasResult'], isFalse);
        expect(info['isRecording'], isFalse);
      });
    });
  });
}