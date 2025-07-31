# Copilot開発支援ガイドライン

## 概要

このガイドラインは、GitHub CopilotがFlutterアプリケーションのデバッグとトラブルシューティングを効率的に行うための標準的な手順とアクセス方法を定義します。

## Copilotデバッグアクセス方法

### 🚀 **クイックアクセスコマンド**

Copilotにデバッグ情報の確認を依頼する際は、以下の簡潔なコマンドを使用してください：

```
@copilot デバッグ状況を確認して
```

または

```
@copilot アプリの現在の状態を教えて
```

### 📂 **自動アクセス可能なファイル**

Copilotは以下のファイルに自動的にアクセスしてデバッグ情報を取得できます：

#### 1. **リアルタイムデバッグログ**
- **パス**: `~/Documents/copilot_debug.json`
- **内容**: アプリの現在の状態、エラー、パフォーマンス情報
- **更新**: アプリ実行中にリアルタイム更新
- **フォーマット**: JSON（構造化データ）

#### 2. **セッションログ**
- **パス**: `docs/development/debug_session.md`
- **内容**: 詳細なデバッグセッション履歴
- **フォーマット**: Markdown（可読性重視）

#### 3. **ターミナル出力**
- **コマンド**: `flutter logs`
- **内容**: リアルタイムのFlutterログ
- **アクセス**: `get_terminal_output` ツール

### 🔧 **CopilotDebugBridgeの使用方法**

#### アプリ側の実装例
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

// クイック報告
CopilotDebugBridge.quickReport("新機能テスト完了", 
  data: {"success_rate": "98%", "issues": ["minor UI glitch"]});
```

#### Copilot側のアクセス例
```markdown
# デバッグ情報の確認手順
1. read_file("~/Documents/copilot_debug.json") でリアルタイム状態を確認
2. read_file("docs/development/debug_session.md") で履歴を確認
3. get_terminal_output() でターミナル出力を確認
```

### 📊 **デバッグ情報の構造**

#### copilot_debug.jsonの構造
```json
{
  "session_id": "1690234567890",
  "app_state": {
    "debug_session": {
      "name": "カラオケページ初期化",
      "started_at": "2025-07-29T10:30:00.000Z",
      "status": "active"
    },
    "current_song": "Test.wav",
    "user_score": {"pitch_accuracy": 95.2, "timing": 88.5},
    "last_error": {
      "component": "AudioService",
      "error": "音声ファイル読み込み失敗",
      "context": {"file": "broken.wav", "error_code": 404},
      "timestamp": "2025-07-29T10:35:00.000Z"
    },
    "performance": [
      {
        "operation": "pitch_detection",
        "duration_ms": 245,
        "result": {"accuracy": 95.2, "detected_notes": 120},
        "timestamp": "2025-07-29T10:32:00.000Z"
      }
    ],
    "quick_report": {
      "message": "新機能テスト完了",
      "data": {"success_rate": "98%", "issues": ["minor UI glitch"]},
      "timestamp": "2025-07-29T10:40:00.000Z"
    },
    "last_updated": "2025-07-29T10:40:00.000Z"
  },
  "generated_at": "2025-07-29T10:40:00.000Z",
  "copilot_access_info": {
    "file_path": "/Users/username/Documents/copilot_debug.json",
    "access_method": "read_file tool",
    "format": "JSON"
  }
}
```

### 🎯 **効率的なCopilotとのやり取り**

#### ❌ **非推奨**: 長いプロンプト
```
Copilotさん、今アプリでエラーが起きているんですが、AudioServiceでファイル読み込みができません。Test.wavというファイルを読み込もうとしているのですが、エラーコード404が出ています。ピッチ検出の精度は95.2%で、タイミングは88.5%です。これまでのセッションは...（長文続く）
```

#### ✅ **推奨**: 簡潔なコマンド
```
@copilot デバッグ状況を確認して
```

または

```
@copilot AudioServiceのエラーを調査して
```

### 🔄 **自動化されたワークフロー**

1. **問題発生時**:
   - アプリが自動的に `CopilotDebugBridge.reportError()` を呼び出し
   - エラー情報が `copilot_debug.json` に即座に記録
   - Copilotが簡潔なコマンドで状況を把握可能

2. **パフォーマンス監視時**:
   - アプリが自動的に `CopilotDebugBridge.reportPerformance()` を呼び出し
   - パフォーマンス履歴が蓄積
   - Copilotがトレンド分析や最適化提案を実行

3. **開発進捗確認時**:
   - `CopilotDebugBridge.quickReport()` で進捗を記録
   - Copilotが開発状況を即座に把握
   - 次のタスクや改善点を提案

### 📝 **ベストプラクティス**

#### 開発者側
- 重要な処理の前後で `CopilotDebugBridge` を呼び出す
- エラーハンドリング部分には必ず `reportError()` を追加
- パフォーマンスが重要な処理には `reportPerformance()` を追加

#### Copilot使用時
- 詳細な説明よりも簡潔なコマンドを使用
- デバッグファイルの自動読み取りを活用
- 必要に応じて特定のコンポーネントに焦点を当てた質問をする

### 🔒 **セキュリティとプライバシー**

- デバッグ情報は `kDebugMode` でのみ記録
- 個人情報や機密情報は `CopilotDebugBridge` に記録しない
- リリースビルドでは自動的に無効化
- ログファイルはローカルのDocumentsフォルダに限定保存

## まとめ

このガイドラインにより、Copilotとの協力開発において：
- プロンプトが大幅に簡潔になる
- デバッグ情報の共有が自動化される
- トラブルシューティングが迅速になる
- 開発効率が向上する
