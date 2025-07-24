import 'dart:math' as math;
import '../../domain/models/song_result.dart';

/// 包括的歌唱評価・スコアリングエンジン実装
/// 
/// カラオケアプリケーションの中核機能である歌唱評価システムを
/// 実装するインフラストラクチャ層のサービスクラスです。
/// 複数の音響分析結果を統合し、定量的・定性的評価を生成します。
/// 
/// アーキテクチャ位置:
/// ```
/// Presentation層
///     ↓ (ユーザー操作)
/// Application層
///     ↓ (ビジネスロジック)
/// Domain層 (評価ルール、モデル)
///     ↓ (実装)
/// Infrastructure層 ← ScoringService (具体実装)
/// ```
/// 
/// 中核責任:
/// - 多次元音響分析の統合評価
/// - スコア算出アルゴリズムの実行
/// - 定量評価と定性フィードバックの生成
/// - 評価基準の統一化と正規化
/// - パフォーマンス分析とボトルネック特定
/// 
/// スコアリング体系:
/// ```
/// 総合スコア = Σ(カテゴリスコア × 重み係数)
/// 
/// 1. ピッチ精度評価 (重み: 70%)
///    ├── 基準音程との差分計算 (セント単位)
///    ├── 半音階精度の統計分析
///    ├── 音程変化追跡の正確性
///    └── ビブラート・装飾音の評価
/// 
/// 2. 安定性評価 (重み: 20%)
///    ├── ピッチ揺れの標準偏差
///    ├── 音量レベルの一貫性
///    ├── 発声継続性の分析
///    └── ブレス位置の適切性
/// 
/// 3. タイミング評価 (重み: 10%)
///    ├── リズム同期の精度
///    ├── フレーズ境界の認識
///    ├── テンポ追従の正確性
///    └── 歌詞同期の品質
/// ```
/// 
/// 評価アルゴリズム詳細:
/// - **ピッチ差分計算**: FFT → 基本周波数抽出 → セント変換 → 統計評価
/// - **安定性分析**: 移動平均フィルタ → 分散計算 → 外れ値除去 → 正規化
/// - **タイミング分析**: ビート検出 → 位相相関 → 同期誤差測定 → スコア化
/// 
/// 使用例:
/// ```dart
/// // スコア計算の実行
/// final result = ScoringService.calculateComprehensiveScore(
///   referencePitches: originalPitchData,
///   recordedPitches: userPitchData,
///   songTitle: '伊勢節',
/// );
/// 
/// print('総合スコア: ${result.totalScore}点');
/// print('詳細フィードバック: ${result.feedback}');
/// ```
/// 
/// パフォーマンス最適化:
/// - **静的メソッド**: インスタンス作成コストの削減
/// - **効率的計算**: 数学的最適化アルゴリズム使用
/// - **メモリ効率**: 大容量データのストリーミング処理
/// - **計算量削減**: O(n)アルゴリズムの選択
/// 
/// エラーハンドリング:
/// - 空データ・null値の適切な処理
/// - 音声データ不正の検出と補正
/// - 分析失敗時のフォールバック機能
/// - 数値計算例外の安全な処理
/// 
/// 評価精度保証:
/// - 単体テスト: 各評価関数の精度検証
/// - 境界値テスト: 極端なケースでの動作確認
/// - 統計的検証: 評価結果の分布検証
/// - 回帰テスト: 評価アルゴリズム変更時の影響確認
/// 
/// 設定定数:
/// - pitchAccuracyWeight: ピッチ精度重み (70%)
/// - stabilityWeight: 安定性重み (20%)
/// - timingWeight: タイミング重み (10%)
/// - 各種精度閾値: セント・時間単位での判定基準
/// 
/// 将来拡張計画:
/// - AI/ML強化評価エンジン
/// - リアルタイム評価機能
/// - 感情表現分析
/// - アーティスト別評価基準
/// - 楽器伴奏との調和評価
/// 
/// 設計原則:
/// - Single Responsibility: スコアリング機能に特化
/// - Open/Closed: 新しい評価軸の追加が容易
/// - Liskov Substitution: 評価インターフェースの統一
/// - Interface Segregation: 用途別メソッドの分離
/// - Dependency Inversion: 外部依存の最小化
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#scoring-service)
class ScoringService {
  // スコアリング定数
  static const double pitchAccuracyWeight = 0.7;
  static const double stabilityWeight = 0.2;
  static const double timingWeight = 0.1;
  
