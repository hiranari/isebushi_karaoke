import 'dart:io';
import '../../domain/interfaces/i_logger.dart';

/// コンソール環境用のロガー実装
/// 
/// 標準出力とstderrを使用
/// Flutter依存なしで動作
class ConsoleLogger implements ILogger {
  @override
  void debug(String message) {
    stdout.writeln('[DEBUG] $message');
  }

  @override
  void info(String message) {
    stdout.writeln('[INFO] $message');
  }

  @override
  void warning(String message) {
    stderr.writeln('[WARNING] $message');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    stderr.writeln('[ERROR] $message');
    if (error != null) {
      stderr.writeln('[ERROR] Exception: $error');
    }
    if (stackTrace != null) {
      stderr.writeln('[ERROR] StackTrace: $stackTrace');
    }
  }
}
