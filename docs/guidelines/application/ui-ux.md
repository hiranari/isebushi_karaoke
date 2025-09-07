# UI/UXガイドライン

## 目的

伊勢節カラオケアプリのユーザー体験を一貫性のある、直感的なものにするため、以下の目標を達成する：

- 明確で一貫性のあるUIデザイン
- ストレスのない操作性
- 効果的なフィードバック提供
- アクセシビリティの確保

## デザインシステム

### 1. カラーパレット

#### メインカラー
```dart
static const MaterialColor primarySwatch = MaterialColor(
  0xFF1E88E5, // メインカラー
  <int, Color>{
    50: Color(0xFFE3F2FD),
    100: Color(0xFFBBDEFB),
    200: Color(0xFF90CAF9),
    300: Color(0xFF64B5F6),
    400: Color(0xFF42A5F5),
    500: Color(0xFF1E88E5), // プライマリ
    600: Color(0xFF1976D2),
    700: Color(0xFF1565C0),
    800: Color(0xFF0D47A1),
    900: Color(0xFF0D47A1),
  },
);
```

#### アクセントカラー
- 正解時: `Color(0xFF4CAF50)` // 緑
- 不正解時: `Color(0xFFF44336)` // 赤
- 注意喚起: `Color(0xFFFFC107)` // 黄

#### テキストカラー
- プライマリ: `Color(0xFF212121)`
- セカンダリ: `Color(0xFF757575)`
- 無効時: `Color(0xFFBDBDBD)`

### 2. タイポグラフィ

#### フォントファミリー
```dart
static const TextTheme textTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  ),
  bodyLarge: TextStyle(
    fontSize: 16,
    letterSpacing: 0.15,
  ),
  labelLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  ),
);
```

#### 使用規則
- 歌詞表示: `displayLarge`
- スコア表示: `headlineMedium`
- 説明文: `bodyLarge`
- ボタンラベル: `labelLarge`

### 3. スペーシング

#### 基本単位
```dart
class Spacing {
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
```

#### パディング規則
- リスト項目: `EdgeInsets.symmetric(vertical: Spacing.s)`
- セクション間: `SizedBox(height: Spacing.xl)`
- コンテンツパディング: `EdgeInsets.all(Spacing.m)`

### 4. アニメーション

#### 持続時間
```dart
class AnimationDuration {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 400);
}
```

#### イージング
```dart
class AnimationCurves {
  static const standard = Curves.easeInOut;
  static const emphasize = Curves.easeOutBack;
  static const decelerate = Curves.easeOutCubic;
}
```

## コンポーネントガイドライン

### 1. ボタン

#### プライマリーボタン
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(
      horizontal: Spacing.l,
      vertical: Spacing.m,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text('開始'),
  onPressed: () {},
)
```

#### アイコンボタン
```dart
IconButton(
  icon: Icon(Icons.mic),
  color: Colors.red,
  splashRadius: 24,
  tooltip: '録音開始',
  onPressed: () {},
)
```

### 2. スコア表示

#### 円形プログレス
```dart
CircularScoreIndicator(
  score: 85,
  size: 120,
  strokeWidth: 8,
  backgroundColor: Colors.grey[200],
  valueColor: primarySwatch,
  animationDuration: AnimationDuration.slow,
  curve: AnimationCurves.emphasize,
)
```

#### スコアテキスト
```dart
Text(
  '$score点',
  style: textTheme.displayLarge.copyWith(
    color: primarySwatch,
    fontWeight: FontWeight.bold,
  ),
)
```

### 3. ピッチビジュアライザー

#### リアルタイム表示
```dart
PitchVisualizer(
  data: pitchData,
  height: 200,
  lineColor: primarySwatch,
  backgroundColor: Colors.transparent,
  gridColor: Colors.grey[300],
  showGrid: true,
)
```

#### アニメーション設定
- 更新間隔: 50ms
- スムージング: 移動平均フィルター
- トランジション: `AnimationCurves.decelerate`

## インタラクションパターン

### 1. 録音フロー

#### 状態表示
1. 待機中: マイクアイコン（通常）
2. 録音準備中: マイクアイコン（点滅）
3. 録音中: 停止アイコン（赤色）
4. 処理中: プログレスインジケーター

#### フィードバック
- 録音開始時: 短いバイブレーション
- エラー時: エラー音とダイアログ
- 完了時: 成功音と視覚的フィードバック

### 2. スコアリング

#### リアルタイムフィードバック
- 音程一致: 緑色のハイライト
- 音程ずれ: 赤色のハイライト
- 無音区間: グレー表示

#### 結果表示
- スコアのアニメーション表示
- パフォーマンスグラフ
- 改善ポイントのハイライト

### 3. ナビゲーション

#### 遷移アニメーション
```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => NextPage(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: AnimationDuration.normal,
  ),
);
```

#### ジェスチャー
- 戻る: 左スワイプ
- 楽曲選択: タップ
- 録音キャンセル: 下スワイプ

## アクセシビリティ

### 1. 基本要件

#### コントラスト比
- テキスト: 最低4.5:1
- 大きなテキスト: 最低3:1
- アイコン: 最低3:1

#### タッチターゲット
- 最小サイズ: 48x48 logical pixels
- 間隔: 8 logical pixels以上

### 2. Semanticsラベル

```dart
Semantics(
  label: '録音を開始',
  hint: 'タップして歌唱を開始します',
  button: true,
  child: IconButton(
    icon: Icon(Icons.mic),
    onPressed: () {},
  ),
)
```

### 3. 視覚的フィードバック
- フォーカス表示
- エラー状態
- 選択状態
- 処理中の状態

## レスポンシブデザイン

### 1. レイアウトガイドライン

#### ブレークポイント
```dart
class BreakPoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

