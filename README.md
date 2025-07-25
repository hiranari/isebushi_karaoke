# 伊勢節カラオケアプリ

Flutter で開発された伊勢節のカラオケアプリです。録音機能とピッチ解析によるスコアリング機能を備えています。

## 機能

- 📱 **曲選択画面**: JSONファイルから動的に曲リストを読み込み
- 🎤 **録音機能**: マイクからリアルタイムで音声を録音
- 🎵 **音源再生**: 各楽曲の音源を再生
- 📊 **ピッチ解析**: 音源から自動的にピッチを抽出、リアルタイムでピッチ（音程）を検出・表示
- 🏆 **多角的スコアリング**: 音程精度・安定性・タイミングの3要素で100点満点評価、11段階グレード（S, A+, A, B+, B, C+, C, D+, D, F）

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
│   └── song.json          # 楽曲情報（タイトル、音源、歌手）
├── sounds/
│   ├── kiku.mp3          # 楽曲音源ファイル
│   └── dummy.mp3         # ダミー音源
├── icon/
│   └── icon.png          # アプリアイコン
└── splash/
    └── splash.png        # スプラッシュ画像
```

## セットアップ

### 前提条件
- **Flutter SDK** (3.8.0以上、3.24.x推奨)
- **Dart SDK** (Flutter SDKに含まれる)
- **Android Studio** または **VS Code** (IDE)
- **Android SDK** (Android開発用)
- **Xcode** (iOS開発用、macOSのみ)
- **Git** (バージョン管理)

### Flutter SDKのインストール

#### Windows
1. [Flutter公式サイト](https://docs.flutter.dev/get-started/install/windows)からFlutter SDKをダウンロード
2. ダウンロードしたZIPファイルを適当な場所（例：`C:\development`）に展開
3. システム環境変数のPATHに`C:\development\flutter\bin`を追加
4. コマンドプロンプトで`flutter --version`を実行して確認

#### macOS
```bash
# Homebrewを使用してインストール
brew install --cask flutter

# または手動インストール
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.5-stable.zip
unzip flutter_macos_3.24.5-stable.zip
export PATH="$PWD/flutter/bin:$PATH"
```

#### Linux
```bash
# snapを使用してインストール
sudo snap install flutter --classic

# または手動インストール
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PWD/flutter/bin:$PATH"
```

### 開発環境の設定

1. **Flutter doctor の実行**
   ```bash
   flutter doctor
   ```
   不足している依存関係やツールがあれば指示に従ってインストール

2. **Android Studioの設定** (Android開発用)
   - Android Studio をインストール
   - Android SDK の設定
   - AVD (Android Virtual Device) の作成

3. **VS Code の設定** (推奨)
   - VS Code をインストール
   - Flutter 拡張機能をインストール
   - Dart 拡張機能をインストール

### プロジェクトのセットアップ

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/hiranari/isebushi_karaoke.git
   cd isebushi_karaoke
   ```

2. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

3. **静的解析の実行**
   ```bash
   flutter analyze
   ```

4. **テストの実行**
   ```bash
   flutter test
   ```

5. **アイコン・スプラッシュ画像の生成**
   ```bash
   flutter pub run flutter_launcher_icons:main
   flutter pub run flutter_native_splash:create
   ```

6. **アプリのビルドと実行**
   ```bash
   # デバッグモードで実行
   flutter run

   # リリースモードで実行
   flutter run --release

   # 特定のデバイスで実行
   flutter devices  # 利用可能なデバイス一覧を表示
   flutter run -d <device-id>
   ```

### プラットフォーム別のビルド

#### Android APK の生成
```bash
# リリースAPKの生成
flutter build apk --release

# サイズ最適化版APKの生成
flutter build apk --split-per-abi
```

#### iOS アプリの生成 (macOSのみ)
```bash
# iOSシミュレーター用
flutter build ios --simulator

# 実機用
flutter build ios --release
```

## 楽曲データの追加

### 1. 音源ファイルの追加
`assets/sounds/` ディレクトリに MP3 ファイルを配置

### 2. 楽曲リストの更新
`assets/data/song.json` に楽曲情報を追加
```json
[
  {
    "title": "楽曲名",
    "audioFile": "assets/sounds/song.mp3",
    "singer": "歌手名（エンコード済み）"
  }
]
```

**注意**: ピッチデータは音源ファイルから自動的に抽出されるため、手動での作成は不要です。キャッシュ機能により2回目以降の起動は高速化されます。

### 3. pubspec.yaml の更新
新しいアセットファイルを `pubspec.yaml` に登録
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

## CI/CD パイプライン

このプロジェクトでは GitHub Actions を使用した自動化された CI/CD パイプラインを実装しています。

### 自動実行される処理

