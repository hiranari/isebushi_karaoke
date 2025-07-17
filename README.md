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
- `pitch_detector_dart`: ピッチ（音程）解析 (v0.0.7)
- `permission_handler`: デバイス権限管理
- `provider`: 状態管理（Phase 3で追加）
- `path_provider`: ファイルパス管理（Phase 1で追加）

### 開発・UI関連
- `flutter_launcher_icons`: アプリアイコン生成
- `flutter_native_splash`: スプラッシュ画面生成

## プロジェクト構成

```
lib/
├── main.dart                    # アプリエントリーポイント・ルーティング
├── song_select_page.dart        # 曲選択画面
├── pages/
│   ├── karaoke_page.dart        # カラオケメイン画面（Phase 3アーキテクチャ）
│   └── karaoke_page_legacy.dart # レガシー実装
├── models/
│   ├── song_result.dart         # 歌唱結果データモデル
│   ├── comprehensive_score.dart # 包括的スコアモデル
│   ├── improvement_suggestion.dart # 改善提案モデル
│   ├── pitch_comparison_result.dart # ピッチ比較結果
│   └── audio_analysis_result.dart   # 音声解析結果
├── services/
│   ├── scoring_service.dart           # スコアリングロジック
│   ├── pitch_detection_service.dart   # ピッチ検出サービス
│   ├── pitch_comparison_service.dart  # ピッチ比較サービス
│   ├── analysis_service.dart          # 詳細分析サービス
│   ├── improvement_suggestion_service.dart # 改善提案生成
│   ├── feedback_service.dart          # フィードバック生成
│   ├── audio_processing_service.dart  # 音声処理サービス
│   ├── cache_service.dart             # キャッシュ管理
│   └── karaoke_session_notifier.dart  # セッション通知
├── providers/
│   ├── karaoke_session_provider.dart  # カラオケセッション状態管理
│   └── song_result_provider.dart      # 歌唱結果状態管理
└── widgets/
    ├── progressive_score_display.dart      # プログレッシブスコア表示
    ├── realtime_pitch_visualizer.dart     # リアルタイムピッチ可視化
    ├── overall_score_widget.dart          # 総合スコア表示
    ├── detailed_analysis_widget.dart      # 詳細分析表示
    ├── improvement_suggestions_widget.dart # 改善提案表示
    └── song_result_widget.dart            # 歌唱結果表示

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
- **Flutter SDK**: 3.8.0以上

### 主要クラス
- `MyApp`: アプリケーションクラス・ルーティング定義
- `SongSelectPage`: 楽曲選択画面
- `KaraokePage`: カラオケメイン画面（Phase 3アーキテクチャ）
- `KaraokeSessionProvider`: セッション状態管理
- `ScoringService`: スコアリングロジック
- `PitchDetectionService`: ピッチ検出処理

### 開発環境セットアップ
1. Flutter SDKのインストール
2. 依存関係の解決: `flutter pub get`
3. 問題解決の実行: `flutter analyze`
4. アプリの実行: `flutter run`

### トラブルシューティング
#### コンパイルエラーが発生した場合
```bash
# 依存関係の再取得
flutter pub get

# キャッシュクリア
flutter clean

