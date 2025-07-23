// 注意: AudioProcessingServiceは静的メソッドのため、Service Locatorに登録せずに直接使用
// import '../services/audio_processing_service.dart';
import '../services/pitch_detection_service.dart';
// ScoringServiceも静的メソッドのため、直接使用
// import '../services/scoring_service.dart';
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
    // Register service instances
    // Note: 静的メソッドのみのサービス（AudioProcessingService, ScoringService等）は登録不要
    
    registerService<PitchDetectionService>(PitchDetectionService());
    registerService<AnalysisService>(AnalysisService());
    registerService<FeedbackService>(FeedbackService());
    registerService<CacheService>(CacheService());
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
