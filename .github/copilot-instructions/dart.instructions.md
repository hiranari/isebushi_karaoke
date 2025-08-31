---
applyTo: '**/*.dart'
description: 'Dartコードの開発ガイドライン'
---

# Dart開発ガイドライン

## Code Structure
- Provider パターンを使用した状態管理
- Widgetは小さく保ち、責務を明確に
- ビジネスロジックはドメイン層に集中

## Flutter Best Practices
- const constructorを積極的に使用
- StatelessWidgetを優先して使用
- BuildContextの使用は最小限に

## Testing
- Widget テストは必須
- Integration テストはUI フローの検証に使用
- モックを適切に活用したユニットテスト
