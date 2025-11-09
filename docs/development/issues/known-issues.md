# 既知の問題点 (Known Issues)

## 1. フォルダ構造の問題

- **説明:** 現在のフォルダ構成には、Clean Architectureの原則から外れているファイルがいくつか存在します。
- **重要度:** 中
- **ステータス:** 未着手
- **詳細:**
  - `lib/song_select_page.dart` は `lib/presentation/pages/` へ移動する必要があります。
  - `lib/pages/` ディレクトリは `lib/presentation/pages/` へ統合する必要があります。
  - プロジェクトルートにある `.dart` ファイル群は `tools/` へ移動する必要があります。
  - `scripts/` ディレクトリは `tools/scripts/` へ移動する必要があります。
- **出典:** `docs/guidelines/FOLDER_STRUCTURE_GUIDELINES.md`

## 2. KaraokePageの責務肥大化

- **説明:** `KaraokePage` に音声再生、スコア計算、デバッグ表示など、多数の責務が混在しています。
- **重要度:** 低
- **ステータス:** 未着手
- **詳細:**
  - 機能が安定した後に、`AudioManager`, `RealtimeScoreManager`, `DebugManager` などの関心事に基づいてクラスを分離することが推奨されます。
- **出典:** `docs/development/REFACTORING_TASK_LIST.md`

## 3. テストカバレッジ

- **説明:** `pitch_detection_test.dart`以外のPhase機能に対するテストカバレッジが不足しています。
- **重要度:** 低
- **ステータス:** 未着手
- **詳細:**
  - プロジェクトの品質を担保するため、各機能に対応するユニットテストや統合テストを拡充する必要があります。
- **出典:** `docs/development/REFACTORING_TASK_LIST.md`

## 4. コミットメッセージの不統一

- **説明:** 一部のコミットメッセージが、ガイドラインで定められた形式（日本語での明確な形式）に準拠していません。
- **重要度:** 低
- **ステータス:** 未着手
- **詳細:**
  - 今後のコミットにおいては、`COMMIT_GUIDELINES.md` に従うことを徹底する必要があります。
- **出典:** `docs/development/REFACTORING_TASK_LIST.md`
