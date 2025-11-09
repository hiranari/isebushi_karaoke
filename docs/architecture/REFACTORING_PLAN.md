# 伊勢節カラオケアプリ包括的リファクタリング計画

## 概要

このドキュメントは、`AUDIO_DEVELOPMENT_GUIDELINES.md`からの確立されたガイドラインに従い、クリーンアーキテクチャ原則を実装する伊勢節カラオケアプリケーションの包括的リファクタリング計画を概説します。

## 現状分析

### 特定された問題
1. **重複サービス**: 改善提案サービスの複数バージョン（`improvement_suggestion_service.dart`と`improvement_suggestion_service_new.dart`）
2. **ウィジェット重複**: 改善提案ウィジェットの複数バージョン
3. **サービス結合**: 音声処理とピッチ検出サービス間の密結合
4. **一貫性のない命名**: 一部のサービスで責任が不明確
5. **抽象化の欠如**: サービス用の明確なインターフェース定義なし
6. **WAVのみ移行**: ガイドラインに従ったWAVのみサポートの完全実装

## リファクタリング目標

### 主要目的
1. **重複の排除**: 重複サービス・ウィジェットファイルの削除
2. **関心の分離改善**: サービス間の明確な境界
3. **保守性向上**: より良いコード構成とドキュメント
4. **クリーンアーキテクチャ実装**: 適切な階層化と依存性逆転
5. **命名標準化**: コードベース全体の一貫した命名規則
6. **包括的UML作成**: 詳細図によるアーキテクチャドキュメント

### 副次目的
1. **パフォーマンス最適化**: 冗長処理の削減
2. **エラーハンドリング**: 一貫したエラーハンドリングパターン
3. **テストカバレッジ**: リファクタリングされたコードのテストカバレッジ向上
4. **Documentation**: Complete inline and architectural documentation

## Proposed Architecture

### Layer Structure

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (Pages, Widgets, Providers)       │
├─────────────────────────────────────┤
│          Application Layer          │
│     (Use Cases, State Logic)       │
├─────────────────────────────────────┤
│            Domain Layer             │
│    (Models, Interfaces, Rules)     │
├─────────────────────────────────────┤
│         Infrastructure Layer        │
│  (Audio Processing, File I/O)      │
└─────────────────────────────────────┘
```

## Detailed Refactoring Plan

### Phase 1: Service Layer Cleanup

#### 1.1 Remove Duplicate Services
- [ ] Remove `improvement_suggestion_service_new.dart`
- [ ] Remove `analysis_service_new.dart`  
- [ ] Consolidate functionality into main service files
- [ ] Update imports across the codebase

#### 1.2 Service Interface Definition
- [ ] Create abstract interfaces for all services
- [ ] Implement dependency inversion principle
- [ ] Define clear service contracts

#### 1.3 Service Reorganization
```
services/
├── interfaces/
│   ├── i_audio_processing_service.dart
│   ├── i_pitch_detection_service.dart
│   ├── i_scoring_service.dart
│   └── i_analysis_service.dart
├── implementations/
│   ├── audio_processing_service_impl.dart
│   ├── pitch_detection_service_impl.dart
│   ├── scoring_service_impl.dart
│   └── analysis_service_impl.dart
└── factories/
    └── service_factory.dart
```

### Phase 2: Widget Layer Cleanup

#### 2.1 Remove Duplicate Widgets
- [ ] Remove `improvement_suggestions_widget_new.dart`
- [ ] Consolidate functionality into main widget
- [ ] Update widget references

#### 2.2 Widget Reorganization
```
widgets/
├── common/
│   ├── score_display_base.dart
│   └── feedback_card.dart
├── karaoke/
│   ├── realtime_pitch_visualizer.dart
│   └── progressive_score_display.dart
└── results/
    ├── song_result_widget.dart
    ├── detailed_analysis_widget.dart
    └── improvement_suggestions_widget.dart
