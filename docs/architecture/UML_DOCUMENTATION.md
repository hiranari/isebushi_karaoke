# 🏗️ Isebushi Karaoke - UMLアーキテクチャドキュメント

> **更新ポリシー**: 新機能追加・修正時は必ずUML図を更新してください。

## 📋 ドキュメント情報
- **作成日**: 2025年7月31日
- **最終更新**: 2025年7月31日
- **対象ブランチ**: copilot/fix-e14957fd-f22b-4af8-9758-246edf71f633
- **更新理由**: 基準ピッチ検証ツール強化対応

---

## 🎯 現在のクリーンアーキテクチャ概要

```mermaid
graph TB
    subgraph "🎨 Presentation Layer"
        KP[KarakokePage]
        SSP[SongSelectPage]
        PVW[PitchVisualizationWidget]
        RSW[RealtimeScoreWidget]
    end
    
    subgraph "💼 Application Layer"
        KSP[KaraokeSessionProvider]
        SRP[SongResultProvider]
        UC[UseCases]
    end
    
    subgraph "🏛️ Domain Layer"
        subgraph "Interfaces"
            IPDS[IPitchDetectionService]
            IAS[IAnalysisService]
            ISS[IScoringService]
            ICS[ICacheService]
            IAPS[IAudioProcessingService]
            IFS[IFeedbackService]
        end
        
        subgraph "Models"
            AAR[AudioAnalysisResult]
            AD[AudioData]
            CS[ComprehensiveScore]
            IS[ImprovementSuggestion]
            PCR[PitchComparisonResult]
            SM[ScoringModels]
            SR[SongResult]
        end
    end
    
    subgraph "🔧 Infrastructure Layer"
        PDS[PitchDetectionService]
        AS[AnalysisService]
        SS[ScoringService]
        CacheS[CacheService]
        APS[AudioProcessingService]
        FS[FeedbackService]
        ISS_IMPL[ImprovementSuggestionService]
        PCS[PitchComparisonService]
        WP[WavProcessor]
        WV[WavValidator]
    end
    
    subgraph "🛠️ Tools Layer"
        TRP[TestReferencePitch]
        TPD[TestPitchDetection]
    end
    
    %% Dependencies
    KP --> KSP
    KP --> PDS
    SSP --> CacheS
    
    KSP --> IPDS
    SRP --> ISS
    
    PDS -.-> IPDS
    AS -.-> IAS
    SS -.-> ISS
    CacheS -.-> ICS
    APS -.-> IAPS
    FS -.-> IFS
    
    PDS --> AAR
    AS --> PCR
    SS --> CS
    
    TRP --> PDS
    TPD --> PDS
    
    classDef presentationStyle fill:#e1f5fe
    classDef applicationStyle fill:#f3e5f5
    classDef domainStyle fill:#e8f5e8
    classDef infrastructureStyle fill:#fff3e0
    classDef toolsStyle fill:#fce4ec
    
    class KP,SSP,PVW,RSW presentationStyle
    class KSP,SRP,UC applicationStyle
    class IPDS,IAS,ISS,ICS,IAPS,IFS,AAR,AD,CS,IS,PCR,SM,SR domainStyle
    class PDS,AS,SS,CacheS,APS,FS,ISS_IMPL,PCS,WP,WV infrastructureStyle
    class TRP,TPD toolsStyle
```

---

## 🎯 基準ピッチ検証ツール強化 - 新アーキテクチャ設計

### 📐 拡張後のクリーンアーキテクチャ

