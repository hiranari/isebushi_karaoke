import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Copilotが簡単にアクセスできるデバッグブリッジ
/// 
/// このクラスはCopilotがアプリの状態とデバッグ情報に
/// アクセスしやすくするための専用インターフェースです。
class CopilotDebugBridge {
  static const String _copilotLogFile = 'copilot_debug.json';
  static final Map<String, dynamic> _state = {};
  static String? _sessionId;

  static String get _currentSessionId => _sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();
  
  /// Copilot用の状態を設定
  static void setState(String key, dynamic value) {
    if (kDebugMode) {
      _state[key] = value;
      _state['last_updated'] = DateTime.now().toIso8601String();
      _saveStateToFile();
      debugPrint('🤖 COPILOT_STATE: $key = $value');
    }
  }
  
  /// Copilot用の複数状態を一括設定
  static void setStates(Map<String, dynamic> states) {
    if (kDebugMode) {
      _state.addAll(states);
      _state['last_updated'] = DateTime.now().toIso8601String();
      _saveStateToFile();
      debugPrint('🤖 COPILOT_STATES: ${states.keys.join(", ")}');
    }
  }
  
  /// エラー情報をCopilot向けに記録
  static void reportError(String component, String error, {dynamic context}) {
    if (kDebugMode) {
      final errorInfo = {
        'component': component,
        'error': error,
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _state['last_error'] = errorInfo;
      _saveStateToFile();
      debugPrint('🤖 COPILOT_ERROR: [$component] $error');
    }
  }
  
  /// パフォーマンス情報をCopilot向けに記録
  static void reportPerformance(String operation, Duration duration, {dynamic result}) {
    if (kDebugMode) {
      final perfInfo = {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'result': result,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (_state['performance'] == null) {
        _state['performance'] = [];
      }
      (_state['performance'] as List).add(perfInfo);
      
      // 最新20件のみ保持
      if ((_state['performance'] as List).length > 20) {
        (_state['performance'] as List).removeAt(0);
      }
      
      _saveStateToFile();
      debugPrint('🤖 COPILOT_PERF: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  /// 現在の状態をJSON形式でファイルに保存
  static Future<void> _saveStateToFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_copilotLogFile');
      
      final jsonData = {
        'session_id': _currentSessionId,
        'app_state': _state,
        'generated_at': DateTime.now().toIso8601String(),
        'copilot_access_info': {
          'file_path': file.path,
          'access_method': 'read_file tool',
          'format': 'JSON',
        }
      };
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData)
      );
    } catch (e) {
      debugPrint('⚠️ COPILOT_BRIDGE: Failed to save state: $e');
    }
  }
  
  /// セッションIDを生成（アプリ起動ごとに一意）
  static String _getSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Copilot用のクイック状態レポート
  static void quickReport(String message, {dynamic data}) {
    if (kDebugMode) {
      setState('quick_report', {
        'message': message,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }
  
  /// デバッグセッション開始をCopilotに通知
  static void startDebugSession(String sessionName) {
    if (kDebugMode) {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString(); // セッション開始時に新しいIDを生成
      _state.clear();
      setState('debug_session', {
        'name': sessionName,
        'started_at': DateTime.now().toIso8601String(),
        'status': 'active',
      });
    }
  }
  
  /// デバッグセッション終了をCopilotに通知
  static void endDebugSession({String? summary}) {
    if (kDebugMode) {
      setState('debug_session', {
        ..._state['debug_session'] ?? {},
        'ended_at': DateTime.now().toIso8601String(),
        'status': 'completed',
        'summary': summary,
      });
    }
  }
}
