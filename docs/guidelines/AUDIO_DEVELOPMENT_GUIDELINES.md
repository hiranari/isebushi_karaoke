# 音声開発ガイドライン

## 概要

このガイドラインは、伊勢節カラオケアプリの音声関連機能開発における統一基準を定義します。

## 音声ファイル形式

### サポート形式
- **推奨**: WAV（PCM、16bit、44.1kHz）
- **理由**: ピッチ検出の精度と処理速度の最適化

### 非サポート形式
- **MP3**: デコード処理の複雑性とリアルタイム処理への影響
- **AAC/M4A**: 同上の理由

## デバッグとロギング

### 🚫 **絶対禁止事項**

#### 1. print文の使用は**コードレビューで却下**
```dart
// ❌ 絶対に使用禁止（コミット拒否対象）
print('デバッグ情報');
print('エラー: $error');
```

**違反した場合**:
- **Problemsパネルに300+の警告が発生**
- **コードレビューで即座に却下**
- **CI/CDパイプラインでビルド失敗**
- **リファクタリング作業が無意味になる**

#### 2. 自動検証の追加

このガイドライン違反を防ぐため、以下の自動チェックを導入：

**VS Code設定ファイル (.vscode/settings.json)**:
```json
{
  "dart.lineLength": 120,
  "dart.showLintWarnings": true,
  "flutter.previewEmbeddedAndroidViews": true,
  "files.autoSave": "onFocusChange",
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "problems.decorations.enabled": true
}
```

**分析オプション強化 (analysis_options.yaml)**:
```yaml
analyzer:
  errors:
    avoid_print: error  # print文をエラーレベルに昇格
    unused_local_variable: error
    
linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
```

#### 3. 推奨代替手段（強制）

**レベル1: 基本デバッグ**（必須）:
```dart
// ✅ 基本的なデバッグ出力（必須）
if (kDebugMode) {
  debugPrint('デバッグ情報');
}
```

**レベル2: 構造化ログ**（推奨）:
```dart
// ✅ エラーレベル別ログ（推奨）
import 'package:your_app/core/utils/debug_logger.dart';

DebugLogger.info('処理完了');
DebugLogger.warning('警告発生');
DebugLogger.error('エラー発生', error, stackTrace);
```

**レベル3: Copilot連携ログ**（最推奨）:
```dart
// ✅ Copilotが自動監視可能（最推奨）
import 'package:your_app/core/utils/copilot_debug_bridge.dart';

CopilotDebugBridge.setState('current_status', 'processing');
CopilotDebugBridge.reportError('AudioService', 'ファイル読み込み失敗');
CopilotDebugBridge.reportPerformance('pitch_detection', duration);
```

### 🔧 **ツールスクリプトでの例外**

開発ツール（`tools/`ディレクトリ）では、以下の条件下でprint文を許可：

1. **スクリプト実行時の進捗表示**
2. **一回限りの分析結果出力**
3. **手動実行が前提の診断ツール**

```dart
// tools/scripts/ 内では許可
void main() {
  print('🔍 WAVファイル検証開始...');
  // 処理...
  print('✅ 検証完了');
}
```

## コードクリーン化

### 未使用変数の削除

```dart
// ❌ 避けるべき実装
final dataSize = view.getUint32(40, Endian.little); // 使用されていない

// ✅ 推奨実装（使用する場合）
final dataSize = view.getUint32(40, Endian.little);
validateDataSize(dataSize);

// ✅ 推奨実装（不要な場合）
// final dataSize = view.getUint32(40, Endian.little); // 削除
```

### const宣言の徹底

```dart
// ❌ 避けるべき実装
final EdgeInsets padding = EdgeInsets.all(8.0);

// ✅ 推奨実装
const EdgeInsets padding = EdgeInsets.all(8.0);
```

## 音声処理パフォーマンス

### リアルタイム処理
- 処理時間: 100ms以下を目標
- メモリ使用量: 最小限に抑制
- ガベージコレクション頻度: 削減

### キャッシュ戦略
- 頻繁にアクセスされるピッチデータのキャッシュ
- メモリ効率的なデータ構造の使用

## エラーハンドリング

### 音声ファイル関連エラー
```dart
try {
  final audioData = await loadAudioFile(path);
} on AudioException catch (e, stackTrace) {
  DebugLogger.error('音声ファイル読み込み失敗', e, stackTrace);
  CopilotDebugBridge.reportError('AudioLoader', e.message, 
    context: {'file_path': path});
  // ユーザー向け適切なエラーメッセージ表示
}
```

## テスト戦略

### 音声処理テスト
- ユニットテスト: 個別機能の検証
- 統合テスト: 音声処理パイプライン全体
- パフォーマンステスト: リアルタイム性能検証

## まとめ

このガイドラインに従うことで：
- **開発効率向上**: Problemsパネルの警告削減
- **保守性向上**: 一貫したログ戦略
- **パフォーマンス向上**: 最適化されたデバッグ手法
- **Copilot連携**: 効率的なトラブルシューティング