```mermaid
graph TB
    subgraph "🎨 Presentation Layer"
        KP[KarakokePage<br/>_loadReferencePitches]
        SSP[SongSelectPage]
        PVW[PitchVisualizationWidget]
        RSW[RealtimeScoreWidget]
    end
    
    subgraph "💼 Application Layer"
        KSP[KaraokeSessionProvider]
        SRP[SongResultProvider]
        VPU[VerifyPitchUseCase<br/>🆕]
    end
    
    subgraph "🏛️ Domain Layer"
        subgraph "Interfaces"
            IPDS[IPitchDetectionService]
            IAS[IAnalysisService]
            ISS[IScoringService]
            ICS[ICacheService]
            IAPS[IAudioProcessingService]
            IFS[IFeedbackService]
            IPVS[IPitchVerificationService<br/>🆕]
        end
        
        subgraph "Models"
            AAR[AudioAnalysisResult]
            AD[AudioData]
            CS[ComprehensiveScore]
            IS[ImprovementSuggestion]
            PCR[PitchComparisonResult]
            SM[ScoringModels]
            SR[SongResult]
            PVR[PitchVerificationResult<br/>🆕]
        end
    end
    
    subgraph "🔧 Infrastructure Layer"
        PDS[PitchDetectionService]
        AS[AnalysisService]
        SS[ScoringService]
        CacheS[CacheService]
        APS[AudioProcessingService]
        FS[FeedbackService]
        ISS_IMPL[ImprovementSuggestionService]
        PCS[PitchComparisonService]
        WP[WavProcessor]
        WV[WavValidator]
        PVS[PitchVerificationService<br/>🆕]
    end
    
    subgraph "🛠️ Tools Layer"
        TRP[TestReferencePitch]
        TPD[TestPitchDetection]
        PVT[PitchVerificationTool<br/>🆕]
    end
    
    subgraph "📁 Output"
        JSON[verification_results/<br/>*.json<br/>🆕]
    end
    
    %% 新しい依存関係
    KP --> VPU
    VPU --> IPVS
    PVS -.-> IPVS
    PVS --> PVR
    PVS --> PDS
    PVS --> CacheS
    
    PVT --> VPU
    PVT --> JSON
    
    %% 既存の依存関係
    KP --> KSP
    KP --> PDS
    SSP --> CacheS
    
    KSP --> IPDS
    SRP --> ISS
    
    PDS -.-> IPDS
    AS -.-> IAS
    SS -.-> ISS
    CacheS -.-> ICS
    APS -.-> IAPS
    FS -.-> IFS
    
    PDS --> AAR
    AS --> PCR
    SS --> CS
    
    TRP --> PDS
    TPD --> PDS
    
    classDef presentationStyle fill:#e1f5fe
    classDef applicationStyle fill:#f3e5f5
    classDef domainStyle fill:#e8f5e8
    classDef infrastructureStyle fill:#fff3e0
    classDef toolsStyle fill:#fce4ec
    classDef newStyle fill:#ffeb3b,stroke:#f57f17,stroke-width:3px
    classDef outputStyle fill:#f1f8e9
    
    class KP,SSP,PVW,RSW presentationStyle
    class KSP,SRP applicationStyle
    class IPDS,IAS,ISS,ICS,IAPS,IFS,AAR,AD,CS,IS,PCR,SM,SR domainStyle
    class PDS,AS,SS,CacheS,APS,FS,ISS_IMPL,PCS,WP,WV infrastructureStyle
    class TRP,TPD toolsStyle
    class JSON outputStyle
    
    %% 新規追加要素
    class VPU,IPVS,PVR,PVS,PVT newStyle
```

---

## 🔍 基準ピッチ検証ツール - クラス詳細設計

### 🏛️ Domain Layer

#### IPitchVerificationService (Interface)

```mermaid
classDiagram
    class IPitchVerificationService {
        <<interface>>
        +verifyPitchData(wavFilePath: String, useCache: bool) PitchVerificationResult
        +extractReferencePitches(wavFilePath: String, useCache: bool) List~double~
        +exportToJson(result: PitchVerificationResult, outputPath: String) Future~void~
        +compareWithReference(pitches: List~double~, referencePitches: List~double~) ComparisonStats
    }
    
    class PitchVerificationResult {
        +String wavFilePath
        +DateTime analyzedAt
        +List~double~ pitches
        +PitchStatistics statistics
        +bool fromCache
        +ComparisonStats? comparison
        +Map~String, dynamic~ toJson()
        +PitchVerificationResult.fromJson(Map~String, dynamic~ json)
    }
    
    class PitchStatistics {
        +int totalCount
        +int validCount
        +int invalidCount
        +double validRate
        +double minPitch
        +double maxPitch
        +double avgPitch
        +double pitchRange
        +bool isInExpectedRange
        +List~double~ firstTen
        +List~double~ lastTen
    }
    
    class ComparisonStats {
        +double similarity
        +double rmse
        +double correlation
        +List~double~ differences
        +String comparisonSummary
    }
    
    IPitchVerificationService --> PitchVerificationResult
    PitchVerificationResult --> PitchStatistics
    PitchVerificationResult --> ComparisonStats
```

