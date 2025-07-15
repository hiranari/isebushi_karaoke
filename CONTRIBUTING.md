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