---
applyTo: '**'
description: 'プロジェクトのフォルダ構成とファイル配置のガイドライン'
---

# フォルダ構成ガイドライン

## Root Directory Structure
- `lib/`: メインのソースコードディレクトリ
- `test/`: テストコードディレクトリ
- `docs/`: プロジェクトドキュメント
- `tools/`: 開発用ツール
- `assets/`: 静的リソース

## Main Source Code Organization (`lib/`)
- `application/`: アプリケーション層（ユースケース、サービス）
- `domain/`: ドメイン層（エンティティ、値オブジェクト）
- `infrastructure/`: インフラストラクチャ層（リポジトリ実装、外部サービス）
- `presentation/`: プレゼンテーション層（UI、ビューモデル）
- `core/`: 共通ユーティリティ

## Test Directory Structure (`test/`)
- ソースコードと同じ構造を維持
- 各テストファイルは対応するソースファイルと同じ名前に`_test.dart`を付加

## Assets Organization
- `assets/data/`: JSONなどのデータファイル
- `assets/images/`: 画像リソース
- `assets/sounds/`: 音声ファイル
- `assets/icon/`: アプリアイコン

## Documentation Structure (`docs/`)
- `architecture/`: アーキテクチャ設計文書
- `guidelines/`: 開発ガイドライン
- `development/`: 開発関連ドキュメント

## Naming Conventions
- ディレクトリ名はスネークケース
- Dartファイル名はスネークケース
- クラス名はパスカルケース
- パッケージ名はスネークケース