### 🔧 Infrastructure Layer

#### PitchVerificationService (Implementation)

```mermaid
classDiagram
    class PitchVerificationService {
        -PitchDetectionService _pitchDetectionService
        -CacheService _cacheService
        +initialize() void
        +verifyPitchData(wavFilePath: String, useCache: bool) PitchVerificationResult
        +extractReferencePitches(wavFilePath: String, useCache: bool) List~double~
        +exportToJson(result: PitchVerificationResult, outputPath: String) Future~void~
        +compareWithReference(pitches: List~double~, referencePitches: List~double~) ComparisonStats
        -_calculateStatistics(pitches: List~double~) PitchStatistics
        -_isInExpectedRange(minPitch: double, maxPitch: double) bool
        -_ensureOutputDirectory(outputPath: String) Future~void~
    }
    
    class PitchDetectionService {
        +extractPitchFromAudio(sourcePath: String, isAsset: bool) AudioAnalysisResult
    }
    
    class CacheService {
        +loadFromCache(filePath: String) AudioAnalysisResult?
        +saveToCache(filePath: String, result: AudioAnalysisResult) Future~void~
    }
    
    PitchVerificationService --> PitchDetectionService
    PitchVerificationService --> CacheService
    PitchVerificationService ..|> IPitchVerificationService
```

### 💼 Application Layer

#### VerifyPitchUseCase

```mermaid
classDiagram
    class VerifyPitchUseCase {
        -IPitchVerificationService _verificationService
        +VerifyPitchUseCase(IPitchVerificationService verificationService)
        +execute(wavFilePath: String, useCache: bool, exportJson: bool) PitchVerificationResult
        +executeWithComparison(wavFilePath: String, referencePitches: List~double~, useCache: bool) PitchVerificationResult
        -_handleJsonExport(result: PitchVerificationResult, wavFilePath: String) Future~void~
        -_generateOutputPath(wavFilePath: String) String
    }
    
    VerifyPitchUseCase --> IPitchVerificationService
```

### 🛠️ Tools Layer

#### PitchVerificationTool

```mermaid
classDiagram
    class PitchVerificationTool {
        -VerifyPitchUseCase _useCase
        +main(List~String~ args) Future~void~
        -_parseArguments(List~String~ args) ToolArguments
        -_validateWavFile(String filePath) bool
        -_printResults(PitchVerificationResult result) void
        -_printUsage() void
    }
    
    class ToolArguments {
        +String wavFilePath
        +bool useCache
        +bool exportJson
        +bool verbose
        +String? outputDir
    }
    
    PitchVerificationTool --> VerifyPitchUseCase
    PitchVerificationTool --> ToolArguments
```

---

## 🔄 データフロー図

### 従来の基準ピッチ読み込みフロー

```mermaid
sequenceDiagram
    participant KP as KarakokePage
    participant PDS as PitchDetectionService
    participant CS as CacheService
    
    KP->>+KP: _loadReferencePitches()
    KP->>+CS: loadFromCache(audioFile)
    CS-->>-KP: cachedResult?
    
    alt キャッシュなし
        KP->>+PDS: extractPitchFromAudio()
        PDS-->>-KP: analysisResult
        KP->>+CS: saveToCache()
        CS-->>-KP: saved
    end
    
    KP->>KP: setState(pitches)
    Note over KP: デバッグ情報はコンソール出力のみ
```

### 🆕 新しい検証ツール統合フロー

