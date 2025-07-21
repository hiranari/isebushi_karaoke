/// DebugLoggerの使用例とテストケース
/// 
/// このファイルは実際のエラーログがどのように表示されるかを
/// 確認するためのサンプルです。
import '../lib/utils/debug_logger.dart';

void main() {
  // エラーログのサンプル
  DebugLogger.error(
    '音源ファイルの読み込みに失敗しました',
    Exception('File not found: assets/sounds/missing.mp3'),
  );

  // 警告ログのサンプル
  DebugLogger.warning('マイクの権限が取得できませんでした');

  // 情報ログのサンプル
  DebugLogger.info('ピッチデータの解析を開始しています');

  // 成功ログのサンプル
  DebugLogger.success('録音が正常に完了しました');

  // パフォーマンス測定のサンプル
  final result = DebugLogger.measure('データベース検索', () {
    // 重い処理のシミュレーション
    return '検索結果';
  });

  // 条件付きログのサンプル
  final debugEnabled = true;
  DebugLogger.conditional(debugEnabled, 'デバッグモードが有効です');

  print('DebugLoggerのサンプル実行完了: $result');
}
