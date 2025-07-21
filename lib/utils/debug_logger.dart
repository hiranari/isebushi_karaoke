import 'package:flutter/foundation.dart';

/// デバッグログ用のユーティリティクラス
/// 
/// エラーメッセージを視覚的に目立たせ、デバッグコンソールで
/// 重要な情報を見つけやすくします。
class DebugLogger {
  /// エラーレベルのログを出力
  /// 
  /// [message] エラーメッセージ
  /// [error] エラーオブジェクト（オプション）
  /// [stackTrace] スタックトレース（オプション）
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final errorBox = _createErrorBox(message, error, stackTrace);
      debugPrint(errorBox);
    }
  }

  /// 警告レベルのログを出力
  /// 
  /// [message] 警告メッセージ
  static void warning(String message) {
    if (kDebugMode) {
      final warningBox = _createWarningBox(message);
      debugPrint(warningBox);
    }
  }

  /// 情報レベルのログを出力
  /// 
  /// [message] 情報メッセージ
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// 成功メッセージのログを出力
  /// 
  /// [message] 成功メッセージ
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ SUCCESS: $message');
    }
  }

  /// エラーボックスを作成
  static String _createErrorBox(String message, Object? error, StackTrace? stackTrace) {
    final buffer = StringBuffer();
    
    // エラーボックスの上部
    buffer.writeln('╔${'═' * 60}╗');
    buffer.writeln('║${_centerText('🚨 ERROR', 60)}║');
    buffer.writeln('╠${'═' * 60}╣');
    
    // メッセージ部分
    final messageLines = message.split('\n');
    for (final line in messageLines) {
      buffer.writeln('║ ${_padText(line, 58)} ║');
    }
    
    // エラーオブジェクトがある場合
    if (error != null) {
      buffer.writeln('╠${'─' * 60}╣');
      buffer.writeln('║ ${_padText('Error Object:', 58)} ║');
      final errorLines = error.toString().split('\n');
      for (final line in errorLines) {
        buffer.writeln('║ ${_padText(line, 58)} ║');
      }
    }
    
    // スタックトレースがある場合（最初の数行のみ）
    if (stackTrace != null) {
      buffer.writeln('╠${'─' * 60}╣');
      buffer.writeln('║ ${_padText('Stack Trace:', 58)} ║');
      final stackLines = stackTrace.toString().split('\n').take(5);
      for (final line in stackLines) {
        buffer.writeln('║ ${_padText(line, 58)} ║');
      }
      if (stackTrace.toString().split('\n').length > 5) {
        buffer.writeln('║ ${_padText('... (truncated)', 58)} ║');
      }
    }
    
    // エラーボックスの下部
    buffer.writeln('╚${'═' * 60}╝');
    
    return buffer.toString();
  }

  /// 警告ボックスを作成
  static String _createWarningBox(String message) {
    final buffer = StringBuffer();
    
    buffer.writeln('┌${'─' * 40}┐');
    buffer.writeln('│${_centerText('⚠️ WARNING', 40)}│');
    buffer.writeln('├${'─' * 40}┤');
    
    final messageLines = message.split('\n');
    for (final line in messageLines) {
      buffer.writeln('│ ${_padText(line, 38)} │');
    }
    
    buffer.writeln('└${'─' * 40}┘');
    
    return buffer.toString();
  }

  /// テキストを中央揃えする
  static String _centerText(String text, int width) {
    if (text.length >= width) return text;
    final padding = (width - text.length) ~/ 2;
    final leftPadding = ' ' * padding;
    final rightPadding = ' ' * (width - text.length - padding);
    return '$leftPadding$text$rightPadding';
  }

  /// テキストを指定幅にパディングする
  static String _padText(String text, int width) {
    if (text.length >= width) {
      return '${text.substring(0, width - 3)}...';
    }
    return text.padRight(width);
  }

  /// 開発環境でのみ実行されるデバッグコード用のヘルパー
  /// 
  /// [action] 実行するアクション
  static void debugOnly(VoidCallback action) {
    if (kDebugMode) {
      action();
    }
  }

  /// パフォーマンス測定用のヘルパー
  /// 
  /// [label] 測定対象の名前
  /// [action] 測定するアクション
  static T measure<T>(String label, T Function() action) {
    if (kDebugMode) {
      final stopwatch = Stopwatch()..start();
      final result = action();
      stopwatch.stop();
      info('⏱️ $label: ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } else {
      return action();
    }
  }

  /// 条件付きログ出力
  /// 
  /// [condition] ログ出力の条件
  /// [message] ログメッセージ
  static void conditional(bool condition, String message) {
    if (kDebugMode && condition) {
      info(message);
    }
  }
}
