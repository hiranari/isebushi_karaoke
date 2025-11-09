# 🎯 ピッチ検証ツール - 使用ガイド

## 📋 概要
カラオケ画面の基準ピッチが思った結果になっていない問題を解決するため、外部ツールからピッチデータの検証を行えるようになりました。

## 🚀 基本的な使用方法

### コマンドライン実行
```bash
# 基本的な検証（コンソール出力のみ）
dart tools/verification/pitch_verification_tool.dart assets/sounds/Test.wav

# 詳細表示 + JSON出力
dart tools/verification/pitch_verification_tool.dart assets/sounds/Test.wav --json --verbose

# キャッシュを使わず特定ディレクトリに出力
dart tools/verification/pitch_verification_tool.dart path/to/file.wav --no-cache --json -o ./my_results
```

### 利用可能なオプション
- `--json, -j`: 結果をJSONファイルに出力
- `--verbose, -v`: 詳細な情報を表示
- `--no-cache`: キャッシュを使用せず新規解析
- `--output-dir, -o DIR`: JSON出力ディレクトリ指定
- `--help, -h`: ヘルプ表示

## 📊 出力される情報

### コンソール出力
- 楽曲ファイル名
- 処理時間
- キャッシュ使用状況
- 統計情報（総ピッチ数、有効率、ピッチ範囲、期待範囲適合）
- 詳細データ（最初・最後の10個のピッチ）

### JSON出力（--jsonオプション使用時）
```json
{
  "wavFilePath": "assets/sounds/Test.wav",
  "analyzedAt": "2025-07-31T12:00:00.000Z",
  "fromCache": true,
  "statistics": {
    "totalCount": 1234,
    "validCount": 1100,
    "validRate": 89.1,
    "minPitch": 261.6,
    "maxPitch": 523.3,
    "avgPitch": 392.5,
    "pitchRange": 261.7,
    "isInExpectedRange": true,
    "firstTen": [261.6, 293.7, ...],
    "lastTen": [440.0, 523.3, ...]
  },
  "pitches": [261.6, 293.7, 329.6, ...]
}
```

## 🎯 カラオケ画面との統合

新しい実装では、カラオケ画面と外部ツールが**同じロジック**を使用します：

1. **カラオケ画面**: `VerifyPitchUseCase`を使用してピッチ検証
2. **外部ツール**: 同じ`VerifyPitchUseCase`を使用してピッチ検証
3. **DRY原則**: コード重複なし、一貫性のある結果

## 🔍 トラブルシューティング

### よくある問題
1. **"WAVファイルが見つかりません"**
   - ファイルパスを確認してください
   - アセットファイルは`assets/`から始まるパスを使用

2. **"Flutter binding の初期化エラー"**
   - `flutter test`環境が正しく設定されているか確認

3. **"権限エラー"**
   - JSON出力ディレクトリの書き込み権限を確認

### デバッグオプション
```bash
# エラー時のスタックトレース表示
dart tools/verification/pitch_verification_tool.dart file.wav --debug
```

## 📁 出力ファイル

### JSON出力先
- デフォルト: `./verification_results/`
- ファイル名形式: `{ファイル名}_verification_{タイムスタンプ}.json`
- 例: `Test_verification_2025-07-31T12-00-00.json`

## 🎯 期待効果

1. **透明性の向上**: ピッチ検出結果をJSON形式で詳細確認
2. **デバッグ効率**: カラオケ画面と外部ツールで一貫した結果
3. **保守性**: クリーンアーキテクチャによる責務分離
4. **拡張性**: 新しい検証機能の追加が容易

---

*作成日: 2025年7月31日*
*基準ピッチ検証ツール強化 - Phase 3 実装完了*
