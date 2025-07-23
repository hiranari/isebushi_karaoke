/// Analysis service interface
/// Handles detailed analysis of audio performance
abstract class IAnalysisService {
  /// Analyze pitch accuracy in detail
  /// 
  /// Returns detailed pitch analysis including accuracy metrics
  Map<String, dynamic> analyzePitchAccuracy(
    List<double> referencePitches,
    List<double> recordedPitches,
  );
  
  /// Analyze stability of pitch performance
  /// 
  /// Returns stability metrics including variation and consistency
  Map<String, dynamic> analyzeStability(List<double> pitches);
  
  /// Analyze timing of pitch performance
  /// 
  /// Returns timing analysis including synchronization metrics
  Map<String, dynamic> analyzeTiming(
    List<double> referencePitches,
    List<double> recordedPitches,
  );
  
  /// Analyze overall audio quality
  /// 
  /// Returns audio quality metrics and recommendations
  Map<String, dynamic> analyzeAudioQuality(List<int> audioData);
}
