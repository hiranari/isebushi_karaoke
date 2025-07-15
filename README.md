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

## 現在の実装状況

### ✅ 実装済み機能
- 曲選択画面（song.jsonからの動的読み込み）
- リアルタイム録音・ピッチ検出
- 音源再生機能
- 基本的なスコアリング（30Hz以内の一致判定）

### 🔧 現在の制限事項
- 基準ピッチデータは手動で作成・配置が必要
- スコアリングロジックが単純（一致/不一致の二値判定）
- ピッチ比較の精度が限定的

## 今後の改善予定

### 🎯 Phase 1: 自動ピッチ検出機能
**目標**: assetsに格納されているMP3ファイルから自動でピッチ検出を行う

- **背景**: 現在は基準となるピッチデータを手動で作成・JSONファイルとして配置する必要がある
- **改善内容**:
  - MP3ファイルをPCMデータに変換する機能の実装
  - `pitch_detector_dart`を使用した楽曲全体のピッチ解析
  - 検出結果の自動保存・キャッシュ機能
- **技術的課題**: MP3デコード、メモリ効率的な解析処理
- **期待効果**: 新しい楽曲追加時の手間削減、データ精度向上

### 🎯 Phase 2: 高精度ピッチ比較システム
**目標**: 基準ピッチとカラオケ結果の詳細比較機能を実装

- **背景**: 現在の比較ロジックは単純な一致/不一致判定のみ
- **改善内容**:
  - 時間軸を考慮したピッチ同期機能
  - 音程のズレ量（セント単位）での詳細解析
  - 音程の安定性・ビブラートの検出
  - 音程変化のタイミング精度評価
- **技術的課題**: リアルタイム処理の最適化、時間同期アルゴリズム
- **期待効果**: より正確で公平な評価システムの実現

### 🎯 Phase 3: 総合スコアリング・フィードバックシステム ✅ **実装完了**
**目標**: 多角的な評価指標による詳細スコアリングとユーザーフィードバック

- **改善内容**:
  - ✅ **音程精度スコア**: ピッチの正確性評価（70%）
  - ✅ **安定性スコア**: 音程の安定性評価（20%）  
  - ✅ **タイミングスコア**: 音程変化のタイミング評価（10%）
  - ✅ 段階的UI表示（総合スコア → 詳細分析 → 改善提案）
  - ✅ 歌唱後の詳細分析結果表示
  - ✅ 改善ポイントの具体的提案機能
- **技術的実装**: 
  - ✅ UI/UXの分離設計、Provider状態管理
  - ✅ 単一責任原則に基づくサービス分離
  - ✅ 高いテスト容易性とパフォーマンス最適化
- **期待効果**: ユーザーの歌唱技術向上支援、アプリの教育的価値向上

## アーキテクチャ原則

### 🏗️ Phase 3で確立された設計原則

**すべての今後の機能開発と既存コードのリファクタリングは、以下の原則に従う必要があります：**

#### 1. 単一責任原則 (Single Responsibility Principle)
- 各クラス・サービスは1つの責任のみを持つ
- 例：`ScoringService`（スコア計算のみ）、`AnalysisService`（分析のみ）、`FeedbackService`（フィードバック生成のみ）

#### 2. 関心の分離 (Separation of Concerns)
- UIロジックとビジネスロジックの完全分離
- データモデル、サービス、プロバイダー、ウィジェットの明確な分離
- 例：`SongResultWidget`はUIのみ、`SongResultProvider`は状態管理のみ

#### 3. テスト容易性 (Testability)
- 純粋関数の優先使用
- 依存性注入の活用
- モックしやすいインターフェース設計
- 例：`ScoringService`の静的メソッドは副作用なし

#### 4. 拡張性 (Extensibility)
- 新機能追加時の既存コード変更を最小化
- オープン・クローズド原則の適用
- プラグイン可能な設計
- 例：新しい評価指標の追加が容易な設計

### 📋 開発ロードマップ
1. **Phase 1** (予定期間: 2-3週間) - MP3自動解析機能
2. **Phase 2** (予定期間: 3-4週間) - 高精度比較システム
3. **Phase 3** (予定期間: 4-5週間) - 総合評価システム

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## 参考資料

- [Flutter Documentation](https://docs.flutter.dev/)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [record Package](https://pub.dev/packages/record)
- [pitch_detector_dart Package](https://pub.dev/packages/pitch_detector_dart)
