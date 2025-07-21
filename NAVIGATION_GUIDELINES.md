# 画面遷移・戻る動作ガイドライン

## 基本ルール

### 1. 戻る動作の原則
- **戻る場合は一つ前の画面に戻る**: システムバック、横フリック、AppBarの戻るボタン
- **アプリ終了は最初の画面でのみ**: 楽曲選択画面（ルート画面）でのみアプリ終了を許可

### 2. 画面構成
```
楽曲選択画面 (/) ←→ カラオケ画面 (/karaoke)
     ↓
   アプリ終了
```

## 実装詳細

### 1. 楽曲選択画面 (`SongSelectPage`)

#### 遷移方法
```dart
// ✅ 正しい実装
Navigator.pushNamed(context, '/karaoke', arguments: song);

// ❌ 避けるべき実装  
Navigator.pushReplacementNamed(context, '/karaoke', arguments: song);
```

#### 戻る動作制御
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    
    // アプリ終了確認ダイアログを表示
    final shouldExit = await _showAppExitConfirmation();
    if (shouldExit) {
      Navigator.of(context).pop(); // アプリ終了
    }
  },
  child: Scaffold(/* ... */),
)
```

### 2. カラオケ画面 (`KaraokePage`)

#### 戻る動作制御
```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    
    final sessionProvider = context.read<KaraokeSessionProvider>();
    
    // 録音中の場合は確認ダイアログを表示
    if (sessionProvider.isRecording) {
      final shouldExit = await _showExitConfirmation();
      if (shouldExit && mounted) {
        Navigator.of(context).pop(); // 楽曲選択画面に戻る
      }
    } else {
      // 録音中でない場合は直接戻る
      if (mounted) {
        Navigator.of(context).pop(); // 楽曲選択画面に戻る
      }
    }
  },
  child: Scaffold(/* ... */),
)
```

## 確認ダイアログ

### 1. アプリ終了確認（楽曲選択画面）
```dart
Future<bool> _showAppExitConfirmation() async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('アプリを終了しますか？'),
        content: const Text('伊勢節カラオケアプリを終了してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('終了'),
          ),
        ],
      );
    },
  ) ?? false;
}
```

### 2. 録音中の戻る確認（カラオケ画面）
```dart
Future<bool> _showExitConfirmation() async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('録音中です'),
        content: const Text('録音を停止して画面を戻りますか？\n録音データは失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('戻る'),
          ),
        ],
      );
    },
  ) ?? false;
}
```

## 動作仕様

### 対応プラットフォーム
- **iOS**: 左端からの右スワイプジェスチャー
- **Android**: システムバックジェスチャー（スワイプ/ボタン）
- **共通**: AppBarの戻るボタン

### 動作フロー

#### 楽曲選択画面での戻る操作
1. 戻る操作を検知
2. アプリ終了確認ダイアログを表示
3. 「終了」選択 → アプリ終了
4. 「キャンセル」選択 → 画面に留まる

#### カラオケ画面での戻る操作
1. 戻る操作を検知
2. 録音中かどうかを判定
3. **録音中の場合**:
   - 録音停止確認ダイアログを表示
   - 「戻る」選択 → 楽曲選択画面に戻る
   - 「キャンセル」選択 → カラオケ画面に留まる
4. **録音中でない場合**:
   - 直接楽曲選択画面に戻る

## 注意事項

### 1. BuildContext の非同期使用
戻る処理でダイアログ表示後は `mounted` チェックを必須とする
```dart
if (shouldExit && mounted) {
  Navigator.of(context).pop();
}
```

### 2. PopScope vs WillPopScope
- Flutter 3.12+ では `PopScope` を使用
- それ以前のバージョンでは `WillPopScope` を使用

### 3. テスト対象
- 各画面での戻る動作
- 確認ダイアログの表示と選択
- 録音状態による分岐処理

## トラブルシューティング

### よくある問題

1. **戻る操作でアプリが終了してしまう**
   - `Navigator.pushReplacementNamed` を使用していないか確認
   - `PopScope` の実装が正しいか確認

2. **ダイアログが表示されない**
   - `barrierDismissible: false` が設定されているか確認
   - `mounted` チェックが適切に行われているか確認

3. **録音中の状態判定が正しく動作しない**
   - `Provider` の状態管理が正しく動作しているか確認
   - `context.read<KaraokeSessionProvider>()` が適切に呼ばれているか確認
