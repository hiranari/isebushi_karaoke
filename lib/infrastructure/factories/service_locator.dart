// 注意: AudioProcessingServiceは静的メソッドのため、Service Locatorに登録せずに直接使用
// import '../services/audio_processing_service.dart';
import '../services/pitch_detection_service.dart';
// ScoringServiceも静的メソッドのため、直接使用
// import '../services/scoring_service.dart';
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
/// 
/// 責任:
/// - サービスインスタンスの生成と管理
/// - サービスへの型安全なアクセス提供
/// - アプリケーション全体での単一インスタンス保証
/// 
/// 設計パターン:
/// - Singleton: ServiceLocator自体のインスタンス管理
/// - Service Locator: サービス群の登録・取得機能
/// - Factory: サービスインスタンスの生成委譲
/// 
/// アーキテクチャ上の位置:
/// - Infrastructure層: 技術的な依存性注入機能を提供
/// - Application層とDomain層を結ぶブリッジ役
/// 
/// 使用例:
/// ```dart
/// // 初期化（アプリ起動時）
/// ServiceLocator().initialize();
/// 
/// // サービス取得
/// final pitchService = ServiceLocator().get<PitchDetectionService>();
/// ```
/// 
/// 注意事項:
/// - 静的メソッドのみのサービス（AudioProcessingService、ScoringService等）は登録不要
/// - アプリケーション起動時に必ずinitialize()を呼び出すこと
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#service-locator-pattern)
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
    
    // ログサービスを最初に登録
    registerService<ILogger>(EnhancedDebugLogger());
    
    // ログサービスを依存として注入
    final logger = getService<ILogger>();
    registerService<PitchDetectionService>(PitchDetectionService(logger: logger));
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