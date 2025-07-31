import 'dart:math' as math;
import '../../domain/models/pitch_comparison_result.dart';

/// 高精度ピッチ比較システム（Phase 2）
/// 基準ピッチと歌唱ピッチの詳細比較を行うサービスクラス
class PitchComparisonService {
  static const double semitoneCents = 100.0;
  static const double octaveCents = 1200.0;
  static const double vibratoMinRate = 4.0;
  static const double vibratoMaxRate = 8.0;
  static const double vibratoMinDepth = 20.0;
  static const int timingThresholdMs = 200;
  static const double stabilityThresholdCents = 10.0;

  /// メインの比較処理
  /// DTWアルゴリズムで時間同期を行い、詳細分析を実行
  Future<PitchComparisonResult> compareWithDTW({
    required List<double> referencePitches,
    required List<double> singingPitches,
    double sampleRate = 16000.0,
    double frameLength = 1024.0,
  }) async {
    try {
      // 1. 無効値を除外し、前処理
      final cleanedRef = _preprocessPitches(referencePitches);
      final cleanedSing = _preprocessPitches(singingPitches);

      if (cleanedRef.isEmpty || cleanedSing.isEmpty) {
        return _createEmptyResult();
      }

      // 2. DTWアルゴリズムで時間同期
      final alignedPairs = await _performDTWAlignment(cleanedRef, cleanedSing);

      // 3. セント差分計算
      final centDifferences = _calculateCentDifferences(alignedPairs);

      // 4. ピッチ安定性分析
      final stabilityAnalysis = await _analyzePitchStability(
        singingPitches,
        sampleRate,
        frameLength,
      );

      // 5. ビブラート検出
      final vibratoAnalysis = await _analyzeVibrato(
        singingPitches,
        sampleRate,
        frameLength,
      );

      // 6. タイミング精度評価
      final timingAnalysis = await _analyzeTimingAccuracy(
        alignedPairs,
        sampleRate,
        frameLength,
      );

      // 7. 総合スコア計算
      final overallScore = _calculateOverallScore(
        centDifferences,
        stabilityAnalysis,
        vibratoAnalysis,
        timingAnalysis,
      );

      return PitchComparisonResult(
        overallScore: overallScore,
        centDifferences: centDifferences,
        alignedPitches: alignedPairs,
        stabilityAnalysis: stabilityAnalysis,
        vibratoAnalysis: vibratoAnalysis,
        timingAnalysis: timingAnalysis,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      throw PitchComparisonException('ピッチ比較処理に失敗しました: $e');
    }
  }

  /// DTW（Dynamic Time Warping）アルゴリズムの実装
  Future<List<AlignedPitchPair>> _performDTWAlignment(
    List<double> referencePitches,
    List<double> singingPitches,
  ) async {
    final refLen = referencePitches.length;
    final singLen = singingPitches.length;

    // DTW距離行列の初期化
    final dtwMatrix = List.generate(
      refLen + 1,
      (i) => List.filled(singLen + 1, double.infinity),
    );

    // 初期条件
    dtwMatrix[0][0] = 0.0;

    // DTW行列の計算
    for (int i = 1; i <= refLen; i++) {
      for (int j = 1; j <= singLen; j++) {
        final cost = _calculatePitchDistance(
          referencePitches[i - 1],
          singingPitches[j - 1],
        );

        dtwMatrix[i][j] = cost +
            math.min(
              math.min(dtwMatrix[i - 1][j], dtwMatrix[i][j - 1]),
              dtwMatrix[i - 1][j - 1],
            );
      }
    }

    // バックトラッキングで最適パスを復元
    final alignedPairs = <AlignedPitchPair>[];
    int i = refLen, j = singLen;

    while (i > 0 && j > 0) {
      final refPitch = referencePitches[i - 1];
      final singPitch = singingPitches[j - 1];
      final centDiff = _pitchToCents(singPitch) - _pitchToCents(refPitch);

      alignedPairs.insert(
        0,
        AlignedPitchPair(
          referencePitch: refPitch,
          singingPitch: singPitch,
          centDifference: centDiff,
          referenceIndex: i - 1,
          singingIndex: j - 1,
          alignmentCost: dtwMatrix[i][j],
        ),
      );

      // 最小コストの方向を選択
      final diagonal = dtwMatrix[i - 1][j - 1];
      final up = dtwMatrix[i - 1][j];
      final left = dtwMatrix[i][j - 1];

      if (diagonal <= up && diagonal <= left) {
        i--;
        j--;
      } else if (up <= left) {
        i--;
      } else {
        j--;
      }
    }

    return alignedPairs;
  }

  /// ピッチ間の距離を計算（セント単位）
  double _calculatePitchDistance(double pitch1, double pitch2) {
    if (pitch1 <= 0 || pitch2 <= 0) return 1000.0; // 大きなペナルティ

    final cents1 = _pitchToCents(pitch1);
    final cents2 = _pitchToCents(pitch2);
    return (cents1 - cents2).abs();
  }

  /// 周波数をセントに変換
  /// セント = 1200 * log2(f1/f2)
  double _pitchToCents(double frequency) {
    if (frequency <= 0) return 0.0;
    // A4 (440Hz) を基準とする
    const double referenceFreq = 440.0;
    return octaveCents * (math.log(frequency / referenceFreq) / math.ln2);
  }

  /// アライメント結果からセント差分リストを抽出
  List<double> _calculateCentDifferences(List<AlignedPitchPair> alignedPairs) {
    return alignedPairs.map((pair) => pair.centDifference).toList();
  }

  /// ピッチ安定性分析
  Future<PitchStabilityAnalysis> _analyzePitchStability(
    List<double> pitches,
    double sampleRate,
    double frameLength,
  ) async {
    final validPitches = pitches.where((p) => p > 0).toList();
    
    if (validPitches.length < 3) {
      return const PitchStabilityAnalysis(
        stabilityScore: 0.0,
        pitchVariance: 0.0,
        averageDeviation: 0.0,
        segments: [],
        unstableRegionCount: 0,
      );
    }

    // セント変換
    final centPitches = validPitches.map(_pitchToCents).toList();

    // 統計計算
    final mean = centPitches.reduce((a, b) => a + b) / centPitches.length;
    final variance = centPitches
            .map((c) => math.pow(c - mean, 2))
            .reduce((a, b) => a + b) /
        centPitches.length;
    final standardDeviation = math.sqrt(variance);

    // セグメント分析
    final segments = await _analyzeStabilitySegments(centPitches);
    final unstableCount = segments.where((s) => !s.isStable).length;

    // 安定性スコア（0-100）
    final stabilityScore = math.max(0.0, 100.0 - standardDeviation * 2);

    return PitchStabilityAnalysis(
      stabilityScore: stabilityScore,
      pitchVariance: variance,
      averageDeviation: standardDeviation,
      segments: segments,
      unstableRegionCount: unstableCount,
    );
  }

  /// 安定性セグメント分析
  Future<List<PitchStabilitySegment>> _analyzeStabilitySegments(
    List<double> centPitches,
  ) async {
    const int windowSize = 10; // 分析ウィンドウサイズ
    final segments = <PitchStabilitySegment>[];

    for (int i = 0; i < centPitches.length; i += windowSize ~/ 2) {
      final end = math.min(i + windowSize, centPitches.length);
      final segment = centPitches.sublist(i, end);

      if (segment.length < 3) continue;

      final mean = segment.reduce((a, b) => a + b) / segment.length;
      final variance = segment
              .map((c) => math.pow(c - mean, 2))
              .reduce((a, b) => a + b) /
          segment.length;

      final stabilityScore = math.max(0.0, 100.0 - math.sqrt(variance) * 3);
      final isStable = math.sqrt(variance) < stabilityThresholdCents;

      segments.add(PitchStabilitySegment(
        startIndex: i,
        endIndex: end - 1,
        stabilityScore: stabilityScore,
        isStable: isStable,
      ));
    }

    return segments;
  }

  /// ビブラート分析
  Future<VibratoAnalysis> _analyzeVibrato(
    List<double> pitches,
    double sampleRate,
    double frameLength,
  ) async {
    final validPitches = pitches.where((p) => p > 0).toList();
    
    if (validPitches.length < 20) {
      return const VibratoAnalysis(
        vibratoDetected: false,
        vibratoRate: 0.0,
        vibratoDepth: 0.0,
        vibratoSegments: [],
        vibratoRegularityScore: 0.0,
      );
    }

    // セント変換
    final centPitches = validPitches.map(_pitchToCents).toList();

    // 移動平均でトレンド除去
    final detrended = _removeTrend(centPitches);

    // 周波数分析でビブラート検出
    final vibratoSegments = await _detectVibratoSegments(
      detrended,
      sampleRate / (frameLength / sampleRate),
    );

    final vibratoDetected = vibratoSegments.isNotEmpty;
    final avgRate = vibratoDetected
        ? vibratoSegments.map((s) => s.rate).reduce((a, b) => a + b) /
            vibratoSegments.length
        : 0.0;
    final avgDepth = vibratoDetected
        ? vibratoSegments.map((s) => s.depth).reduce((a, b) => a + b) /
            vibratoSegments.length
        : 0.0;

    // 規則性スコア計算
    final regularityScore = vibratoDetected
        ? _calculateVibratoRegularity(vibratoSegments)
        : 0.0;

    return VibratoAnalysis(
      vibratoDetected: vibratoDetected,
      vibratoRate: avgRate,
      vibratoDepth: avgDepth,
      vibratoSegments: vibratoSegments,
      vibratoRegularityScore: regularityScore,
    );
  }

  /// トレンド除去（移動平均）
  List<double> _removeTrend(List<double> data) {
    const int windowSize = 10;
    final detrended = <double>[];

    for (int i = 0; i < data.length; i++) {
      final start = math.max(0, i - windowSize ~/ 2);
      final end = math.min(data.length, i + windowSize ~/ 2 + 1);
      final window = data.sublist(start, end);
      final average = window.reduce((a, b) => a + b) / window.length;
      detrended.add(data[i] - average);
    }

    return detrended;
  }

  /// ビブラートセグメント検出
  Future<List<VibratoSegment>> _detectVibratoSegments(
    List<double> detrended,
    double frameRate,
  ) async {
    const int minSegmentLength = 20;
    const int windowSize = 40;
    final segments = <VibratoSegment>[];

    for (int i = 0; i < detrended.length; i += windowSize ~/ 2) {
      final end = math.min(i + windowSize, detrended.length);
      if (end - i < minSegmentLength) continue;

      final segment = detrended.sublist(i, end);
      final analysis = _analyzeVibratoInSegment(segment, frameRate);

      if (analysis['isVibrato']) {
        segments.add(VibratoSegment(
          startIndex: i,
          endIndex: end - 1,
          rate: analysis['rate'],
          depth: analysis['depth'],
          regularityScore: analysis['regularity'],
        ));
      }
    }

    return segments;
  }

  /// セグメント内ビブラート分析
  Map<String, dynamic> _analyzeVibratoInSegment(
    List<double> segment,
    double frameRate,
  ) {
    // 簡易FFTの代わりに周期検出を行う
    final rms = math.sqrt(
      segment.map((x) => x * x).reduce((a, b) => a + b) / segment.length,
    );

    // ゼロクロッシング数から周波数推定
    int zeroCrossings = 0;
    for (int i = 1; i < segment.length; i++) {
      if ((segment[i] >= 0) != (segment[i - 1] >= 0)) {
        zeroCrossings++;
      }
    }

    final estimatedRate = (zeroCrossings / 2.0) * frameRate / segment.length;
    final depth = rms * 2.0; // セント単位での深さ近似

    final isVibrato = estimatedRate >= vibratoMinRate &&
        estimatedRate <= vibratoMaxRate &&
        depth >= vibratoMinDepth;

    return {
      'isVibrato': isVibrato,
      'rate': estimatedRate,
      'depth': depth,
      'regularity': isVibrato ? _calculateSegmentRegularity(segment) : 0.0,
    };
  }

  /// セグメント規則性計算
  double _calculateSegmentRegularity(List<double> segment) {
    // 周期の一貫性を評価
    final peaks = _findPeaks(segment);
    if (peaks.length < 3) return 0.0;

    final intervals = <int>[];
    for (int i = 1; i < peaks.length; i++) {
      intervals.add(peaks[i] - peaks[i - 1]);
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals
            .map((interval) => math.pow(interval - avgInterval, 2))
            .reduce((a, b) => a + b) /
        intervals.length;

    return math.max(0.0, 100.0 - math.sqrt(variance) * 10);
  }

  /// ピークを検出
  List<int> _findPeaks(List<double> data) {
    final peaks = <int>[];
    for (int i = 1; i < data.length - 1; i++) {
      if (data[i] > data[i - 1] && data[i] > data[i + 1]) {
        peaks.add(i);
      }
    }
    return peaks;
  }

  /// ビブラート規則性スコア計算
  double _calculateVibratoRegularity(List<VibratoSegment> segments) {
    if (segments.isEmpty) return 0.0;

    final rates = segments.map((s) => s.rate).toList();
    final depths = segments.map((s) => s.depth).toList();

    final avgRate = rates.reduce((a, b) => a + b) / rates.length;
    final avgDepth = depths.reduce((a, b) => a + b) / depths.length;

    final rateVariance = rates
            .map((r) => math.pow(r - avgRate, 2))
            .reduce((a, b) => a + b) /
        rates.length;
    final depthVariance = depths
            .map((d) => math.pow(d - avgDepth, 2))
            .reduce((a, b) => a + b) /
        depths.length;

    return math.max(0.0, 100.0 - (math.sqrt(rateVariance) * 20 + math.sqrt(depthVariance) * 2));
  }

  /// タイミング精度分析
  Future<TimingAccuracyAnalysis> _analyzeTimingAccuracy(
    List<AlignedPitchPair> alignedPairs,
    double sampleRate,
    double frameLength,
  ) async {
    if (alignedPairs.isEmpty) {
      return const TimingAccuracyAnalysis(
        accuracyScore: 0.0,
        averageTimeOffset: 0.0,
        maxTimeOffset: 0.0,
        timingDeviations: [],
        significantDelayCount: 0,
      );
    }

    final timePerFrame = frameLength / sampleRate * 1000.0; // ms

    final timingDeviations = <TimingDeviation>[];
    double totalOffset = 0.0;
    double maxOffset = 0.0;
    int significantDelays = 0;

    for (final pair in alignedPairs) {
      final timeOffset = (pair.singingIndex - pair.referenceIndex) * timePerFrame;
      final offsetAbs = timeOffset.abs();

      timingDeviations.add(TimingDeviation(
        referenceIndex: pair.referenceIndex,
        singingIndex: pair.singingIndex,
        timeOffset: timeOffset,
        isSignificant: offsetAbs > timingThresholdMs,
      ));

      totalOffset += offsetAbs;
      maxOffset = math.max(maxOffset, offsetAbs);

      if (offsetAbs > timingThresholdMs) {
        significantDelays++;
      }
    }

    final averageOffset = totalOffset / alignedPairs.length;
    final accuracyScore = math.max(0.0, 100.0 - averageOffset / 10.0);

    return TimingAccuracyAnalysis(
      accuracyScore: accuracyScore,
      averageTimeOffset: averageOffset,
      maxTimeOffset: maxOffset,
      timingDeviations: timingDeviations,
      significantDelayCount: significantDelays,
    );
  }

  /// 総合スコア計算
  double _calculateOverallScore(
    List<double> centDifferences,
    PitchStabilityAnalysis stabilityAnalysis,
    VibratoAnalysis vibratoAnalysis,
    TimingAccuracyAnalysis timingAnalysis,
  ) {
    // ピッチ精度スコア（60%）
    final validCentDiffs = centDifferences.where((diff) => diff.isFinite).toList();
    final avgCentDiff = validCentDiffs.isEmpty
        ? 100.0
        : validCentDiffs.reduce((a, b) => a + b.abs()) / validCentDiffs.length;
    final pitchScore = math.max(0.0, 100.0 - avgCentDiff / 2.0);

    // 安定性スコア（20%）
    final stabilityScore = stabilityAnalysis.stabilityScore;

    // タイミングスコア（20%）
    final timingScore = timingAnalysis.accuracyScore;

    // 重み付き総合スコア
    return pitchScore * 0.6 + stabilityScore * 0.2 + timingScore * 0.2;
  }

  /// ピッチデータの前処理
  List<double> _preprocessPitches(List<double> pitches) {
    return pitches.where((p) => p > 0 && p.isFinite).toList();
  }

  /// 空の結果を作成
  PitchComparisonResult _createEmptyResult() {
    return PitchComparisonResult(
      overallScore: 0.0,
      centDifferences: [],
      alignedPitches: [],
      stabilityAnalysis: const PitchStabilityAnalysis(
        stabilityScore: 0.0,
        pitchVariance: 0.0,
        averageDeviation: 0.0,
        segments: [],
        unstableRegionCount: 0,
      ),
      vibratoAnalysis: const VibratoAnalysis(
        vibratoDetected: false,
        vibratoRate: 0.0,
        vibratoDepth: 0.0,
        vibratoSegments: [],
        vibratoRegularityScore: 0.0,
      ),
      timingAnalysis: const TimingAccuracyAnalysis(
        accuracyScore: 0.0,
        averageTimeOffset: 0.0,
        maxTimeOffset: 0.0,
        timingDeviations: [],
        significantDelayCount: 0,
      ),
      analyzedAt: DateTime.now(),
    );
  }

  /// シンプルな比較処理（DTWなし）
  Future<PitchComparisonResult> compareSimple({
    required List<double> referencePitches,
    required List<double> singingPitches,
  }) async {
    final cleanedRef = _preprocessPitches(referencePitches);
    final cleanedSing = _preprocessPitches(singingPitches);

    if (cleanedRef.isEmpty || cleanedSing.isEmpty) {
      return _createEmptyResult();
    }

    // シンプルな1対1対応
    final minLength = math.min(cleanedRef.length, cleanedSing.length);
    final alignedPairs = <AlignedPitchPair>[];
    final centDifferences = <double>[];

    for (int i = 0; i < minLength; i++) {
      final centDiff = _pitchToCents(cleanedSing[i]) - _pitchToCents(cleanedRef[i]);
      centDifferences.add(centDiff);

      alignedPairs.add(AlignedPitchPair(
        referencePitch: cleanedRef[i],
        singingPitch: cleanedSing[i],
        centDifference: centDiff,
        referenceIndex: i,
        singingIndex: i,
        alignmentCost: centDiff.abs(),
      ));
    }

    // 簡易分析
    final stabilityAnalysis = await _analyzePitchStability(singingPitches, 16000, 1024);
    final vibratoAnalysis = await _analyzeVibrato(singingPitches, 16000, 1024);
    const timingAnalysis = TimingAccuracyAnalysis(
      accuracyScore: 100.0, // シンプル版では完全同期と仮定
      averageTimeOffset: 0.0,
      maxTimeOffset: 0.0,
      timingDeviations: [],
      significantDelayCount: 0,
    );

    final overallScore = _calculateOverallScore(
      centDifferences,
      stabilityAnalysis,
      vibratoAnalysis,
      timingAnalysis,
    );

    return PitchComparisonResult(
      overallScore: overallScore,
      centDifferences: centDifferences,
      alignedPitches: alignedPairs,
      stabilityAnalysis: stabilityAnalysis,
      vibratoAnalysis: vibratoAnalysis,
      timingAnalysis: timingAnalysis,
      analyzedAt: DateTime.now(),
    );
  }

  // === リアルタイムスコア計算機能 (Phase 3) ===

  /// リアルタイムピッチスコア計算
  /// 単一ピッチペアの即座の比較とスコア計算
  static RealtimeScoreResult calculateRealtimeScore(
    double detectedPitch,
    double referencePitch,
  ) {
    if (detectedPitch <= 0 || referencePitch <= 0) {
      return RealtimeScoreResult.invalid();
    }

    final centsDiff = _calculateCentsDifference(detectedPitch, referencePitch);
    final score = _calculateScoreFromCents(centsDiff.abs());
    final accuracy = _getAccuracyLevel(centsDiff.abs());

    return RealtimeScoreResult(
      detectedPitch: detectedPitch,
      referencePitch: referencePitch,
      centsDifference: centsDiff,
      score: score,
      accuracy: accuracy,
      isValid: true,
    );
  }

  /// 複数フレームの累積スコア計算
  static CumulativeScoreResult calculateCumulativeScore(
    List<RealtimeScoreResult> scoreHistory,
    {int maxHistoryLength = 100}
  ) {
    final validScores = scoreHistory.where((s) => s.isValid).toList();
    if (validScores.isEmpty) {
      return CumulativeScoreResult.empty();
    }

    // 最近のスコアに重みを付けて平均計算
    final weightedScores = <double>[];
    final weights = <double>[];
    
    for (int i = 0; i < validScores.length; i++) {
      final weight = _getTimeWeight(i, validScores.length);
      weightedScores.add(validScores[i].score * weight);
      weights.add(weight);
    }

    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    final averageScore = totalWeight > 0 
        ? weightedScores.fold(0.0, (a, b) => a + b) / totalWeight
        : 0.0;

    final maxScore = validScores.map((s) => s.score).reduce(math.max);
    final minScore = validScores.map((s) => s.score).reduce(math.min);
    
    // 安定性計算
    final recentScores = validScores.take(20).map((s) => s.score).toList();
    final stability = _calculateScoreStability(recentScores);

    return CumulativeScoreResult(
      averageScore: averageScore,
      maxScore: maxScore,
      minScore: minScore,
      validCount: validScores.length,
      totalCount: scoreHistory.length,
      stability: stability,
      trend: _calculateScoreTrend(validScores),
    );
  }

  /// セント差からスコアを計算
  static double _calculateScoreFromCents(double centsDiff) {
    if (centsDiff <= 10.0) return 100.0; // Perfect
    if (centsDiff <= 25.0) return 100.0 - (centsDiff - 10.0) * 1.0; // 100->85
    if (centsDiff <= 50.0) return 85.0 - (centsDiff - 25.0) * 0.6; // 85->70
    if (centsDiff <= 100.0) return 70.0 - (centsDiff - 50.0) * 0.6; // 70->40
    return math.max(0.0, 40.0 - (centsDiff - 100.0) * 0.4); // 40->0
  }

  /// 正確性レベルを判定
  static ScoreAccuracy _getAccuracyLevel(double centsDiff) {
    if (centsDiff <= 10.0) return ScoreAccuracy.perfect;
    if (centsDiff <= 25.0) return ScoreAccuracy.excellent;
    if (centsDiff <= 50.0) return ScoreAccuracy.good;
    if (centsDiff <= 100.0) return ScoreAccuracy.fair;
    return ScoreAccuracy.poor;
  }

  /// 時間重みを計算（最近のデータほど重要）
  static double _getTimeWeight(int index, int totalLength) {
    final normalizedIndex = index / math.max(1, totalLength - 1);
    return 0.5 + 0.5 * normalizedIndex; // 0.5 to 1.0
  }

  /// スコアの安定性を計算
  static double _calculateScoreStability(List<double> scores) {
    if (scores.length < 3) return 0.0;
    
    final average = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores
        .map((s) => math.pow(s - average, 2))
        .reduce((a, b) => a + b) / scores.length;
    final stdDev = math.sqrt(variance);
    
    // 標準偏差が小さいほど安定性が高い
    return math.max(0.0, 100.0 - stdDev * 2.0);
  }

  /// スコアトレンドを計算
  static ScoreTrend _calculateScoreTrend(List<RealtimeScoreResult> scores) {
    if (scores.length < 10) return ScoreTrend.stable;
    
    final recentStartIndex = math.max(0, scores.length - 10);
    final recent = scores.skip(recentStartIndex).map((s) => s.score).toList();
    final olderStartIndex = math.max(0, scores.length - 20);
    final older = scores.skip(olderStartIndex)
                      .take(10).map((s) => s.score).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    final diff = recentAvg - olderAvg;
    
    if (diff > 5.0) return ScoreTrend.improving;
    if (diff < -5.0) return ScoreTrend.declining;
    return ScoreTrend.stable;
  }

  /// セント差を計算する内部メソッド
  static double _calculateCentsDifference(double freq1, double freq2) {
    return 1200.0 * (math.log(freq1 / freq2) / math.ln2);
  }
}

/// リアルタイムスコア結果
class RealtimeScoreResult {
  final double detectedPitch;
  final double referencePitch;
  final double centsDifference;
  final double score;
  final ScoreAccuracy accuracy;
  final bool isValid;

  const RealtimeScoreResult({
    required this.detectedPitch,
    required this.referencePitch,
    required this.centsDifference,
    required this.score,
    required this.accuracy,
    required this.isValid,
  });

  factory RealtimeScoreResult.invalid() {
    return const RealtimeScoreResult(
      detectedPitch: 0.0,
      referencePitch: 0.0,
      centsDifference: 0.0,
      score: 0.0,
      accuracy: ScoreAccuracy.poor,
      isValid: false,
    );
  }
}

/// 累積スコア結果
class CumulativeScoreResult {
  final double averageScore;
  final double maxScore;
  final double minScore;
  final int validCount;
  final int totalCount;
  final double stability;
  final ScoreTrend trend;

  const CumulativeScoreResult({
    required this.averageScore,
    required this.maxScore,
    required this.minScore,
    required this.validCount,
    required this.totalCount,
    required this.stability,
    required this.trend,
  });

  factory CumulativeScoreResult.empty() {
    return const CumulativeScoreResult(
      averageScore: 0.0,
      maxScore: 0.0,
      minScore: 0.0,
      validCount: 0,
      totalCount: 0,
      stability: 0.0,
      trend: ScoreTrend.stable,
    );
  }

  double get validRatio => totalCount > 0 ? validCount / totalCount : 0.0;
}

/// スコア正確性レベル
enum ScoreAccuracy {
  perfect('完璧', 100),
  excellent('素晴らしい', 90),
  good('良い', 75),
  fair('まあまあ', 50),
  poor('要改善', 25);

  const ScoreAccuracy(this.label, this.threshold);
  final String label;
  final int threshold;
}

/// スコアトレンド
enum ScoreTrend {
  improving('上昇中'),
  declining('下降中'),
  stable('安定');

  const ScoreTrend(this.label);
  final String label;
}

/// ピッチ比較に関する例外クラス
class PitchComparisonException implements Exception {
  final String message;
  const PitchComparisonException(this.message);

  @override
  String toString() => 'PitchComparisonException: $message';
}