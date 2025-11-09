import 'package:isebushi_karaoke/domain/interfaces/i_audio_processing_service.dart';

/// A mock implementation of the [IAudioProcessingService] for testing purposes.
///
/// This class allows for simulating the behavior of the real audio processing
/// service in a controlled test environment. You can configure it to return
/// specific PCM data or to throw exceptions to test error handling.
class MockAudioProcessingService implements IAudioProcessingService {
  /// The PCM data that the [extractPcm] method will return.
  /// Defaults to an empty list.
  List<int> pcmToReturn = [];

  /// If set to true, the [extractPcm] method will throw an exception.
  /// Defaults to false.
  bool shouldThrow = false;

  @override
  Future<List<int>> extractPcm({required String path, required bool isAsset}) async {
    if (shouldThrow) {
      throw Exception('Mock Audio Processing Error: Could not process $path');
    }
    // In a real test, you might want to return different data based on the path.
    // For now, we return the pre-configured list.
    return Future.value(pcmToReturn);
  }

  @override
  bool isWavFile(String filePath) {
    // A simple mock implementation.
    return filePath.toLowerCase().endsWith('.wav');
  }

  @override
  Future<bool> validateAudioFile(String filePath) async {
    // A simple mock implementation.
    if (shouldThrow) {
      return false;
    }
    return isWavFile(filePath);
  }
}
