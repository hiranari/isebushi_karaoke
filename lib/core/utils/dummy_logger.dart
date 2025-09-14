import '../../domain/interfaces/i_logger.dart';

/// ダミーロガー
/// 
/// 何もせずに無視するロガー実装
class DummyLogger implements ILogger {
  @override
  void debug(String message) {
    // 何もしない
  }

  @override
  void info(String message) {
    // 何もしない
  }

  @override
  void warning(String message) {
    // 何もしない
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    // 何もしない
  }
}
