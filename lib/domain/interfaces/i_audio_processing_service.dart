/// Audio processing service interface
/// Handles WAV file processing and PCM data extraction
abstract class IAudioProcessingService {
  /// Extract PCM data from a WAV file source (asset or local file).
  ///
  /// Returns raw PCM data as [List<int>]
  Future<List<int>> extractPcm({required String path, required bool isAsset});

  /// Check if the file is a valid WAV format
  bool isWavFile(String filePath);

  /// Validate audio file format and quality
  Future<bool> validateAudioFile(String filePath);
}
