# 🎯 ログ使用ガイドライン

## 📋 基本方針

**新規開発では必ずILoggerインターフェースを使用**

### ✅ **推奨パターン（新規コード）**

```dart
// 1. 依存性注入パターン
class MyService {
  final ILogger _logger;
  MyService(this._logger);
  
  void someMethod() {
    _logger.info('処理開始');
  }
}

// 2. Service Locator パターン
class MyWidget extends StatefulWidget {
  late final ILogger _logger;
  
  @override
  void initState() {
    super.initState();
    _logger = ServiceLocator().getService<ILogger>();
  }
}
```

### ⚠️ **レガシーパターン（既存コードのみ）**

```dart
// Core層・Infrastructure層でのみ許可
DebugLogger.error('エラーメッセージ');
```

---

## 🚫 **禁止事項**

### **❌ Presentation層・Application層での直接使用**

```dart
// 絶対に使用禁止！
class KaraokePage extends StatefulWidget {
  void someMethod() {
    DebugLogger.info('これは禁止'); // ❌
  }
}
```

### **❌ 新規サービスクラスでの静的呼び出し**

```dart
// 新規作成時は禁止
class NewAnalysisService {
  void analyze() {
    DebugLogger.info('分析開始'); // ❌
    // 正しくは：
    // _logger.info('分析開始'); // ✅
  }
}
```

---

## 🔍 **コードレビュー チェックポイント**

### **1. レイヤー別チェック**

- **Presentation層**: `DebugLogger.`の直接使用を検出したら指摘
- **Application層**: 同上
- **Core層**: 既存コードは許可、新規は要検討
- **Infrastructure層**: 段階移行計画に従って判断

### **2. 新規ファイルチェック**

```bash
# PRレビュー時のチェックコマンド
grep -r "DebugLogger\." lib/presentation/ lib/application/
# 検出された場合は修正要求
```

### **3. 推奨修正パターン**

**修正前:**
```dart
DebugLogger.info('メッセージ');
```

**修正後:**
```dart
// 依存性注入
final ILogger _logger = ServiceLocator().getService<ILogger>();
_logger.info('メッセージ');
```

---

## 🚀 **段階移行スケジュール**

### **Phase 1: 基盤完了** ✅
- ILoggerインターフェース定義
- EnhancedDebugLogger実装
- Service Locator対応

### **Phase 2: Application層移行** ✅
- Provider類の依存性注入対応
- 主要ページでの実装

### **Phase 3: 全体統一**（将来計画）
- Core層の段階移行
- Infrastructure層の段階移行
- DebugLogger完全廃止

---

## ⚡ **クイックリファレンス**

### **新規開発時のテンプレート**

```dart
// Service/Provider クラス
class MyNewService {
  final ILogger _logger;
  
  MyNewService({ILogger? logger}) 
    : _logger = logger ?? ServiceLocator().getService<ILogger>();
    
  void doSomething() {
    _logger.info('処理開始');
    try {
      // ビジネスロジック
      _logger.success('処理完了');
    } catch (e) {
      _logger.error('処理エラー', e);
    }
  }
}

// Widget クラス
class MyNewWidget extends StatefulWidget {
  late final ILogger _logger;
  
  @override
  void initState() {
    super.initState();
    _logger = ServiceLocator().getService<ILogger>();
  }
  
  void _handleAction() {
    _logger.debug('アクション実行');
  }
}
```

### **既存コード修正時のパターン**

```dart
// 修正前（Presentation層）
class ExistingPage extends StatefulWidget {
  void _method() {
    DebugLogger.info('情報'); // ❌
  }
}

// 修正後
class ExistingPage extends StatefulWidget {
  late final ILogger _logger;
  
  @override
  void initState() {
    super.initState();
    _logger = ServiceLocator().getService<ILogger>();
  }
  
  void _method() {
    _logger.info('情報'); // ✅
  }
}
```
