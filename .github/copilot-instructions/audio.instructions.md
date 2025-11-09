---
applyTo: '**/audio/**/*.dart'
description: '音声処理と分析に関するガイドライン'
---

# 音声開発ガイドライン

## Audio Processing Best Practices
- 音声データの処理は非同期で実行
- バッファサイズは環境に応じて適切に設定
- メモリ使用量を考慮した実装

## Library Usage
- `just_audio`: 音声再生の基本機能
- `record`: 音声録音機能
- 新しいライブラリの導入は慎重に検討

## Audio Analysis
- ピッチ検出のアルゴリズムは精度を重視
- FFTの設定は処理速度とのバランスを考慮
- リアルタイム処理では適切なバッファ管理が必須

## Error Handling
- 音声デバイスのエラー処理を適切に実装
- ユーザーへの適切なフィードバック提供
- エラーログの詳細な記録

## Performance Considerations
- メモリリークの防止
- バックグラウンド処理の適切な管理
- デバイスリソースの効率的な利用
