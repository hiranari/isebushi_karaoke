---
applyTo: '**/*.dart'
description: '開発とデバッグのガイドライン'
---

# 開発ガイドライン

## Debug Access Methods

### Quick Access Commands
デバッグ情報の確認を依頼する際は、以下の簡潔なコマンドを使用：
```
@copilot デバッグ状況を確認して
```
または
```
@copilot アプリの現在の状態を教えて
```

## CopilotDebugBridge Usage

### Implementation Example
```dart
import 'package:your_app/core/utils/copilot_debug_bridge.dart';

// セッション開始時
CopilotDebugBridge.startDebugSession("カラオケページ初期化");

// 状態更新時
CopilotDebugBridge.setState("current_song", songData);
CopilotDebugBridge.setState("user_score", scoreData);

// エラー発生時
CopilotDebugBridge.reportError("AudioService", "音声ファイル読み込み失敗", 
  context: {"file": fileName, "error_code": errorCode});

// パフォーマンス測定時
final stopwatch = Stopwatch()..start();
// ... 処理実行 ...
CopilotDebugBridge.reportPerformance("pitch_detection", stopwatch.elapsed,
  result: {"accuracy": accuracy, "detected_notes": noteCount});
```

## Automated Workflows

### Error Handling
- エラー発生時の自動ログ記録
- 詳細なコンテキスト情報の保持
- トラブルシューティング情報の提供

### Performance Monitoring
- パフォーマンス指標の自動計測
- ボトルネックの特定
- 最適化提案の生成

### Development Progress
- 進捗状況の自動記録
- タスク完了状況の追跡
- 次のステップの提案

## Best Practices

### Development
- 重要な処理の前後でのデバッグ情報記録
- 適切なエラーハンドリングの実装
- パフォーマンス計測の組み込み

### コード品質管理
- Agentモードでの作業終了前に以下を必ず解消:
  - コンパイルエラー
  - 警告（Warnings）
  - Information（情報メッセージ）
- エラー解消の優先順位:
  1. コンパイルエラー
  2. 警告（Warnings）
  3. Information（情報メッセージ）

### Security and Privacy
- デバッグモードでのみ記録
- 個人情報・機密情報の除外
- リリースビルドでの自動無効化
- ログの安全な管理
