# 🎯 ログアーキテクチャ設計書

## 📋 概要

このドキュメントは、Isebushi Karaokeアプリケーションにおけるログアーキテクチャの統一設計方針を定義します。
Clean Architectureの原則に従い、ILoggerインターフェース中心の設計を採用しています。

---

## 🏗️ アーキテクチャ構成

### **レイヤー構成**

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation層                           │
│  ┌─────────────────┐ ┌─────────────────┐                   │
│  │  KaraokePage    │ │  ProviderClasses │                   │
│  │  (DI Pattern)   │ │  (DI Pattern)   │                   │
│  └─────────────────┘ └─────────────────┘                   │
│           │                      │                         │
│           ▼                      ▼                         │
├─────────────────────────────────────────────────────────────┤
│                   Application層                            │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Service Locator                            │ │
│  │    ILogger logger = getService<ILogger>()              │ │
│  └─────────────────────────────────────────────────────────┘ │
│                          │                                 │
│                          ▼                                 │
├─────────────────────────────────────────────────────────────┤
│                   Infrastructure層                          │
│  ┌─────────────────┐ ┌─────────────────┐                   │
│  │EnhancedDebugLogger│ │  ConsoleLogger  │                   │
│  │ (implements     │ │ (implements     │                   │
│  │   ILogger)      │ │   ILogger)      │                   │
│  └─────────────────┘ └─────────────────┘                   │
│           │                      │                         │
│           ▼                      ▼                         │
├─────────────────────────────────────────────────────────────┤
│                     Domain層                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │               ILogger Interface                         │ │
│  │  - debug(message)                                      │ │
│  │  - info(message)                                       │ │
│  │  - warning(message)                                    │ │
│  │  │  - error(message, error?, stackTrace?)               │ │
│  │  - success(message)                                    │ │
│  └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     Core/Utils層                           │
│  ┌─────────────────┐ ┌─────────────────┐                   │
│  │   DebugLogger   │ │  DebugFileLogger │                   │
│  │ (Static Legacy) │ │ (File Output)   │                   │
│  └─────────────────┘ └─────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎨 設計原則

### **1. Interface Segregation Principle**
- **ILoggerインターフェース**: 最小限の責任でログ出力を抽象化
- **単一責任**: 各実装クラスは特定の出力先に特化

### **2. Dependency Inversion Principle**
- **上位層**: ILoggerインターフェースに依存
- **下位層**: 具象実装クラスを提供
- **Service Locator**: 依存性注入のコンテナ役

### **3. Open/Closed Principle**
- **拡張性**: 新しいLogger実装の追加が容易
- **安定性**: 既存コードを変更せずに機能拡張

---

## 📚 実装クラス詳細

### **EnhancedDebugLogger** 🎯 **【推奨・標準】**

```dart
class EnhancedDebugLogger implements ILogger {
  // 既存DebugLoggerの視覚効果を活用
  // Service Locator経由での依存性注入サポート
  // テスト時のモック化対応
}
```

**特徴**:
- ✅ ILoggerインターフェース準拠
- ✅ 既存の視覚効果を保持（ボックス表示・絵文字）
- ✅ 依存性注入パターンサポート
- ✅ テスタビリティ対応

**用途**: **Application層・Presentation層での標準Logger**

### **ConsoleLogger** 🖥️ **【コンソール環境】**

```dart
class ConsoleLogger implements ILogger {
  // stdout/stderr使用
  // Flutter依存なし
}
```

**特徴**:
- ✅ ILoggerインターフェース準拠
- ✅ Flutter非依存で動作
- ✅ CLI ツール・テスト環境に最適

**用途**: **Tools層・テスト環境**

### **DebugLogger** 🔧 **【Legacy・段階的移行中】**

```dart
class DebugLogger {
  // 静的メソッド（既存互換性のため）
  static void info(String message) { ... }
  static void error(String message, [Object? error, StackTrace? stackTrace]) { ... }
}
```

**特徴**:
- ⚠️ 静的メソッド（Legacy パターン）
- ✅ 既存コードとの互換性維持
- 🔄 段階的移行対象

**用途**: **Core層・Infrastructure層（既存コード）**

### **DebugFileLogger** 📁 **【ファイル出力特化】**

```dart
class DebugFileLogger {
  // ファイル出力専用
  // セッション管理機能
}
```

**特徴**:
- 📁 ファイル出力に特化
- 🔄 セッション管理対応
- 🎯 デバッグ用途

**用途**: **デバッグセッション・ログファイル生成**

