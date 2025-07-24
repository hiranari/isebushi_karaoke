import '../models/comprehensive_score.dart';

/// Scoring service interface
/// Handles score calculation and ranking
abstract class IScoringService {
  /// Calculate comprehensive score from reference and recorded pitches
  ComprehensiveScore calculateComprehensiveScore(
    List<double> referencePitches,
    List<double> recordedPitches,
  );
  
  /// Calculate pitch accuracy score (0-100)
  double calculatePitchAccuracy(
    List<double> referencePitches,
    List<double> recordedPitches,
  );
  
  /// Calculate stability score based on pitch variations (0-100)
  double calculateStability(List<double> pitches);
  
  /// Calculate timing score based on pitch alignment (0-100)
  double calculateTiming(
    List<double> referencePitches,
    List<double> recordedPitches,
  );
  
  /// Get score rank based on total score
  String getScoreRank(double score);
  
  /// Get score comment based on total score
  String getScoreComment(double score);
}
