import '../models/audio_analysis_result.dart';

/// Audio processing service interface
/// Handles WAV file processing and PCM data extraction
abstract class IAudioProcessingService {
  /// Extract PCM data from a WAV file
  ///
  /// Returns raw PCM data as [List<int>]
  Future<List<int>> extractPcmFromWav(String filePath);

  /// Check if the file is a valid WAV format
  bool isWavFile(String filePath);

  /// Validate audio file format and quality
  ///
  /// Returns true if the file is suitable for processing
  Future<bool> validateAudioFile(String filePath);
}
