import '../../domain/interfaces/i_audio_processing_service.dart';
import '../../domain/interfaces/i_pitch_detection_service.dart';
import '../services/audio_processing_service.dart';
import '../services/pitch_detection_service.dart';
import '../services/analysis_service.dart';
import '../services/feedback_service.dart';
import '../services/cache_service.dart';
import '../../core/utils/enhanced_debug_logger.dart';
import '../../domain/interfaces/i_logger.dart';

/// 依存性注入のためのサービスロケーター
///
/// アプリケーション全体でサービスインスタンスを管理し、
/// サービスへの一元的なアクセス方法を提供します。
/// Service Locatorパターンを実装しています。
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Initialize all services
  ///
  /// This should be called during app initialization
  void initialize() {
    // ログサービスを最初に登録
    registerService<ILogger>(EnhancedDebugLogger());
    final logger = getService<ILogger>();

    // Infrastructure Services
    registerService<IAudioProcessingService>(AudioProcessingService());
    registerService<IPitchDetectionService>(PitchDetectionService(
      logger: logger,
      audioProcessor: getService<IAudioProcessingService>(),
    ));
    
    // Application/Domain Services
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
    // If no services were registered yet, initialize defaults lazily.
    if (_services.isEmpty) {
      initialize();
    }

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