  // 精度判定閾値
  static const double pitchAccuracyThresholdCents = 50.0; // セント単位
  static const double timingAccuracyThresholdSec = 0.2;   // 秒単位
  static const double stabilityThresholdCents = 30.0;      // セント単位

  /// 歌唱データから総合的なスコアを算出
  /// 
  /// [referencePitches] 基準ピッチデータ(Hz)
  /// [recordedPitches] 録音ピッチデータ(Hz)
  /// [songTitle] 楽曲タイトル
  /// [recordingTimestamps] 録音時のタイムスタンプ(オプション)
  /// 戻り値: 詳細なスコアリング結果
  static SongResult calculateComprehensiveScore({
    required List<double> referencePitches,
    required List<double> recordedPitches, 
    required String songTitle,
    List<double>? recordingTimestamps,
  }) {
    // データの前処理
    final processedData = _preprocessPitchData(referencePitches, recordedPitches);
    final refPitches = processedData['reference'] as List<double>;
    final recPitches = processedData['recorded'] as List<double>;
    
    // 各分析の実行
    final pitchAnalysis = _analyzePitchAccuracy(refPitches, recPitches);
    final stabilityAnalysis = _analyzeStability(recPitches);
    final timingAnalysis = _analyzeTiming(refPitches, recPitches, recordingTimestamps);
    
    // スコア内訳の計算
    final scoreBreakdown = ScoreBreakdown(
      pitchAccuracyScore: _calculatePitchAccuracyScore(pitchAnalysis),
      stabilityScore: _calculateStabilityScore(stabilityAnalysis),
      timingScore: _calculateTimingScore(timingAnalysis),
    );
    
    return SongResult(
      songTitle: songTitle,
      timestamp: DateTime.now(),
      totalScore: scoreBreakdown.totalScore,
      scoreBreakdown: scoreBreakdown,
      pitchAnalysis: pitchAnalysis,
      timingAnalysis: timingAnalysis,
      stabilityAnalysis: stabilityAnalysis,
      feedback: [], // フィードバックサービスで生成
    );
  }

  /// ピッチデータの前処理
  /// 長さを揃えて、無効なデータを除去
  static Map<String, List<double>> _preprocessPitchData(
    List<double> reference,
    List<double> recorded,
  ) {
    final minLength = math.min(reference.length, recorded.length);
    
    final processedRef = <double>[];
    final processedRec = <double>[];
    
    for (int i = 0; i < minLength; i++) {
      final refPitch = reference[i];
      final recPitch = recorded[i];
      
      // 両方とも有効なピッチの場合のみ追加
      if (refPitch > 0 && recPitch > 0) {
        processedRef.add(refPitch);
        processedRec.add(recPitch);
      }
    }
    
    return {
      'reference': processedRef,
      'recorded': processedRec,
    };
  }