---

## 🚀 使用パターン

### **✅ 推奨パターン（依存性注入）**

```dart
// Application層・Presentation層
class KaraokeSessionProvider extends ChangeNotifier {
  late final ILogger _logger;
  
  KaraokeSessionProvider() {
    _logger = ServiceLocator().getService<ILogger>();
  }
  
  void someMethod() {
    _logger.info('処理開始');
    _logger.success('処理完了');
  }
}
```

### **✅ 許可パターン（静的メソッド）**

```dart
// Core層・Infrastructure層（段階的移行中）
class WavProcessor {
  static void processFile(String path) {
    DebugLogger.info('ファイル処理開始: $path');
    // 処理ロジック
    DebugLogger.success('ファイル処理完了');
  }
}
```

### **❌ 非推奨パターン**

```dart
// 型キャスト（削除済み）
DebugFileLogger() as ILogger  // ❌ 廃止

// 直接インスタンス化（Application層以上では禁止）
final logger = EnhancedDebugLogger();  // ❌ Service Locator使用必須
```

---

## 🔧 Service Locator設定

### **登録例**

```dart
void initialize() {
  // ログサービスを最初に登録
  registerService<ILogger>(EnhancedDebugLogger());
  
  // ログサービスを依存として注入
  final logger = getService<ILogger>();
  registerService<PitchDetectionService>(
    PitchDetectionService(logger: logger)
  );
}
```

### **取得例**

```dart
// Application層でのService Locator使用
final logger = ServiceLocator().getService<ILogger>();
logger.info('Service Locatorから取得');
```

---

## 🧪 テスト戦略

### **モック化対応**

```dart
// テスト用モックLogger
class MockLogger implements ILogger {
  final List<String> logs = [];
  
  @override
  void info(String message) {
    logs.add('INFO: $message');
  }
  
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add('ERROR: $message');
  }
}

// テスト実装
test('should log info messages', () {
  final mockLogger = MockLogger();
  ServiceLocator().registerService<ILogger>(mockLogger);
  
  final provider = KaraokeSessionProvider();
  provider.someMethod();
  
  expect(mockLogger.logs, contains('INFO: 処理開始'));
});
```

---

## 📈 移行ロードマップ

### **Phase 1: 基盤構築** ✅ **完了**
- [x] ILoggerインターフェース定義
- [x] EnhancedDebugLogger実装
- [x] Service Locator統合
- [x] ConsoleLogger success()メソッド追加

### **Phase 2: Application層移行** ✅ **完了**
- [x] KaraokeSessionProvider依存性注入化
- [x] SongResultProvider依存性注入化
- [x] karaoke_page.dart依存性注入化

### **Phase 3: 段階的展開** 🔄 **進行中**
- Core層・Infrastructure層は現状維持
- 新規コードはILogger準拠必須
- 既存コードは自然な更新タイミングで移行

### **Phase 4: 最終統一** 📋 **将来計画**
- 全静的メソッド呼び出しの依存性注入化
- DebugLogger静的メソッドの廃止検討
- 完全なILogger中心設計への移行

---

## ⚠️ 注意事項

### **互換性維持**
- 既存のDebugLogger静的メソッドは保持
- 段階的移行により既存機能への影響を最小化
- flutter analyze: **No issues found!** 維持必須

### **パフォーマンス考慮**
- Service Locator経由でのオーバーヘッドは最小限
- 静的メソッドと依存性注入の共存
- リリースビルドでのデバッグ出力自動抑制

### **開発体験**
- 既存の視覚効果（ボックス表示・絵文字）は完全保持
- デバッガビリティの向上
- ログレベルの一貫性確保

---

## 🎯 まとめ

### **達成された目標**
1. ✅ **ILoggerインターフェース中心の設計統一**
2. ✅ **Service Locatorによる依存性注入パターン確立**
3. ✅ **EnhancedDebugLoggerによる単一ログクラス化**
4. ✅ **既存コードとの互換性維持**
5. ✅ **テスタビリティとモック化対応**

### **設計品質**
- **Clean Architecture準拠**: ✅
- **SOLID原則適用**: ✅  
- **Flutter analyze**: ✅ **No issues found!**
- **既存機能保護**: ✅

### **今後の方針**
- 新規コード: **ILogger準拠必須**
- 既存コード: **段階的移行**
- 開発体験: **既存の視覚効果維持**

---

*最終更新: 2025年8月4日*  
*担当者: GitHub Copilot + 開発チーム*
