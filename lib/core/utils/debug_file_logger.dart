import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/interfaces/i_logger.dart';

/// デバッグ情報をファイルに自動保存するクラス
/// Copilotが読み取り可能なログファイルを生成
class DebugFileLogger implements ILogger {
  static const String _debugFileName = 'debug_session.md';
  static final List<DebugEntry> _entries = [];
  static String? _documentsPath;
  
  /// インスタンス用コンストラクタ（静的メソッドとの互換のため）
  DebugFileLogger();
  
  /// デバッグエントリ
  static void log(String category, String message, {Map<String, dynamic>? data}) {
    final entry = DebugEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      data: data,
    );
    
    _entries.add(entry);
    if (kDebugMode) {
      debugPrint('🐛 [$category] $message'); // コンソールにも出力
    }
    
    // ファイルに即座に保存
    _saveToFile();
  }

  // --- ILogger 実装（インスタンスメソッドは既存の static ロガーに委譲）
  @override
  void debug(String message) {
    DebugFileLogger.log('DEBUG', message);
  }

  @override
  void info(String message) {
    DebugFileLogger.log('INFO', message);
  }

  @override
  void warning(String message) {
    DebugFileLogger.log('WARNING', message);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final data = <String, dynamic>{};
    if (error != null) data['error'] = error.toString();
    if (stackTrace != null) data['stack'] = stackTrace.toString();
    DebugFileLogger.log('ERROR', message, data: data);
  }

  @override
  void success(String message) {
    DebugFileLogger.log('SUCCESS', message);
  }
  
  /// セッション開始
  static void startSession(String title) {
    _entries.clear();
    log('SESSION', 'デバッグセッション開始: $title');
  }
  
  /// 重要なピッチ検出情報
  static void logPitchDetection(String audioFile, List<double> pitches) {
    final validPitches = pitches.where((p) => p > 0).toList();
    final stats = _calculatePitchStats(validPitches);
    
    log('PITCH_DETECTION', '音源: $audioFile', data: {
      'total_pitches': pitches.length,
      'valid_pitches': validPitches.length,
      'valid_rate': '${(validPitches.length / pitches.length * 100).toStringAsFixed(1)}%',
      'min_pitch': stats['min']?.toStringAsFixed(1),
      'max_pitch': stats['max']?.toStringAsFixed(1),
      'avg_pitch': stats['avg']?.toStringAsFixed(1),
      'first_10_pitches': pitches.take(10).map((p) => p.toStringAsFixed(1)).toList(),
    });
  }
  
  /// 音源切り替え情報
  static void logAudioSwitch(String fromFile, String toFile, bool success) {
    log('AUDIO_SWITCH', '音源切り替え: $fromFile → $toFile', data: {
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// テスト結果
  static void logTestResult(String testName, bool success, {String? details}) {
    log('TEST_RESULT', '$testName: ${success ? "成功" : "失敗"}', data: {
      'success': success,
      'details': details,
    });
  }
  
  /// ファイルに保存
  static Future<void> _saveToFile() async {
    try {
      // 初回のみ書き込み可能なディレクトリパスを取得
      if (_documentsPath == null) {
        final directory = await getApplicationDocumentsDirectory();
        _documentsPath = directory.path;
      }
      
      final file = File('$_documentsPath/$_debugFileName');
      final markdown = _generateMarkdown();
      await file.writeAsString(markdown);
      if (kDebugMode) {
        debugPrint('🐛 [DEBUG] ログファイル保存: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ デバッグファイル保存失敗: $e');
      }
    }
  }
  
  /// Markdown形式でデバッグ情報を生成
  static String _generateMarkdown() {
    final buffer = StringBuffer();
    
    buffer.writeln('# 🐛 デバッグセッションログ');
    buffer.writeln('');
    buffer.writeln('生成日時: ${DateTime.now().toIso8601String()}');
    buffer.writeln('総エントリ数: ${_entries.length}');
    buffer.writeln('');
    
    // カテゴリ別サマリー
    final categories = _entries.map((e) => e.category).toSet();
    buffer.writeln('## 📊 カテゴリ別サマリー');
    for (final category in categories) {
      final count = _entries.where((e) => e.category == category).length;
      buffer.writeln('- **$category**: $count件');
    }
    buffer.writeln('');
    
    // 詳細ログ
    buffer.writeln('## 📝 詳細ログ');
    buffer.writeln('');
    
    for (final entry in _entries) {
      final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
      
      buffer.writeln('### [$time] ${entry.category}');
      buffer.writeln('**${entry.message}**');
      
      if (entry.data != null) {
        buffer.writeln('```json');
        buffer.writeln(const JsonEncoder.withIndent('  ').convert(entry.data));
        buffer.writeln('```');
      }
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
  
  /// ピッチ統計計算
  static Map<String, double?> _calculatePitchStats(List<double> pitches) {
    if (pitches.isEmpty) {
      return {'min': null, 'max': null, 'avg': null};
    }
    
    final min = pitches.reduce((a, b) => a < b ? a : b);
    final max = pitches.reduce((a, b) => a > b ? a : b);
    final avg = pitches.reduce((a, b) => a + b) / pitches.length;
    
    return {'min': min, 'max': max, 'avg': avg};
  }
  
  /// 現在のログをMarkdown文字列として取得
  static String getCurrentLog() {
    return _generateMarkdown();
  }
  
  /// ログをクリア
  static void clearLog() {
    _entries.clear();
    _saveToFile();
  }
  
  /// デバッグファイルのパスを取得
  static Future<String?> getDebugFilePath() async {
    try {
      if (_documentsPath == null) {
        final directory = await getApplicationDocumentsDirectory();
        _documentsPath = directory.path;
      }
      return '$_documentsPath/$_debugFileName';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ デバッグファイルパス取得失敗: $e');
      }
      return null;
    }
  }
}

/// デバッグエントリクラス
class DebugEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final Map<String, dynamic>? data;
  
  DebugEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.data,
  });
}
