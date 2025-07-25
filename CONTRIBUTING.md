# 開発ガイドライン

## アーキテクチャ原則 (Phase 3で確立)

本プロジェクトは以下の基本原則に従って開発されています。全ての将来的な機能追加やリファクタリングにおいて、これらの原則を厳守してください。

### 🏗️ 単一責任の原則 (Single Responsibility Principle)
- **1クラス1責任**: 各クラスは明確に定義された単一の責任のみを持つ
- **例**: `ScoringService`はスコア算出のみ、`FeedbackService`はアドバイス生成のみ
- **利点**: テスタビリティ向上、保守性向上、変更影響の局所化

### 🔄 関心の分離 (Separation of Concerns)
- **UI層**: 表示とユーザーインタラクションのみ（`widgets/`、`pages/`）
- **ビジネスロジック層**: ドメインロジックの実装（`services/`）
- **データ層**: データモデルとその操作（`models/`）
- **状態管理層**: アプリケーション状態の管理（`providers/`）
- **利点**: 変更の独立性、並行開発の効率化、責任の明確化

### 🧪 テスタビリティ (Testability)
- **依存性注入**: 外部依存をインターフェースで抽象化
- **純粋関数**: 副作用のない関数の優先使用
- **モック可能設計**: テスト時のモック注入が可能な設計
- **利点**: 高品質なユニットテスト、回帰テスト、リファクタリング安全性

### 🔧 拡張性 (Extensibility)
- **オープン・クローズド原則**: 拡張に開いて、修正に閉じた設計
- **インターフェース指向**: 具象クラスではなくインターフェースに依存
- **プラグイン設計**: 新機能の追加が既存コードに影響しない設計
- **利点**: 機能追加の容易性、既存機能への影響最小化

## コーディングルール

### ファイル構成
- **1画面1ファイルの原則**: 各画面は独立したファイルに分割
- **機能別ディレクトリ構成**:
  ```
  lib/
  ├── pages/          # 画面ファイル（UI層）
  ├── widgets/        # 再利用可能なウィジェット（UI層）
  ├── providers/      # 状態管理（状態管理層）
  ├── services/       # ビジネスロジック・API呼び出し（ビジネスロジック層）
  ├── models/         # データモデル（データ層）
  └── utils/          # ユーティリティ関数
  ```

### クラス分割ルール
- **100行ルール**: 1クラス100行を超える場合は分割を検討
- **責任分離**: UI表示とビジネスロジックを明確に分離
- **サービスクラス**: 音声処理、ピッチ解析などは専用サービスクラスに分離

### 状態管理ルール (Phase 3で追加)
- **Provider パターン**: 状態管理には Provider を使用
- **ChangeNotifier**: 状態変更の通知には ChangeNotifier を継承
- **責任分離**: 1つの Provider は1つの責任領域のみを担当
- **ライフサイクル管理**: 状態の初期化、更新、破棄を明確に定義

### UI設計原則 (Phase 3で追加)
- **Consumer パターン**: 状態依存する UI は Consumer でラップ
- **プログレッシブ表示**: 情報の段階的開示によるUX向上
- **レスポンシブ対応**: 様々な画面サイズに対応した柔軟な設計
- **アクセシビリティ**: 色覚特性や視覚障害に配慮した設計

### 命名規則
- **クラス名**: PascalCase (例: `PitchDetectionService`)
- **メソッド名**: camelCase (例: `extractPitchFromAudio`)
- **ファイル名**: snake_case (例: `pitch_detection_service.dart`)
- **定数**: UPPER_SNAKE_CASE (例: `DEFAULT_SAMPLE_RATE`)

### 変数名命名規則 ⚠️ 【新設・厳守必須】
- **省略禁止原則**: 変数名は省略せず、意味が明確に伝わる完全な名前を使用
- **例**: 
  - ❌ `fundamentalFreqs` → ✅ `fundamentalFrequencies`
  - ❌ `freqIndex` → ✅ `frequencyIndex`
  - ❌ `baseFreq` → ✅ `baseFrequency`
  - ❌ `avgErr` → ✅ `averageError`
  - ❌ `maxVal` → ✅ `maximumValue`
- **可読性優先**: 長い名前でも可読性を重視
- **スペルチェック辞書**: 専門用語は `.vscode/settings.json` の `cSpell.words` に登録
- **辞書登録ルール**: 
  - 省略形ではなく完全な単語を登録
  - 意味が明確に分かる形で登録
  - 登録時は意味をコメントで併記することを推奨
  - プロジェクト固有の単語は `.vscode/project-words.txt` に追加

### スペルチェック管理
- **辞書ファイル**: `.vscode/project-words.txt` にプロジェクト固有の単語を登録
- **VS Code設定**: `.vscode/settings.json` でスペルチェック動作を制御
- **コードブロック**: マークダウンファイルのコードブロック内はスペルチェック対象外
- **追加方法**: 新しい専門用語は辞書ファイルに追加後、チーム共有

### エラーハンドリング
- **必須**: すべての非同期処理にエラーハンドリングを実装
- **ユーザー通知**: エラー時はSnackBarで適切なメッセージを表示
- **ログ出力**: デバッグ用のログを適切に出力
- **グレースフルデグラデーション**: エラー時も可能な限り機能を提供

### コード品質管理ルール ⚠️ 【新設・厳守必須】
- **ゼロ警告原則**: エラー、警告、情報を含む全てのlint問題を残さない
- **flutter analyze**: コミット前に必ず実行し、すべての問題を解決
- **品質チェック項目**:
  - `prefer_const_constructors`: constコンストラクタの使用
  - `avoid_print`: 本番コードでのprint文の禁止
  - `use_build_context_synchronously`: BuildContextの適切な使用
  - `constant_identifier_names`: 定数名はlowerCamelCaseに統一
  - `unnecessary_overrides`: 不要なオーバーライドの削除
  - `deprecated_member_use`: 非推奨APIの使用禁止（例: `withOpacity` → `withValues`）
  - `unused_element`: 未使用の要素の削除
- **コミット基準**: `flutter analyze`で0 issues foundの状態のみコミット可能
- **テスト実行**: `flutter test`で全てのテストが通ることを確認
- **品質保証フロー**:
  1. `flutter analyze` → No issues found!
  2. `flutter test` → All tests passed!
  3. 上記2つが完了してからコミット実行

### Phase 3 専用ルール
- **スコアリング**: `lib/services/scoring_service.dart` に集約
- **フィードバック生成**: `lib/services/feedback_service.dart` に集約
- **状態管理**: `lib/providers/karaoke_session_provider.dart` で歌唱セッション管理
- **UI コンポーネント**: `lib/widgets/` で再利用可能なウィジェット実装
- **プログレッシブ表示**: タップによる段階的情報開示を必須とする

### コメント規則
- **クラス**: 目的と責任を明記
- **複雑なメソッド**: アルゴリズムの説明を記載
- **TODO**: 将来の改善予定の箇所は明記
- **アーキテクチャ説明**: Phase 3で導入された設計パターンの説明を記載

## Git コミットルール
- **feat**: 新機能追加
- **fix**: バグ修正
- **refactor**: リファクタリング
- **docs**: ドキュメント更新
- **arch**: アーキテクチャ変更 (Phase 3で追加)

例: `feat: 多角的スコアリングシステムを実装`