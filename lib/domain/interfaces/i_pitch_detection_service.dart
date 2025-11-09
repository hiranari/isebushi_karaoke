/// Pitch detection service interface
/// Handles real-time and file-based pitch detection
abstract class IPitchDetectionService {
  /// Extract pitch data from an audio file
  ///
  /// Returns a list of detected pitch values in Hz
  /// Throws [PitchDetectionException] if detection fails
  Future<List<double>> extractPitchFromAudio({
    required String path,
    required bool isAsset,
    List<double>? referencePitches,
  });

  /// Detect pitch from PCM audio data
  ///
  /// Returns detected pitch in Hz or null if no pitch detected
  Future<double?> detectPitchFromPcm(List<int> pcmData);

  /// Validate if a pitch value is within acceptable range
  bool isValidPitch(double pitch);

  /// Normalize frequency to standard range
  double normalizeFrequency(double frequency, {double? referencePitch});
}