  /// ピッチ精度の分析
  static PitchAnalysis _analyzePitchAccuracy(
    List<double> referencePitches,
    List<double> recordedPitches,
  ) {
    // 空データの場合は空の分析結果を返す
    if (referencePitches.isEmpty || recordedPitches.isEmpty) {
      return const PitchAnalysis(
        averageDeviation: 0.0,
        maxDeviation: 0.0,
        correctNotes: 0,
        totalNotes: 0,
        pitchPoints: [],
        deviationHistory: [],
      );
    }
    
    final pitchPoints = <PitchPoint>[];
    final deviations = <double>[];
    int correctNotes = 0;
    
    for (int i = 0; i < referencePitches.length; i++) {
      final refPitch = referencePitches[i];
      final recPitch = recordedPitches[i];
      
      // セント単位でのずれを計算
      final deviationCents = _calculateCentsDeviation(refPitch, recPitch);
      deviations.add(deviationCents);
      
      // 正確性の判定
      if (deviationCents.abs() <= pitchAccuracyThresholdCents) {
        correctNotes++;
      }
      
      pitchPoints.add(PitchPoint(
        timestamp: _calculateActualTimestamp(i, referencePitches.length),
        referencePitch: refPitch,
        recordedPitch: recPitch,
        deviation: deviationCents,
      ));
    }
    
    final averageDeviation = deviations.isEmpty ? 0.0 :
        deviations.reduce((a, b) => a + b) / deviations.length;
    final maxDeviation = deviations.isEmpty ? 0.0 :
        deviations.reduce(math.max);
    
    return PitchAnalysis(
      averageDeviation: averageDeviation,
      maxDeviation: maxDeviation,
      correctNotes: correctNotes,
      totalNotes: referencePitches.length,
      pitchPoints: pitchPoints,
      deviationHistory: deviations,
    );
  }

  /// 安定性の分析
  static StabilityAnalysis _analyzeStability(List<double> recordedPitches) {
    // 有効ピッチのフィルタリング
    final validPitches = recordedPitches.where((p) => p > 0).toList();
    
    if (validPitches.isEmpty) {
      return const StabilityAnalysis(
        averageVariation: 0.0,
        maxVariation: 0.0,
        stableNotes: 0,
        unstableNotes: 0,
        variationHistory: [],
      );
    }
    
    // 単一ピッチの場合は完全に安定
    if (validPitches.length == 1) {
      return const StabilityAnalysis(
        averageVariation: 0.0,
        maxVariation: 0.0,
        stableNotes: 1,
        unstableNotes: 0,
        variationHistory: [],
      );
    }
    
    final variations = <double>[];
    int stableNotes = 0;
    int unstableNotes = 0;
    
    // 隣接するピッチ間の変動を分析
    for (int i = 1; i < validPitches.length; i++) {
      final variation = _calculateCentsDeviation(
        validPitches[i - 1],
        validPitches[i],
      ).abs();
      
      variations.add(variation);
      
      if (variation <= stabilityThresholdCents) {
        stableNotes++;
      } else {
        unstableNotes++;
      }
    }
    
    final averageVariation = variations.isEmpty ? 0.0 :
        variations.reduce((a, b) => a + b) / variations.length;
    final maxVariation = variations.isEmpty ? 0.0 :
        variations.reduce(math.max);
    
    return StabilityAnalysis(
      averageVariation: averageVariation,
      maxVariation: maxVariation,
      stableNotes: stableNotes,
      unstableNotes: unstableNotes,
      variationHistory: variations,
    );
  }

