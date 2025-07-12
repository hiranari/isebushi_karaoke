# 伊勢節カラオケアプリ

Flutter で開発された伊勢節のカラオケアプリです。録音機能とピッチ解析によるスコアリング機能を備えています。

## 機能

- 📱 **曲選択画面**: JSONファイルから動的に曲リストを読み込み
- 🎤 **録音機能**: マイクからリアルタイムで音声を録音
- 🎵 **音源再生**: 各楽曲の音源を再生
- 📊 **ピッチ解析**: リアルタイムでピッチ（音程）を検出・表示
- 🏆 **スコアリング**: 録音した音程と基準音程を比較してスコアを算出

## 使用技術

### メイン技術
- **Flutter**: クロスプラットフォーム開発フレームワーク
- **Dart**: プログラミング言語

### 主要パッケージ
- `just_audio`: 音源再生
- `record`: マイク録音
- `pitch_detector_dart`: ピッチ（音程）解析
- `permission_handler`: デバイス権限管理

### 開発・UI関連
- `flutter_launcher_icons`: アプリアイコン生成
- `flutter_native_splash`: スプラッシュ画面生成

## プロジェクト構成

```
lib/
├── main.dart              # アプリエントリーポイント・ルーティング
├── song_select_page.dart  # 曲選択画面
└── karaoke_page.dart      # カラオケメイン画面

assets/
├── data/
│   └── song.json          # 楽曲情報（タイトル、音源、ピッチデータ）
├── sounds/
│   ├── kiku.mp3          # 楽曲音源ファイル
│   └── dummy.mp3         # ダミー音源
├── pitch/
│   ├── kiku_pitches.json # 基準ピッチデータ
│   └── dummy_pitches.json# ダミーピッチデータ
├── icon/
│   └── icon.png          # アプリアイコン
└── splash/
    └── splash.png        # スプラッシュ画像
```

## セットアップ

### 前提条件
- Flutter SDK (3.x以上推奨)
- Android Studio / Xcode (各プラットフォーム開発用)

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone <repository-url>
   cd isebushi_karaoke
   ```

2. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

3. **アイコン・スプラッシュ画像の生成**
   ```bash
   flutter pub run flutter_launcher_icons:main
   flutter pub run flutter_native_splash:create
   ```

4. **アプリの実行**
   ```bash
   flutter run
   ```

## 楽曲データの追加

### 1. 音源ファイルの追加
`assets/sounds/` ディレクトリに MP3 ファイルを配置

### 2. ピッチデータの作成
楽曲の基準ピッチデータを JSON 形式で作成し、`assets/pitch/` に配置
```json
[120.0, 125.5, 130.2, 0.0, 128.7, 132.1, ...]
```

### 3. 楽曲リストの更新
`assets/data/song.json` に楽曲情報を追加
```json
[
  {
    "title": "楽曲名",
    "audioFile": "assets/sounds/song.mp3",
    "pitchFile": "assets/pitch/song_pitches.json"
  }
]
```

### 4. pubspec.yaml の更新
新しいアセットファイルを `pubspec.yaml` に登録

## 対応プラットフォーム

- ✅ **Android** (API 24+)
- ✅ **iOS** (iOS 12.0+)
- ❌ **Web** (録音機能制限のため非対応)

## 権限設定

### Android
`android/app/src/main/AndroidManifest.xml` に録音権限が設定済み
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### iOS
iOS の場合は自動で権限処理されます

## 開発者向け情報

### ビルド設定
- **最小 SDK**: Android API 24, iOS 12.0
- **NDK バージョン**: 27.0.12077973
- **Gradle**: 8.x系

### 主要クラス
- `MyApp`: アプリケーションクラス・ルーティング定義
- `SongSelectPage`: 楽曲選択画面
- `KaraokePage`: カラオケメイン画面・録音・解析処理

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## 参考資料

- [Flutter Documentation](https://docs.flutter.dev/)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [record Package](https://pub.dev/packages/record)
- [pitch_detector_dart Package](https://pub.dev/packages/pitch_detector_dart)
