import '../../domain/interfaces/i_audio_processing_service.dart';
import '../../domain/interfaces/i_pitch_detection_service.dart';
import '../../domain/interfaces/i_scoring_service.dart';
import '../../domain/interfaces/i_analysis_service.dart';
import '../../domain/interfaces/i_feedback_service.dart';
import '../../domain/interfaces/i_cache_service.dart';

import '../services/audio_processing_service.dart';
import '../services/pitch_detection_service.dart';
import '../services/scoring_service.dart';
import '../services/analysis_service.dart';
import '../services/feedback_service.dart';
import '../services/cache_service.dart';

/// Service locator for dependency injection
/// 
/// Manages service instances and provides a centralized way to access services
/// throughout the application. Follows the Service Locator pattern.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Initialize all services
  /// 
  /// This should be called during app initialization
  void initialize() {
    // Register service implementations
    registerService<IAudioProcessingService>(AudioProcessingService());
    registerService<IPitchDetectionService>(PitchDetectionService());
    registerService<IScoringService>(ScoringService());
    registerService<IAnalysisService>(AnalysisService());
    registerService<IFeedbackService>(FeedbackService());
    registerService<ICacheService>(CacheService());
  }

  /// Register a service instance
  /// 
  /// Stores the service instance for later retrieval
  void registerService<T>(T service) {
    _services[T] = service;
  }

  /// Get a service instance
  /// 
  /// Returns the registered service instance of type T
  /// Throws [StateError] if the service is not registered
  T getService<T>() {
    final service = _services[T];
    if (service == null) {
      throw StateError('Service of type $T is not registered');
    }
    return service as T;
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  /// Reset all services (mainly for testing)
  void reset() {
    _services.clear();
  }

  /// Get all registered services
  Map<Type, dynamic> get services => Map.unmodifiable(_services);
}