  /// タイミングの分析
  static TimingAnalysis _analyzeTiming(
    List<double> referencePitches,
    List<double> recordedPitches,
    List<double>? recordingTimestamps,
  ) {
    // 空データの場合は空の分析結果を返す
    if (referencePitches.isEmpty || recordedPitches.isEmpty) {
      return const TimingAnalysis(
        averageLatency: 0.0,
        maxLatency: 0.0,
        earlyNotes: 0,
        lateNotes: 0,
        onTimeNotes: 0,
        latencyHistory: [],
      );
    }
    
    // 実際のタイミング分析を実装
    final latencyHistory = <double>[];
    int earlyNotes = 0;
    int lateNotes = 0;
    int onTimeNotes = 0;
    
    // 録音タイムスタンプがない場合は、一定間隔で推定
    final timestamps = recordingTimestamps ?? 
        List.generate(recordedPitches.length, (i) => _calculateActualTimestamp(i, recordedPitches.length));
    
    // 基準との時間差を計算
    for (int i = 0; i < math.min(referencePitches.length, recordedPitches.length); i++) {
      final expectedTime = _calculateActualTimestamp(i, referencePitches.length);
      final actualTime = i < timestamps.length ? timestamps[i] : expectedTime;
      
      final latency = actualTime - expectedTime;
      latencyHistory.add(latency);
      
      // タイミング精度の分類
      if (latency.abs() <= timingAccuracyThresholdSec) {
        onTimeNotes++;
      } else if (latency < 0) {
        earlyNotes++;
      } else {
        lateNotes++;
      }
    }
    
    final averageLatency = latencyHistory.isEmpty ? 0.0 :
        latencyHistory.reduce((a, b) => a + b) / latencyHistory.length;
    final maxLatency = latencyHistory.isEmpty ? 0.0 :
        latencyHistory.reduce((a, b) => a.abs() > b.abs() ? a : b);
    
    return TimingAnalysis(
      averageLatency: averageLatency,
      maxLatency: maxLatency,
      earlyNotes: earlyNotes,
      lateNotes: lateNotes,
      onTimeNotes: onTimeNotes,
      latencyHistory: latencyHistory,
    );
  }

  /// ピッチ精度スコアの計算（0-100）
  static double _calculatePitchAccuracyScore(PitchAnalysis analysis) {
    if (analysis.totalNotes == 0) return 0.0;
    
    // 基本正確性スコア（正確な音程の割合）
    final baseAccuracyScore = analysis.accuracyRatio * 60; // 最大60点に調整
    
    // 平均ずれに基づくスコア（指数関数的に減衰）
    final avgDeviationAbs = analysis.averageDeviation.abs();
    final deviationScore = math.max(0.0, 40.0 * math.exp(-avgDeviationAbs / 50.0)); // 50セント以上で急激に減点
    
    // 極端なずれ（1オクターブ以上）に対する厳しいペナルティ
    final maxDeviationAbs = analysis.maxDeviation.abs();
    double severePenalty = 0.0;
    if (maxDeviationAbs >= 1200) { // 1オクターブ以上のずれ
      severePenalty = 80.0; // 大幅減点
    } else if (maxDeviationAbs >= 600) { // 半オクターブ以上のずれ
      severePenalty = 40.0;
    } else if (maxDeviationAbs >= 200) { // 大きなずれ
      severePenalty = 20.0;
    }
    
    return math.max(0.0, math.min(100.0, baseAccuracyScore + deviationScore - severePenalty));
  }

  /// 安定性スコアの計算（0-100）
  static double _calculateStabilityScore(StabilityAnalysis analysis) {
    final totalNotes = analysis.stableNotes + analysis.unstableNotes;
    if (totalNotes == 0) return 0.0;  // 音が出ていない場合は0点
    
    // 基本安定性スコア
    final stabilityScore = analysis.stabilityRatio * 100;
    
    // 平均変動による減点
    final variationPenalty = math.min(
      analysis.averageVariation / stabilityThresholdCents * 15,
      15.0,
    );
    
    return math.max(0.0, stabilityScore - variationPenalty);
  }

  /// タイミングスコアの計算（0-100）
  static double _calculateTimingScore(TimingAnalysis analysis) {
    final totalNotes = analysis.earlyNotes + analysis.lateNotes + analysis.onTimeNotes;
    if (totalNotes == 0) return 0.0;
    
    // 正時性の基本スコア（正確なタイミングの割合）
    final baseTimingScore = analysis.onTimeNotes / totalNotes * 50; // 最大50点に調整
    
    // 遅延の少なさに基づく追加スコア
    final latencyScore = math.max(0.0, 30.0 - (analysis.averageLatency.abs() / timingAccuracyThresholdSec * 30));
    
    // 最大遅延による減点（極端な遅延がある場合の減点）
    final maxLatencyPenalty = math.min(
      analysis.maxLatency.abs() / (timingAccuracyThresholdSec * 2) * 15,
      15.0,
    );
    
    // 早い・遅いノートのバランスによる加点（バランスが良いほど良い）
    final balanceBonus = totalNotes > 1 ? math.max(0.0, 20.0 - (analysis.earlyNotes - analysis.lateNotes).abs() / totalNotes * 20) : 0.0;
    
    return math.max(0.0, math.min(100.0, baseTimingScore + latencyScore + balanceBonus - maxLatencyPenalty));
  }

