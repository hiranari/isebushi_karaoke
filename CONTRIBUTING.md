# 開発ガイドライン

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

### Phase 3 専用ルール
- **総合スコアリング**: `lib/services/scoring_service.dart` に集約
- **詳細分析**: `lib/services/analysis_service.dart` に集約  
- **改善提案**: `lib/services/improvement_suggestion_service.dart` に集約
- **状態管理**: `lib/services/karaoke_session_notifier.dart` でUI状態制御
- **プログレッシブUI**: 段階的情報開示パターンの実装
- **データモデル**: `lib/models/song_result.dart` で歌唱結果を一元管理

### テスト方針
- **ユニットテスト**: ビジネスロジック（services/models）の完全網羅
- **ウィジェットテスト**: UI層の表示とインタラクションの検証
- **保守性重視**: テストコードも100行ルール・可読性・単一責務を遵守
- **分離テスト**: UI層とロジック層の独立したテスト実装

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