```mermaid
sequenceDiagram
    participant PVT as PitchVerificationTool
    participant VPU as VerifyPitchUseCase
    participant PVS as PitchVerificationService
    participant PDS as PitchDetectionService
    participant CS as CacheService
    participant JSON as JSONファイル
    
    PVT->>+VPU: execute(wavFilePath, useCache, exportJson)
    VPU->>+PVS: verifyPitchData(wavFilePath, useCache)
    
    PVS->>+CS: loadFromCache(wavFilePath)
    CS-->>-PVS: cachedResult?
    
    alt キャッシュなし
        PVS->>+PDS: extractPitchFromAudio()
        PDS-->>-PVS: analysisResult
        PVS->>+CS: saveToCache()
        CS-->>-PVS: saved
    end
    
    PVS->>PVS: _calculateStatistics(pitches)
    PVS-->>-VPU: PitchVerificationResult
    
    alt exportJson = true
        VPU->>+PVS: exportToJson(result, outputPath)
        PVS->>+JSON: 書き込み
        JSON-->>-PVS: 完了
        PVS-->>-VPU: 完了
    end
    
    VPU-->>-PVT: result
    PVT->>PVT: _printResults(result)
    
    Note over PVT,JSON: 🎯 同じロジックでカラオケ画面とツールが統一
```

### 🆕 カラオケ画面での統合フロー

```mermaid
sequenceDiagram
    participant KP as KarakokePage
    participant VPU as VerifyPitchUseCase
    participant PVS as PitchVerificationService
    
    KP->>+KP: _loadReferencePitches()
    KP->>+VPU: execute(audioFile, useCache=true, exportJson=false)
    VPU->>+PVS: verifyPitchData(audioFile, true)
    PVS-->>-VPU: PitchVerificationResult
    VPU-->>-KP: result
    
    KP->>KP: setState(result.pitches)
    KP->>KP: デバッグ出力(result.statistics)
    
    Note over KP,PVS: 🎯 DRY原則に従った共通ロジック使用
```

---

## 📂 ファイル構成

### 新規作成ファイル

```
📁 lib/domain/interfaces/
└── 🆕 i_pitch_verification_service.dart

📁 lib/domain/models/
└── 🆕 pitch_verification_result.dart

📁 lib/infrastructure/services/
└── 🆕 pitch_verification_service.dart

📁 lib/application/use_cases/
└── 🆕 verify_pitch_use_case.dart

📁 tools/verification/
└── 🆕 pitch_verification_tool.dart

📁 verification_results/
└── 🆕 *.json (実行時生成)
```

### 更新ファイル

```
📁 lib/presentation/pages/
└── 🔄 karaoke_page.dart (DI・UseCaseパターン適用)

📁 docs/architecture/
└── 🔄 UML_DOCUMENTATION.md (本ドキュメント)
```

---

## ✅ 実装チェックリスト

### Domain層
- [ ] `IPitchVerificationService` インターフェース定義
- [ ] `PitchVerificationResult` モデル作成
- [ ] `PitchStatistics` モデル作成
- [ ] `ComparisonStats` モデル作成

### Infrastructure層
- [ ] `PitchVerificationService` 実装
- [ ] 統計計算ロジック実装
- [ ] JSON出力機能実装
- [ ] 期待範囲判定ロジック実装

### Application層
- [ ] `VerifyPitchUseCase` 作成
- [ ] ファイルパス検証ロジック
- [ ] JSON出力パス生成ロジック

### Tools層
- [ ] `PitchVerificationTool` 作成
- [ ] コマンドライン引数パース
- [ ] 結果表示フォーマット

### Integration
- [ ] `KarakokePage` のDI統合
- [ ] `_loadReferencePitches` のリファクタリング
- [ ] 単体テスト作成
- [ ] 統合テスト作成

---

## 🎯 期待効果

### ✅ 解決される問題
1. **基準ピッチ結果の透明性**: JSON出力による詳細な検証データ
2. **DRY原則の徹底**: カラオケ画面とツールの処理統一
3. **クリーンアーキテクチャ**: 責務分離と依存性注入
4. **テスタビリティ**: モック可能な抽象化

### 📈 向上する品質
1. **デバッグ効率**: 構造化されたデータ出力
2. **保守性**: 単一責任の原則に従った設計
3. **拡張性**: インターフェースベースの疎結合
4. **再利用性**: ユースケースパターンの活用

---

*最終更新: 2025年7月31日 - 基準ピッチ検証ツール強化対応*
*担当者: GitHub Copilot + 開発チーム*