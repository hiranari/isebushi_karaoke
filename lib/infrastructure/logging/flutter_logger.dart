import 'package:flutter/foundation.dart';
import '../../domain/interfaces/i_logger.dart';

/// Flutter環境用のロガー実装
/// 
/// debugPrint()とkDebugModeを使用
/// リリースビルドでは出力を抑制
class FlutterLogger implements ILogger {
  @override
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  @override
  void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  @override
  void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('[ERROR] Exception: $error');
      }
      if (stackTrace != null) {
        debugPrint('[ERROR] StackTrace: $stackTrace');
      }
    }
  }
}
