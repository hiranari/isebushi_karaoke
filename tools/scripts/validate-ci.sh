#!/bin/bash

# Flutter CI Local Validation Script
# このスクリプトはCIと同じチェックをローカルで実行します

set -e

echo "🚀 Flutter CI ローカル検証を開始します..."

# Flutter がインストールされているかチェック
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter がインストールされていません。README.md の「Flutter SDKのインストール」セクションを参照してください。"
    exit 1
fi

echo "✅ Flutter の確認"
flutter --version

echo "📦 依存関係の取得"
flutter pub get

echo "🔍 依存関係の確認"
flutter pub deps

echo "🔍 静的解析の実行"
flutter analyze --fatal-infos

echo "🧪 テストの実行"
flutter test --coverage --reporter expanded

echo ""
echo "🎉 すべてのチェックが完了しました！"
echo "   このブランチはCIを通過する準備ができています。"
echo ""
echo "カバレッジレポートは coverage/lcov.info に保存されました。"