# 再実行
flutter run
```

#### パッケージ互換性の問題
- `pitch_detector_dart`は現在v0.0.7を使用
- 一部のAPIが変更されているため、カスタム実装で対応

## 現在の実装状況

### ✅ 実装済み機能
- 曲選択画面（song.jsonからの動的読み込み）
- リアルタイム録音・ピッチ検出
- 音源再生機能
- 基本的なスコアリング（30Hz以内の一致判定）

### 🔧 現在の制限事項・既知の問題
- Phase 3のアーキテクチャ移行により、一部のAPIの不整合が発生中
- リアルタイムピッチ検出機能が一時的に簡略化されている
- 一部のテストケースでモデル定義の更新が必要
- `pitch_detector_dart`パッケージのAPIが変更されており、互換性調整が必要

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

### 🎯 Phase 3: 総合スコアリング・フィードバックシステム (🔧 移行中)
**目標**: 多角的な評価指標による詳細スコアリングとユーザーフィードバック

- **改善内容**:
  - ✅ **音程精度スコア**: ピッチの正確性評価（70%）
  - ✅ **安定性スコア**: 音程の安定性評価（20%）
  - ✅ **タイミングスコア**: 音程変化のタイミング評価（10%）
  - 🔧 リアルタイムでの視覚的フィードバック（音程グラフ表示）
  - ✅ 歌唱後の詳細分析結果表示（プログレッシブ表示）
  - 🔧 改善ポイントの具体的提案機能
  - ✅ 単一責任・関心の分離に基づく設計
  - ✅ Provider パターンによる状態管理
  - ✅ UI とロジックの分離
- **技術的課題**: 🔧 API整合性の調整、パフォーマンス最適化
- **期待効果**: ✅ ユーザーの歌唱技術向上支援、アプリの教育的価値向上

### 📋 開発ロードマップ
1. **Phase 1** ✅ (完了) - MP3自動解析機能
2. **Phase 2** ✅ (完了) - 高精度比較システム
3. **Phase 3** 🔧 (移行中) - 総合評価システム
   - アーキテクチャ設計: ✅ 完了
   - コア機能実装: ✅ 完了
   - API整合性調整: 🔧 進行中
   - テスト整備: 🔧 進行中

## Phase 3 新機能

### 🏆 多角的スコアリングシステム
- **音程精度 (70%重み)**: セント単位での精密な音程分析
- **安定性 (20%重み)**: ビブラートや音程の揺れを評価
- **タイミング (10%重み)**: 基準との同期精度を評価
- **総合評価**: S～Fランクでの分かりやすいグレード表示

### 📊 プログレッシブUI表示
1. **総合スコア表示**: 最初にトータルスコアとグレードのみ表示
2. **詳細分析表示**: タップで各要素の内訳とグラフを表示
3. **アドバイス表示**: さらにタップで具体的な改善提案を表示

### 🎨 リアルタイム視覚化
- **ピッチグラフ**: 基準ピッチと録音ピッチをリアルタイム表示
- **現在位置インジケーター**: 録音中の現在ピッチをハイライト
- **色分け表示**: 精度に応じた色分けで直感的な理解をサポート

### 🔧 改善されたアーキテクチャ
- **単一責任の原則**: 各クラスが明確な責任を持つ設計
- **関心の分離**: UI、ビジネスロジック、データ管理の完全分離
- **状態管理**: Provider パターンによる効率的な状態管理
- **テスタビリティ**: 各コンポーネントの独立性によるテスト容易性

## 現在の開発状況

### ✅ 完了済み
- 新しいアーキテクチャ設計（Phase 3）
- コアサービスクラスの実装
- 状態管理システム（Provider）
- プログレッシブUI表示システム
- データモデルの設計

### 🔧 進行中・調整が必要な項目
- API整合性の調整（モデル間の不整合解消）
- `pitch_detector_dart`パッケージの互換性対応
- レガシーコードの完全移行
- テストケースの更新
- リアルタイムピッチ検出の再実装

### 🎯 次のステップ
1. API整合性の完全修正
2. リアルタイムピッチ検出機能の復旧
3. 統合テストの実行と修正
4. パフォーマンスの最適化
5. ドキュメントの最終更新
- **タイミング (10%重み)**: 基準との同期精度を評価
- **総合評価**: S～Fランクでの分かりやすいグレード表示

### 📊 プログレッシブUI表示
1. **総合スコア表示**: 最初にトータルスコアとグレードのみ表示
2. **詳細分析表示**: タップで各要素の内訳とグラフを表示
3. **アドバイス表示**: さらにタップで具体的な改善提案を表示

### 🎨 リアルタイム視覚化
- **ピッチグラフ**: 基準ピッチと録音ピッチをリアルタイム表示
- **現在位置インジケーター**: 録音中の現在ピッチをハイライト
- **色分け表示**: 精度に応じた色分けで直感的な理解をサポート

### 🔧 改善されたアーキテクチャ
- **単一責任の原則**: 各クラスが明確な責任を持つ設計
- **関心の分離**: UI、ビジネスロジック、データ管理の完全分離
- **状態管理**: Provider パターンによる効率的な状態管理
- **テスタビリティ**: 各コンポーネントの独立性によるテスト容易性

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## 参考資料

- [Flutter Documentation](https://docs.flutter.dev/)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [record Package](https://pub.dev/packages/record)
- [pitch_detector_dart Package](https://pub.dev/packages/pitch_detector_dart)
