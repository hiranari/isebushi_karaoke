---
applyTo: '**/*_test.dart'
description: 'テストコード作成のガイドライン'
---

# テストガイドライン

## Test Structure
- Arrange-Act-Assert パターンを使用
- テストの説明は明確に
- テストケースは独立して実行可能に

## Testing Best Practices
- テストデータは明示的に定義
- モックは必要最小限に
- エッジケースのテストを忘れずに
- パフォーマンステストは重要な機能に対して実施

## Test Categories
- Unit Tests: ビジネスロジックの検証
- Widget Tests: UI コンポーネントの検証
- Integration Tests: フロー全体の検証
- Performance Tests: パフォーマンスの検証
