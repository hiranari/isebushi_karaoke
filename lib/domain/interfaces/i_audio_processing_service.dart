/// Audio processing service interface
/// Handles WAV file processing and PCM data extraction
abstract class IAudioProcessingService {
  /// Extract pitch data from a WAV audio file
  /// 
  /// Returns a list of detected pitch values in Hz
  /// Throws [AudioProcessingException] if the file is invalid or processing fails
  Future<List<double>> extractPitchFromAudio(String filePath);
  
  /// Extract PCM data from a WAV file
  /// 
  /// Returns raw PCM data as Uint8List
  /// Throws [AudioProcessingException] if the file is not a valid WAV
  Future<List<int>> extractPcmFromWav(String filePath);
  
  /// Check if the file is a valid WAV format
  bool isWavFile(String filePath);
  
  /// Validate audio file format and quality
  /// 
  /// Returns true if the file is suitable for processing
  Future<bool> validateAudioFile(String filePath);
}