プルリクエストまたはメインブランチへのプッシュ時に以下が実行されます：

1. **環境セットアップ**
   - Ubuntu最新版での実行
   - Java 17のセットアップ
   - Flutter 3.24.5 (stable) のインストール

2. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

3. **静的解析**
   ```bash
   flutter analyze --fatal-infos
   ```

4. **テスト実行**
   ```bash
   flutter test --coverage
   ```

5. **カバレッジレポート** (オプション)
   - Codecovへのカバレッジ情報アップロード

### ワークフローファイル

CI設定は `.github/workflows/ci.yml` で管理されています。

### 失敗時の対応

いずれかのステップが失敗した場合：
- プルリクエストのマージが制限されます
- GitHub上でエラーの詳細を確認できます
- ローカルで同じコマンドを実行して問題を特定・修正してください

```bash
# ローカルでCIと同じチェックを実行
flutter pub get
flutter analyze --fatal-infos
flutter test
```

### ローカル検証スクリプト

CIと同じチェックをローカルで実行するためのスクリプトを用意しています：

```bash
# スクリプトの実行
./scripts/validate-ci.sh
```

このスクリプトはプッシュ前に実行することで、CIでの失敗を事前に防ぐことができます。

## 状態管理・UI分岐・Provider活用ルール

### 状態管理アーキテクチャ

このアプリケーションは **Provider パターン** を使用した状態管理を採用しています。以下のルールに従って開発してください。

#### 1. KaraokeSessionProvider の責務

**主要な責務:**
- 歌唱セッションのライフサイクル管理（準備→録音→分析→完了）
- リアルタイムピッチデータの管理
- 録音状態の管理
- 分析結果の管理
- UI状態の通知

**状態遷移フロー:**
```
ready → recording → analyzing → completed
  ↓         ↓           ↓
error ← error ← error
```

#### 2. リアルタイムピッチ検出の仕組み

**Provider での実装:**
```dart
// ピッチ値の更新（UI に自動反映）
void updateCurrentPitch(double? pitch) {
  _currentPitch = pitch;
  
  // 録音中の場合はピッチを記録
  if (_isRecording && pitch != null && pitch > 0) {
    _recordedPitches.add(pitch);
  }
  
  notifyListeners(); // UI に変更を通知
}
```

**UI での消費:**
```dart
Consumer<KaraokeSessionProvider>(
  builder: (context, sessionProvider, child) {
    return RealtimePitchVisualizer(
      currentPitch: sessionProvider.currentPitch,
      isRecording: sessionProvider.isRecording,
      // ... その他のプロパティ
    );
  },
)
```

#### 3. UI分岐のルール

**状態に応じた UI の切り替え:**
```dart
// セッション状態による分岐
switch (sessionProvider.state) {
  case KaraokeSessionState.ready:
    // 録音開始ボタンを有効化
    break;
  case KaraokeSessionState.recording:
    // 録音停止ボタンを表示、リアルタイムピッチを可視化
    break;
  case KaraokeSessionState.analyzing:
    // 分析中のローディング表示
    break;
  case KaraokeSessionState.completed:
    // 結果表示、スコア表示
    break;
  case KaraokeSessionState.error:
    // エラーメッセージ表示
    break;
}
```

**録音状態による分岐:**
```dart
// 録音状態による UI 制御
if (sessionProvider.isRecording) {
  // ピッチビジュアライザーをアクティブ表示
  // 録音停止ボタンを表示
} else {
  // 録音開始ボタンを表示
}
```

#### 4. Provider活用のベストプラクティス

**✅ 推奨:**
- `Consumer` または `context.watch()` を使用してリアクティブにUI更新
- 状態変更は必ず Provider のメソッドを通して実行
- `notifyListeners()` の呼び出しを忘れない
- 単一責任の原則に従い、Provider の責務を明確にする

**❌ 禁止:**
- Provider の private フィールドに直接アクセス
- UI コンポーネント内でビジネスロジックを実装
- `notifyListeners()` の不適切な呼び出し（過度な頻度など）
- 状態の直接変更（Provider のメソッドを経由しない）

#### 5. リアルタイム更新の実装パターン

**録音中のリアルタイム更新:**
```dart
// 定期的なピッチ更新
Timer.periodic(const Duration(milliseconds: 100), (timer) {
  if (sessionProvider.isRecording) {
    // ピッチ検出ロジック
    final detectedPitch = detectPitch();
    sessionProvider.updateCurrentPitch(detectedPitch);
  } else {
    timer.cancel();
  }
});
```

**UI での自動更新:**
```dart
// Consumer を使用した自動更新
Consumer<KaraokeSessionProvider>(
  builder: (context, provider, child) {
    return Text('現在のピッチ: ${provider.currentPitch?.toStringAsFixed(1) ?? "---"}Hz');
  },
)
```

