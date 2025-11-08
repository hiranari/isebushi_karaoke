# 伊勢節カラオケアプリ ドキュメント

## 📚 概要

このディレクトリには、伊勢節カラオケアプリケーションの全ドキュメントが含まれています。

## 📂 ディレクトリ構造

```
docs/
├── README.md （このファイル）
├── architecture/          # アーキテクチャ設計書
│   ├── LOGGING_ARCHITECTURE.md
│   ├── REFACTORING_STATUS.md
│   ├── REFACTORING_PLAN.md
│   └── UML_DOCUMENTATION.md
├── guidelines/           # 開発ガイドライン
│   ├── AUDIO_DEVELOPMENT_GUIDELINES.md
│   ├── LOGGING_GUIDELINES.md
│   ├── PROBLEMS_ZERO_POLICY.md
│   └── development/
│       ├── process.md
│       └── ...
└── operations/          # 運用管理
    ├── performance_metrics.md
    ├── error_handling_flows.md
    └── maintenance_procedures.md
```

## 📝 主要ドキュメント

### アーキテクチャ設計書
- [ロギングアーキテクチャ](./architecture/LOGGING_ARCHITECTURE.md)
- [リファクタリング状況](./architecture/REFACTORING_STATUS.md)
- [リファクタリング計画](./architecture/REFACTORING_PLAN.md)
- [UMLドキュメント](./architecture/UML_DOCUMENTATION.md)

### 開発ガイドライン
- [音声開発ガイドライン](./guidelines/AUDIO_DEVELOPMENT_GUIDELINES.md)
- [ロギングガイドライン](./guidelines/LOGGING_GUIDELINES.md)
- [Problems撲滅ポリシー](./guidelines/PROBLEMS_ZERO_POLICY.md)

### 運用管理
- [パフォーマンスメトリクス](./operations/performance_metrics.md)
- [エラーハンドリングフロー](./operations/error_handling_flows.md)
- [メンテナンス手順](./operations/maintenance_procedures.md)

## 🔄 バージョン管理

各ドキュメントには以下の情報が含まれています：
- バージョン番号
- 最終更新日
- 更新履歴

## 📋 ドキュメント更新ガイドライン

1. 新規ドキュメント作成時
   - 適切なディレクトリを選択
   - バージョン情報を含める
   - このREADMEに追加

2. 既存ドキュメント更新時
   - バージョン番号を更新
   - 更新履歴を記録
   - 関連ドキュメントとの整合性を確認

3. ドキュメント削除時
   - このREADMEから削除
   - 関連ドキュメントの参照を更新

## 👥 メンテナンス担当

- アーキテクチャ設計書: [担当者名]
- 開発ガイドライン: [担当者名]
- 運用管理: [担当者名]

---

*Version: 1.0.0*  
*最終更新: 2025年11月8日*