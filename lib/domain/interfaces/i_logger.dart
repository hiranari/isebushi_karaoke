/// ロギングインターフェース
/// 
/// クリーンアーキテクチャに従い、ログ出力を抽象化
/// 外部依存（Flutter debugPrint、Console print等）から分離
abstract class ILogger {
  /// デバッグレベルのログ出力
  void debug(String message);
  
  /// 情報レベルのログ出力
  void info(String message);
  
  /// 警告レベルのログ出力
  void warning(String message);
  
  /// エラーレベルのログ出力
  void error(String message, [Object? error, StackTrace? stackTrace]);
  
  /// 成功レベルのログ出力
  void success(String message);
}