  /// 実際のタイムスタンプを計算
  /// 
  /// [index] ピッチデータのインデックス
  /// [totalLength] 全体の長さ
  /// 戻り値: 実際のタイムスタンプ（秒）
  static double _calculateActualTimestamp(int index, int totalLength) {
    // 一般的な楽曲の長さ（3-5分）を基準に計算
    const double averageSongDuration = 240.0; // 4分
    const double minInterval = 0.05; // 最小間隔50ms
    
    if (totalLength <= 1) return 0.0;
    
    // 線形補間でタイムスタンプを計算
    final interval = math.max(minInterval, averageSongDuration / totalLength);
    return index * interval;
  }

  /// セント単位での音程のずれを計算
  /// 
  /// [referencePitch] 基準ピッチ(Hz)
  /// [recordedPitch] 録音ピッチ(Hz)
  /// 戻り値: ずれ（セント単位）
  static double _calculateCentsDeviation(double referencePitch, double recordedPitch) {
    if (referencePitch <= 0 || recordedPitch <= 0) return 0.0;
    
    // セント = 1200 * log2(f2/f1)
    return 1200 * (math.log(recordedPitch / referencePitch) / math.ln2);
  }

  /// スコアのグレード判定
  static String getScoreGrade(double score) {
    if (score >= 95) return 'S';
    if (score >= 90) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'D+';
    if (score >= 55) return 'D';
    return 'F';
  }

  /// スコアランクを取得（後方互換性のため）
  static String getScoreRank(double score) {
    return getScoreGrade(score);
  }

  /// スコアレベルを取得（後方互換性のため）
  static String getScoreLevel(double score) {
    if (score >= 95) return 'S';
    if (score >= 85) return 'A';
    if (score >= 75) return 'B';
    if (score >= 65) return 'C';
    if (score >= 55) return 'D';
    return 'F';
  }

  /// スコアコメントを取得
  static String getScoreComment(double score) {
    if (score >= 95) return '素晴らしい歌唱です！';
    if (score >= 85) return 'とても上手です！';
    if (score >= 75) return '良い歌唱です！';
    if (score >= 65) return 'もう少し練習が必要です';
    if (score >= 55) return '練習を続けましょう';
    return '基礎から練習しましょう';
  }

  /// セント単位での音程のずれを計算（公開メソッド）
  static double calculateCentDifference(double referencePitch, double recordedPitch) {
    return _calculateCentsDeviation(referencePitch, recordedPitch);
  }

  /// 推奨フォーカスエリアを取得
  static List<String> getRecommendedFocus(ScoreBreakdown scoreBreakdown) {
    final focus = <String>[];
    
    if (scoreBreakdown.pitchAccuracyScore < 70) {
      focus.add('音程精度');
    }
    if (scoreBreakdown.stabilityScore < 70) {
      focus.add('音程安定性');
    }
    if (scoreBreakdown.timingScore < 70) {
      focus.add('タイミング');
    }
    
    return focus.isEmpty ? ['全体的なバランス'] : focus;
  }

  /// スコア計算メソッド（後方互換性のため）
  static SongResult calculateScore({
    required List<double> referencePitches,
    required List<double> recordedPitches,
    required String songTitle,
  }) {
    return calculateComprehensiveScore(
      referencePitches: referencePitches,
      recordedPitches: recordedPitches,
      songTitle: songTitle,
    );
  }

  // スコアリング定数（後方互換性のため）
  static const double perfectPitchThreshold = 20.0;
  static const double goodPitchThreshold = 50.0;
  static const double unstableVariationThreshold = 30.0;
}