```

### Phase 3: Model Layer Enhancement

#### 3.1 Model Interfaces
- [ ] Add validation methods to models
- [ ] Implement proper equality and hashCode
- [ ] Add serialization/deserialization validation
- [ ] Create model builders for complex objects

### Phase 4: Provider Layer Optimization

#### 4.1 Provider Responsibilities
- [ ] Clearly define provider boundaries
- [ ] Implement proper error handling
- [ ] Add loading states
- [ ] Optimize notification patterns

## File Structure After Refactoring

```
lib/
├── main.dart
├── song_select_page.dart
├── core/
│   ├── constants/
│   │   └── audio_constants.dart
│   ├── errors/
│   │   └── audio_exceptions.dart
│   └── utils/
│       ├── debug_logger.dart
│       ├── singer_encoder.dart
│       └── pitch_debug_helper.dart
├── domain/
│   ├── models/
│   │   ├── song_result.dart
│   │   ├── comprehensive_score.dart
│   │   ├── improvement_suggestion.dart
│   │   ├── audio_analysis_result.dart
│   │   └── pitch_comparison_result.dart
│   └── interfaces/
│       ├── i_audio_processing_service.dart
│       ├── i_pitch_detection_service.dart
│       ├── i_scoring_service.dart
│       ├── i_analysis_service.dart
│       └── i_feedback_service.dart
├── application/
│   ├── providers/
│   │   ├── karaoke_session_provider.dart
│   │   └── song_result_provider.dart
│   └── use_cases/
│       ├── record_karaoke_use_case.dart
│       ├── analyze_performance_use_case.dart
│       └── generate_feedback_use_case.dart
├── infrastructure/
│   ├── services/
│   │   ├── audio_processing_service.dart
│   │   ├── pitch_detection_service.dart
│   │   ├── scoring_service.dart
│   │   ├── analysis_service.dart
│   │   ├── feedback_service.dart
│   │   ├── improvement_suggestion_service.dart
│   │   ├── pitch_comparison_service.dart
│   │   └── cache_service.dart
│   └── factories/
│       └── service_locator.dart
└── presentation/
    ├── pages/
    │   └── karaoke_page.dart
    └── widgets/
        ├── common/
        │   ├── loading_indicator.dart
        │   └── error_display.dart
        ├── karaoke/
        │   ├── realtime_pitch_visualizer.dart
        │   └── progressive_score_display.dart
        └── results/
            ├── song_result_widget.dart
            ├── overall_score_widget.dart
            ├── detailed_analysis_widget.dart
            └── improvement_suggestions_widget.dart
```

## Implementation Priority

### High Priority (Phase 1)
1. Remove duplicate files
2. Consolidate services
3. Update imports and references
4. Fix immediate compilation issues

### Medium Priority (Phase 2) 
1. Implement service interfaces
2. Reorganize file structure
3. Update provider logic
4. Enhance error handling

### Low Priority (Phase 3)
1. Optimize performance
2. Add comprehensive testing
3. Complete documentation
4. Implement advanced features

## Quality Assurance

### Testing Strategy
- [ ] Unit tests for all services
- [ ] Widget tests for UI components
- [ ] Integration tests for complete workflows
- [ ] Performance tests for audio processing

### Code Quality Checks
- [ ] Static analysis with dart analyzer
- [ ] Code formatting with dart format
- [ ] Documentation completeness
- [ ] Adherence to guidelines

## Migration Plan

### Step 1: Backup and Branch
```bash
git checkout -b refactoring/comprehensive-cleanup
git add .
git commit -m "Backup before comprehensive refactoring"
```

### Step 2: Remove Duplicates
1. Delete duplicate service files
2. Delete duplicate widget files
3. Update all import statements
4. Run tests to ensure no breakage

### Step 3: Restructure
1. Create new directory structure
2. Move files to appropriate locations
3. Update imports again
4. Update pubspec.yaml if needed

### Step 4: Validate
1. Run all tests
2. Test app functionality
3. Check for any remaining issues
4. Update documentation

## Success Metrics

- [ ] Zero duplicate files
- [ ] All tests passing
- [ ] App functionality preserved
- [ ] Improved maintainability score
- [ ] Clear architecture documentation
- [ ] Performance maintained or improved

## Next Steps

1. Review and approve this refactoring plan
2. Create detailed UML diagrams (next document)
3. Begin implementation following the migration plan
4. Regular checkpoints and reviews
5. Final validation and documentation update
