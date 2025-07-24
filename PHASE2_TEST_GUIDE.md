# フェーズ2 ピッチ比較システム - テストガイド

## 概要
このガイドでは、新しく実装されたフェーズ2高精度ピッチ比較システムのテスト方法を説明します。

## 実装された機能

### 1. PitchComparisonService
- **DTWアルゴリズム**: 最適時間アライメントのための動的時間ワーピング
- **セント計算**: 音楽的セント単位のピッチ差分（1200 * log2(f1/f2)）
- **ピッチ安定性**: セグメントスコアリングによる分散分析
- **ビブラート検出**: レート、深度、規則性の分析
- **タイミング精度**: 相互相関ベースのタイミング評価

### 2. 新しいUI要素
- 録音後に表示される**精密ピッチ比較**ボタン
- 複数スコアカテゴリによる包括的結果表示
- 音符アイコン付きビブラート検出インジケーター
- 展開可能な詳細統計セクション

## 手動テスト手順

### 1. 基本機能テスト
1. アプリを起動し楽曲を選択
2. ピッチデータ分析の完了を待機
3. 「録音開始」をタップして録音開始
4. 数秒間歌うまたはハミング
5. 「録音停止」をタップして録音停止
6. 「精密ピッチ比較」ボタンをタップ
7. 詳細結果が表示されることを確認

### 2. Expected Results Display
The detailed comparison should show:
- **総合スコア**: Overall weighted score (0-100)
- **平均セント差**: Average pitch difference in cents
- **ピッチ安定性**: Stability score based on variance
- **タイミング精度**: Timing accuracy score
- **ビブラート情報**: Detection status with rate/depth if found

### 3. Edge Cases to Test
- Empty recording (should show appropriate message)
- Very short recording (should handle gracefully)
- Long recording with varied pitch patterns
- Silent portions in recording

## Algorithm Details

### DTW (Dynamic Time Warping)
```dart
// Creates optimal alignment between reference and singing pitches
// Handles different lengths and timing variations
final alignedPairs = await _performDTWAlignment(cleanedRef, cleanedSing);
```

### Cent Calculation
```dart
// Musical cent conversion: 1200 * log2(f1/f2)
double _pitchToCents(double frequency) {
  const double referenceFreq = 440.0; // A4
  return OCTAVE_CENTS * (math.log(frequency / referenceFreq) / math.ln2);
}
```

### Vibrato Detection
- Analyzes frequency modulation patterns
- Detects rate (4-8 Hz typical range)
- Measures depth (minimum 10 cents)
- Calculates regularity score

### Stability Analysis
- Segments audio into windows
- Calculates variance for each segment
- Identifies unstable regions
- Provides overall stability score

## Data Models

### PitchComparisonResult
- Comprehensive result container
- JSON serialization support
- Statistical summary methods

### AlignedPitchPair
- DTW-aligned reference/singing pitch pairs
- Cent differences and alignment costs
- Time indices for both sequences

## Integration Points

### KaraokePage Integration
- Service instance: `_pitchComparisonService`
- Result storage: `_lastComparisonResult`
- UI method: `_performDetailedComparison()`

### Error Handling
- Graceful handling of empty data
- Informative error messages
- Fallback to basic comparison if needed

## Future Enhancements
- Real-time comparison during recording
- Visual pitch tracking graphs
- Advanced vibrato analysis
- Machine learning-based scoring
- Export comparison results

## Code Organization
```
lib/
├── models/
│   └── pitch_comparison_result.dart    # Data models
├── services/
│   └── pitch_comparison_service.dart   # Core algorithm
└── pages/
    └── karaoke_page.dart               # UI integration
```

## Testing Notes
- Due to Flutter environment limitations, manual testing is recommended
- Unit tests are provided but may need Flutter SDK to run
- Focus on UI responsiveness and result accuracy
- Verify all analysis components appear correctly