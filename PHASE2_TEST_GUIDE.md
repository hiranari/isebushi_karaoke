# Phase 2 Pitch Comparison System - Test Guide

## Overview
This guide explains how to test the newly implemented Phase 2 high-precision pitch comparison system.

## Features Implemented

### 1. PitchComparisonService
- **DTW Algorithm**: Dynamic Time Warping for optimal time alignment
- **Cent Calculation**: Musical cent-based pitch difference (1200 * log2(f1/f2))
- **Pitch Stability**: Variance analysis with segment scoring
- **Vibrato Detection**: Rate, depth, and regularity analysis
- **Timing Accuracy**: Cross-correlation based timing evaluation

### 2. New UI Elements
- **精密ピッチ比較** button appears after recording
- Comprehensive results display with multiple score categories
- Vibrato detection indicator with musical note icons
- Expandable detailed statistics section

## Manual Testing Steps

### 1. Basic Functionality Test
1. Launch the app and select a song
2. Wait for pitch data analysis to complete
3. Tap "録音開始" to start recording
4. Sing or hum for a few seconds
5. Tap "録音停止" to stop recording
6. Tap "精密ピッチ比較" button
7. Verify detailed results appear

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