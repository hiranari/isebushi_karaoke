import 'package:flutter/foundation.dart';
import '../../domain/interfaces/i_logger.dart';
import 'debug_logger.dart';

/// ILoggerインターフェースを実装したDebugLoggerラッパー
/// 
/// 既存のDebugLoggerの視覚効果を保持しながら、
/// ILoggerインターフェースに準拠し、依存性注入をサポート
class EnhancedDebugLogger implements ILogger {
  /// デバッグレベルのログを出力
  /// 
  /// [message] デバッグメッセージ
  @override
  void debug(String message) {
    if (kDebugMode) {
      debugPrint('🐛 DEBUG: $message');
    }
  }

  /// エラーレベルのログを出力
  /// 
  /// [message] エラーメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    // 既存のDebugLoggerの視覚効果を使用
    DebugLogger.error(message, error, stackTrace);
  }

  /// 警告レベルのログを出力
  /// 
  /// [message] 警告メッセージ
  @override
  void warning(String message) {
    // 既存のDebugLoggerの視覚効果を使用
    DebugLogger.warning(message);
  }

  /// 情報レベルのログを出力
  /// 
  /// [message] 情報メッセージ
  @override
  void info(String message) {
    // 既存のDebugLoggerの視覚効果を使用
    DebugLogger.info(message);
  }

  /// 成功メッセージのログを出力
  /// 
  /// [message] 成功メッセージ
  @override
  void success(String message) {
    // 既存のDebugLoggerの視覚効果を使用
    DebugLogger.success(message);
  }
}