#### 6. エラーハンドリングパターン

**Provider でのエラー処理:**
```dart
void setError(String message) {
  _errorMessage = message;
  _state = KaraokeSessionState.error;
  notifyListeners();
}
```

**UI でのエラー表示:**
```dart
if (sessionProvider.state == KaraokeSessionState.error) {
  return ErrorWidget(message: sessionProvider.errorMessage);
}
```

### 開発者向けガイドライン

1. **新しい状態の追加**: `KaraokeSessionState` enum に追加し、適切な状態遷移を実装
2. **新しいUI状態の追加**: Provider にプロパティを追加し、getter と setter を提供
3. **リアルタイム機能の追加**: `updateCurrentPitch()` パターンを参考に実装
4. **テスト**: 状態遷移とUI更新の両方をテストすることを推奨

## 開発者向け情報
### ビルド設定
- **最小 SDK**: Android API 24, iOS 12.0
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

1. **Flutter SDKのインストール** (上記の「Flutter SDKのインストール」セクションを参照)

2. **開発環境の確認**
   ```bash
   flutter doctor -v
   ```

3. **依存関係の解決**
   ```bash
   flutter pub get
   ```

4. **静的解析の実行**
   ```bash
   flutter analyze --fatal-infos
   ```

5. **テストの実行**
   ```bash
   # 全てのテストを実行
   flutter test

   # カバレッジ付きでテストを実行
   flutter test --coverage

   # 特定のテストファイルのみ実行
      flutter test test/scoring_service_test.dart
   ```

### コーディングガイドライン

#### 変数名命名規則
- **省略禁止**: 変数名は省略せず、意味が明確な完全な名前を使用
- **可読性優先**: 長くても分かりやすい名前を付ける
- **例**: 
  - ✅ `fundamentalFrequencies` (基本周波数)
  - ✅ `frequencyIndex` (周波数インデックス)
  - ✅ `averageError` (平均誤差)
  - ❌ `fundamentalFreqs`, `freqIndex`, `avgErr`

#### 品質管理
- **ゼロ警告原則**: `flutter analyze` で警告・エラーを残さない
- **テスト完走**: `flutter test` で全テストが通ることを確認
- **詳細**: `CONTRIBUTING.md` を参照

## 機能概要
   ```

6. **アプリの実行**
   ```bash
   # デバッグモードで実行
   flutter run

   # ホットリロードの使用
   # アプリ実行中に 'r' キーで即座に変更を反映
   ```

### コマンドリファレンス

#### 基本コマンド
```bash
# プロジェクトの状態確認
flutter doctor

# 利用可能なデバイス確認
flutter devices

# 依存関係の更新
flutter pub upgrade

# キャッシュのクリア
flutter clean

# パッケージの追加
flutter pub add <package_name>

# パッケージの削除
flutter pub remove <package_name>
```

#### ビルドコマンド
```bash
# Android APK（リリース版）
flutter build apk --release

# Android Bundle（Google Play用）
flutter build appbundle --release

# iOS（macOSのみ）
flutter build ios --release

# Web版
flutter build web
```

#### 開発用コマンド
```bash
# Widgetテスト用のゴールデンファイル更新
flutter test --update-goldens

# 依存関係の依存グラフ確認
flutter pub deps