#### レイアウトグリッド
- モバイル: 4カラム
- タブレット: 8カラム
- デスクトップ: 12カラム

### 2. アダプティブUIパターン

#### 楽曲選択画面
```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < BreakPoints.mobile) {
      return SongListMobileView();
    } else if (constraints.maxWidth < BreakPoints.tablet) {
      return SongListTabletView();
    }
    return SongListDesktopView();
  },
)
```

#### カラオケ画面
- モバイル: 縦スタック
- タブレット: 2カラムレイアウト
- デスクトップ: 3カラムレイアウト

## エラー処理とフィードバック

### 1. エラーメッセージ

#### スタイルガイド
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(
      'エラー',
      style: textTheme.titleLarge.copyWith(color: Colors.red),
    ),
    content: Text(
      'マイクへのアクセスができません。\n設定からマイクの使用を許可してください。',
      style: textTheme.bodyLarge,
    ),
    actions: [
      TextButton(
        child: Text('設定を開く'),
        onPressed: () => openSettings(),
      ),
      TextButton(
        child: Text('キャンセル'),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ),
);
```

#### エラータイプ別デザイン
- 致命的エラー: 赤背景のダイアログ
- 警告: 黄色背景のスナックバー
- 情報: 青背景のトースト

### 2. ローディング表示

#### インジケーター
```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primarySwatch),
      ),
      SizedBox(height: Spacing.m),
      Text(
        '音声を解析中...',
        style: textTheme.bodyLarge,
      ),
    ],
  ),
)
```

#### スケルトンローディング
- 楽曲リスト
- スコア表示
- グラフ表示

## パフォーマンス最適化

### 1. アニメーション

#### メモリ効率
- `RepaintBoundary`の適切な使用
- アニメーション完了後のリソース解放
- キャッシュの適切な管理

#### フレームレート
- 60FPSの維持
- 重いアニメーションの最適化
- ジャンクの防止

### 2. レンダリング

#### ウィジェットの最適化
- `const`の適切な使用
- `ListView.builder`の使用
- 不要な再ビルドの防止

## 品質管理

### 1. UIテスト

#### 視覚的レグレッションテスト
- スクリーンショットテスト
- レイアウトテスト
- アニメーションテスト

#### インタラクションテスト
- タップ操作
- スワイプ操作
- 長押し操作

### 2. UXテスト

#### ユーザビリティテスト
- タスク完了時間
- エラー発生率
- ユーザー満足度

#### アクセシビリティテスト
- スクリーンリーダー
- キーボード操作
- 色覚異常シミュレーション

## まとめ

このガイドラインに従うことで、以下が実現できます：

1. 一貫性のあるUIデザイン
2. 直感的な操作性
3. 効果的なフィードバック
4. 高いアクセシビリティ
5. 優れたパフォーマンス
