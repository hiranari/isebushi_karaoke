import '../models/song_result.dart';
import '../models/improvement_suggestion.dart';

/// Feedback service interface
/// Handles feedback generation and improvement suggestions
abstract class IFeedbackService {
  /// Generate basic feedback based on score
  /// 
  /// Returns a list of feedback messages
  List<String> generateBasicFeedback(double totalScore);
  
  /// Generate improvement suggestions based on performance
  /// 
  /// Returns a list of specific improvement suggestions
  List<ImprovementSuggestion> generateImprovementSuggestions(
    Map<String, double> scoreBreakdown,
    Map<String, double> statistics,
  );
  
  /// Suggest next practice goals based on song result
  /// 
  /// Returns a map of suggested targets and messages
  Map<String, double> suggestNextGoals(SongResult songResult);
  
  /// Get encouragement message based on score
  /// 
  /// Returns an appropriate encouragement message
  String getEncouragementMessage(double totalScore);
}