# アプリサイズの分析
flutter build apk --analyze-size
```

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
- 音源からの自動ピッチ抽出・キャッシュ機能
- リアルタイム録音・ピッチ検出
- 音源再生機能
- 多角的スコアリングシステム（音程精度70%・安定性20%・タイミング10%）
- 100点満点での統一スコア表示
- 11段階詳細グレード評価（S, A+, A, B+, B, C+, C, D+, D, F）
- プログレッシブUI表示（段階的な結果表示）

### 🔧 現在の制限事項・既知の問題
- Phase 3のアーキテクチャ移行により、一部のAPIの不整合が発生中
- リアルタイムピッチ検出機能が一時的に簡略化されている
- 一部のテストケースでモデル定義の更新が必要
- `pitch_detector_dart`パッケージのAPIが変更されており、互換性調整が必要

### 🎯 解決済みの課題
- ✅ スコアリング極値問題の修正（0点または100点のみになる問題）
- ✅ 各スコア要素の100点満点統一
- ✅ 11段階グレード評価システムの実装
- ✅ ピッチファイル管理の廃止（完全自動抽出に移行）

## 今後の改善予定

### 🎯 Phase 1: 自動ピッチ検出機能 ✅ (完了)
**目標**: assetsに格納されているMP3ファイルから自動でピッチ検出を行う

- **改善内容**:
  - ✅ MP3ファイルをPCMデータに変換する機能の実装
  - ✅ `pitch_detector_dart`を使用した楽曲全体のピッチ解析
  - ✅ 検出結果の自動保存・キャッシュ機能
  - ✅ 手動ピッチファイル管理の廃止
- **期待効果**: ✅ 新しい楽曲追加時の手間削減、データ精度向上

### 🎯 Phase 2: 高精度ピッチ比較システム ✅ (完了)
**目標**: 基準ピッチとカラオケ結果の詳細比較機能を実装

- **改善内容**:
  - ✅ 時間軸を考慮したピッチ同期機能
  - ✅ 音程のズレ量（セント単位）での詳細解析
  - ✅ 音程の安定性・ビブラートの検出
  - ✅ 音程変化のタイミング精度評価
- **期待効果**: ✅ より正確で公平な評価システムの実現

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
1. **Phase 1** ✅ (完了) - MP3自動解析機能・ピッチファイル管理廃止
2. **Phase 2** ✅ (完了) - 高精度比較システム・多角的スコアリング
3. **Phase 3** 🔧 (移行中) - 総合評価システム・アーキテクチャ改善
   - アーキテクチャ設計: ✅ 完了
   - コア機能実装: ✅ 完了
   - スコアリングシステム: ✅ 完了
   - API整合性調整: 🔧 進行中
   - テスト整備: 🔧 進行中

## Phase 3 新機能

### 🏆 多角的スコアリングシステム
- **音程精度 (70%重み)**: セント単位での精密な音程分析、100点満点評価
- **安定性 (20%重み)**: ビブラートや音程の揺れを評価、100点満点評価
- **タイミング (10%重み)**: 基準との同期精度を評価、100点満点評価
- **総合評価**: 11段階詳細グレード（S, A+, A, B+, B, C+, C, D+, D, F）
- **スコア閾値**: S(95+), A+(90-94), A(85-89), B+(80-84), B(75-79), C+(70-74), C(65-69), D+(60-64), D(55-59), F(<55)

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
- ✅ 新しいアーキテクチャ設計（Phase 3）
- ✅ コアサービスクラスの実装
- ✅ 状態管理システム（Provider）
- ✅ プログレッシブUI表示システム
- ✅ データモデルの設計
- ✅ 多角的スコアリングシステム（100点満点統一）
- ✅ 11段階グレード評価システム
- ✅ 音源からの自動ピッチ抽出とキャッシュ
- ✅ ピッチファイル管理の完全廃止
- ✅ スコアリング極値問題の修正

### 🔧 進行中・調整が必要な項目
- API整合性の調整（モデル間の不整合解消）
- `pitch_detector_dart`パッケージの互換性対応
- レガシーコードの完全移行
- テストケースの更新
- リアルタイムピッチ検出の再実装

### 🎯 次のステップ
1. ✅ API整合性の完全修正
2. ✅ スコアリングシステムの改善（100点満点統一・11段階グレード）
3. ✅ ピッチファイル管理の廃止
4. 🔧 リアルタイムピッチ検出機能の復旧
5. 🔧 統合テストの実行と修正
6. 🔧 パフォーマンスの最適化
7. 🔧 ドキュメントの最終更新
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

## 最近の改善実績

### 🎯 スコアリングシステムの大幅改善（2025年7月）
- **課題**: 音程精度とタイミングスコアが0点または100点の極値のみ返す問題
- **解決**: 
  - 音程精度: 80基準点 + 25偏差ボーナス + ペナルティ方式に変更
  - タイミング: 60基準点 + 25遅延スコア + 15バランスボーナス + ペナルティ方式に変更
  - 全スコア要素を100点満点に統一
- **効果**: 現実的なスコア分布と詳細なフィードバックを実現

### 🎯 グレード評価システムの詳細化
- **11段階詳細評価**: S, A+, A, B+, B, C+, C, D+, D, F
- **明確な閾値設定**: 各グレードに5点刻みの明確な基準を設定
- **ユーザビリティ向上**: より細かい成長の実感と目標設定が可能

### 🎯 ピッチ管理システムの完全自動化
- **手動管理の廃止**: song.jsonからpitchFileフィールドを完全削除
- **自動抽出**: 各楽曲の音源ファイルから自動的にピッチを抽出
- **キャッシュ最適化**: 2回目以降の高速読み込みを実現
- **運用負荷軽減**: 新規楽曲追加時の作業を大幅に簡素化

## ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## 参考資料

- [Flutter Documentation](https://docs.flutter.dev/)
- [just_audio Package](https://pub.dev/packages/just_audio)
- [record Package](https://pub.dev/packages/record)
- [pitch_detector_dart Package](https://pub.dev/packages/pitch_detector_dart)
