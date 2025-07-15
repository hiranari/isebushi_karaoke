# 開発ガイドライン

## アーキテクチャ原則（Phase 3で確立）

### 🏗️ 必須設計原則

**すべての今後の機能開発と既存コードのリファクタリングは、以下の原則に従う必要があります：**

#### 1. 単一責任原則 (Single Responsibility Principle)
- **原則**: 各クラス・サービスは1つの責任のみを持つ
- **実装例**: 
  - `ScoringService` → スコア計算専用
  - `AnalysisService` → 詳細分析専用  
  - `FeedbackService` → フィードバック生成専用
- **違反例**: 1つのクラスでスコア計算とUI表示を両方行う

#### 2. 関心の分離 (Separation of Concerns)
- **原則**: UIロジックとビジネスロジックの完全分離
- **実装例**:
  - `SongResultWidget` → UI表示のみ
  - `SongResultProvider` → 状態管理のみ
  - `ScoringService` → 計算ロジックのみ
- **ディレクトリ構成**: `models/`, `services/`, `providers/`, `widgets/`, `pages/`

#### 3. テスト容易性 (Testability)  
- **原則**: 純粋関数の優先使用、依存性注入の活用
- **実装例**:
  - サービスクラスは静的メソッドで副作用なし
  - モック可能なインターフェース設計
  - 単体テストでの100%カバレッジ目標
- **テストファイル**: `test/*_test.dart`で対応するサービスをテスト

#### 4. 拡張性 (Extensibility)
- **原則**: 新機能追加時の既存コード変更を最小化
- **実装例**:
  - オープン・クローズド原則の適用
  - プラグイン可能な評価指標システム
  - 設定可能なスコア重み
- **新機能**: 既存のインターフェースを変更せず拡張

### 📁 Phase 3 アーキテクチャ構成

```
lib/
├── models/          # データモデル（SongResult等）
├── services/        # ビジネスロジック（Scoring, Analysis, Feedback）
├── providers/       # 状態管理（SongResultProvider）
├── widgets/         # 再利用可能UI（SongResultWidget）
├── pages/           # 画面ファイル（KaraokePage等）
└── utils/           # ユーティリティ関数
```

### 🔄 状態管理規則（Provider使用）

#### SongResultProviderのライフサイクル
- **作成**: アプリ起動時にMultiProviderで初期化
- **更新**: 歌唱終了時に`calculateSongResult()`で結果計算
- **状態**: `ResultDisplayState`で段階的表示を管理
- **破棄**: 新しい歌唱開始時に`clearResult()`でリセット

#### 状態の責任範囲
- **Provider**: ビジネスロジックの結果とUI状態の管理
- **Widget**: 状態の購読とUI表示のみ
- **Service**: 純粋な計算処理（状態を持たない）

## コーディングルール

### ファイル構成
- **1画面1ファイルの原則**: 各画面は独立したファイルに分割
- **機能別ディレクトリ構成**:
  ```
  lib/
  ├── pages/          # 画面ファイル
  ├── services/       # ビジネスロジック・API呼び出し
  ├── models/         # データモデル
  ├── utils/          # ユーティリティ関数
  └── widgets/        # 再利用可能なウィジェット
  ```

### クラス分割ルール
- **100行ルール**: 1クラス100行を超える場合は分割を検討
- **責任分離**: UI表示とビジネスロジックを明確に分離
- **サービスクラス**: 音声処理、ピッチ解析などは専用サービスクラスに分離

### 命名規則
- **クラス名**: PascalCase (例: `PitchDetectionService`)
- **メソッド名**: camelCase (例: `extractPitchFromAudio`)
- **ファイル名**: snake_case (例: `pitch_detection_service.dart`)
- **定数**: UPPER_SNAKE_CASE (例: `DEFAULT_SAMPLE_RATE`)

### エラーハンドリング
- **必須**: すべての非同期処理にエラーハンドリングを実装
- **ユーザー通知**: エラー時はSnackBarで適切なメッセージを表示
- **ログ出力**: デバッグ用のログを適切に出力

### Phase 1 専用ルール
- **MP3処理**: `lib/services/audio_processing_service.dart` に集約
- **ピッチ検出**: `lib/services/pitch_detection_service.dart` に集約
- **キャッシュ管理**: `lib/services/cache_service.dart` に集約
- **非同期処理**: FutureBuilder使用時は必ずローディング状態を表示

### コメント規則
- **クラス**: 目的と責任を明記
- **複雑なメソッド**: アルゴリズムの説明を記載
- **TODO**: Phase 2, 3で改善予定の箇所は明記

## Git コミットルール
- **feat**: 新機能追加
- **fix**: バグ修正
- **refactor**: リファクタリング
- **docs**: ドキュメント更新

例: `feat: MP3からピッチ検出機能を実装`