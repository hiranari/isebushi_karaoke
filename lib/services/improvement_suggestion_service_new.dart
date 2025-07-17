import '../models/comprehensive_score.dart';
import '../models/improvement_suggestion.dart';

/// 改善提案生成を担当するサービスクラス
/// Phase 3: 各スコアごとに動的に改善提案を生成
class ImprovementSuggestionService {
  /// 改善提案を生成
  static List<ImprovementSuggestion> generateSuggestions({
    required ComprehensiveScore score,
    required Map<String, double> statistics,
  }) {
    List<ImprovementSuggestion> suggestions = [];

    // 音程精度に関する提案
    suggestions.addAll(_generatePitchSuggestions(score.pitchAccuracy, statistics));

    // 安定性に関する提案
    suggestions.addAll(_generateStabilitySuggestions(score.stability, statistics));

    // タイミングに関する提案
    suggestions.addAll(_generateTimingSuggestions(score.timing, statistics));

    // 優先度順にソート
    suggestions.sort((a, b) => a.priority.compareTo(b.priority));

    return suggestions;
  }

  /// 音程精度の改善提案を生成
  static List<ImprovementSuggestion> _generatePitchSuggestions(
    double pitchScore,
    Map<String, double> statistics,
  ) {
    List<ImprovementSuggestion> suggestions = [];

    if (pitchScore < 60) {
      suggestions.add(const ImprovementSuggestion(
        category: 'pitch',
        title: '基本的な音程練習',
        description: '楽器と一緒に単音での発声練習から始めましょう。ピアノやアプリで正確な音程を確認しながら、少しずつ音程感覚を身につけていきます。',
        priority: 1,
        specificAdvice: '音階練習で基本的な音感を身につけ、ピアノと合わせて発声練習を行い、毎日少しずつでも継続的に練習しましょう。',
      ));

      suggestions.add(const ImprovementSuggestion(
        category: 'pitch',
        title: '聴音練習',
        description: '正確な音程を聞き取る耳を鍛えましょう。楽曲を何度も聞いて、メロディーラインを正確に覚えることが重要です。',
        priority: 2,
        specificAdvice: '楽曲のメロディーラインを集中して聞き、楽器と合わせて確認し、音程の幅を意識して聞き分ける練習をしましょう。',
      ));
    } else if (pitchScore < 75) {
      suggestions.add(const ImprovementSuggestion(
        category: 'pitch',
        title: '音程幅の練習',
        description: '基本的な音程は取れているので、音程幅（インターバル）の練習を重点的に行いましょう。3度、5度、オクターブなどの練習が効果的です。',
        priority: 2,
        specificAdvice: '音程幅の練習を通じて、より正確な音程感覚を身につけ、楽曲全体での音程精度を向上させましょう。',
      ));
    } else if (pitchScore < 85) {
      suggestions.add(const ImprovementSuggestion(
        category: 'pitch',
        title: '微細な音程調整',
        description: '大まかな音程は取れているので、より細かい音程の調整を意識しましょう。楽器との比較練習で精度を高めていきます。',
        priority: 3,
        specificAdvice: '楽器と比較しながら微細な音程の調整を行い、より高い精度で歌えるよう練習しましょう。',
      ));
    }

    // 統計情報に基づく具体的な提案
    final meanError = statistics['meanAbsoluteError'] ?? 0.0;
    if (meanError > 50) {
      suggestions.add(const ImprovementSuggestion(
        category: 'pitch',
        title: '大幅な音程修正',
        description: '基準音程から大きくずれている傾向があります。楽曲のキーが自分の音域に合っているか確認し、必要に応じてキー調整を検討しましょう。',
        priority: 1,
        specificAdvice: '自分の音域に合ったキーで練習し、無理のない範囲で歌うことから始めましょう。',
      ));
    }

    final perfectRatio = statistics['perfectPitchRatio'] ?? 0.0;
    if (perfectRatio < 0.3) {
      suggestions.add(const ImprovementSuggestion(
        category: 'pitch',
        title: '正確な音程の維持',
        description: '正確な音程で歌えている部分を増やしましょう。一つ一つの音を丁寧に歌うことを心がけ、急がずにメロディーを追いかけましょう。',
        priority: 2,
        specificAdvice: '一つ一つの音を丁寧に歌い、急がずにメロディーをしっかりと追いかけて正確性を高めましょう。',
      ));
    }

    return suggestions;
  }

  /// 安定性の改善提案を生成
  static List<ImprovementSuggestion> _generateStabilitySuggestions(
    double stabilityScore,
    Map<String, double> statistics,
  ) {
    List<ImprovementSuggestion> suggestions = [];

    if (stabilityScore < 60) {
      suggestions.add(const ImprovementSuggestion(
        category: 'stability',
        title: '呼吸法の改善',
        description: '安定した歌声のために正しい呼吸法を身につけましょう。腹式呼吸を意識し、息の流れを一定に保つ練習をしてください。',
        priority: 1,
        specificAdvice: '腹式呼吸を意識し、息の流れを一定に保つ練習を毎日続けて、安定した歌声の基礎を作りましょう。',
      ));

      suggestions.add(const ImprovementSuggestion(
        category: 'stability',
        title: '発声練習',
        description: '母音（あ・え・い・お・う）での発声練習で、安定した声の出し方を身につけましょう。鏡を見ながら口の形も確認してください。',
        priority: 2,
        specificAdvice: '母音での発声練習を通じて、鏡で口の形を確認しながら安定した声の出し方を身につけましょう。',
      ));
    } else if (stabilityScore < 75) {
      suggestions.add(const ImprovementSuggestion(
        category: 'stability',
        title: 'ロングトーン練習',
        description: '一つの音を長く保つ練習をして、音程の安定性を高めましょう。メトロノームに合わせて、一定の音程で歌い続ける練習が効果的です。',
        priority: 2,
        specificAdvice: 'メトロノームに合わせてロングトーンの練習を行い、音程の安定性を段階的に向上させましょう。',
      ));
    } else if (stabilityScore < 85) {
      suggestions.add(const ImprovementSuggestion(
        category: 'stability',
        title: '音程変化の練習',
        description: '音程が変わる箇所での安定性を向上させましょう。音程変化をゆっくりと練習し、滑らかに移行できるようにします。',
        priority: 3,
        specificAdvice: '音程変化をゆっくりと練習し、滑らかな移行ができるよう段階的に速度を上げて練習しましょう。',
      ));
    }

    // 統計情報に基づく具体的な提案
    final avgVariation = statistics['averageVariation'] ?? 0.0;
    if (avgVariation > 40) {
      suggestions.add(const ImprovementSuggestion(
        category: 'stability',
        title: '音程変動の抑制',
        description: '音程の変動が大きすぎます。体の力を抜いてリラックスし、喉に負担をかけない発声を心がけましょう。',
        priority: 1,
        specificAdvice: '体の力を抜いてリラックスし、喉に負担をかけない自然な発声を心がけて練習しましょう。',
      ));
    }

    final maxVariation = statistics['maxVariation'] ?? 0.0;
    if (maxVariation > 80) {
      suggestions.add(const ImprovementSuggestion(
        category: 'stability',
        title: '急激な音程変化の改善',
        description: '一部で急激な音程変化が見られます。音程移行をより滑らかに行うため、レガート（なめらかに）を意識して歌いましょう。',
        priority: 2,
        specificAdvice: 'レガート（なめらかに）を意識し、音程移行をより滑らかに行う練習を重点的に行いましょう。',
      ));
    }

    return suggestions;
  }

  /// タイミングの改善提案を生成
  static List<ImprovementSuggestion> _generateTimingSuggestions(
    double timingScore,
    Map<String, double> statistics,
  ) {
    List<ImprovementSuggestion> suggestions = [];

    if (timingScore < 60) {
      suggestions.add(const ImprovementSuggestion(
        category: 'timing',
        title: 'リズム練習',
        description: 'メトロノームや原曲に合わせてリズムを正確に取る練習をしましょう。まずは歌詞なしで「ラ」や「ダ」でリズムを刻む練習から始めてください。',
        priority: 1,
        specificAdvice: 'メトロノームに合わせて「ラ」や「ダ」でリズムを刻む基礎練習から始め、正確なリズム感を身につけましょう。',
      ));

      suggestions.add(const ImprovementSuggestion(
        category: 'timing',
        title: '楽曲の構造理解',
        description: '楽曲全体の構造を把握し、どこで音程が変化するかを事前に覚えましょう。楽譜があれば参考にし、音程変化のタイミングを正確に覚えます。',
        priority: 2,
        specificAdvice: '楽曲の構造を理解し、音程変化のタイミングを楽譜や原曲で確認して正確に覚えましょう。',
      ));
    } else if (timingScore < 75) {
      suggestions.add(const ImprovementSuggestion(
        category: 'timing',
        title: '原曲との同期練習',
        description: '原曲と一緒に歌う練習を重ねて、タイミングを合わせる感覚を養いましょう。最初はゆっくりとしたテンポから始めてください。',
        priority: 2,
        specificAdvice: '原曲と一緒に歌う練習を重ね、ゆっくりとしたテンポから始めてタイミングを合わせる感覚を養いましょう。',
      ));
    } else if (timingScore < 85) {
      suggestions.add(const ImprovementSuggestion(
        category: 'timing',
        title: '細かいタイミング調整',
        description: '基本的なタイミングは取れているので、より細かい部分での調整を意識しましょう。特に音程変化の瞬間でのタイミングを正確にします。',
        priority: 3,
        specificAdvice: '基本的なタイミングを基に、音程変化の瞬間での細かいタイミング調整を練習しましょう。',
      ));
    }

    // 統計情報に基づく具体的な提案
    final songCoverage = statistics['songCoverage'] ?? 0.0;
    if (songCoverage < 0.7) {
      suggestions.add(const ImprovementSuggestion(
        category: 'timing',
        title: '楽曲完走の練習',
        description: '楽曲を最後まで歌い切る練習をしましょう。途中で止まらずに、楽曲全体の流れを掴むことが重要です。',
        priority: 1,
        specificAdvice: '楽曲を最後まで歌い切る練習を重ね、途中で止まらずに楽曲全体の流れを掴みましょう。',
      ));
    }

    if (songCoverage > 1.2) {
      suggestions.add(const ImprovementSuggestion(
        category: 'timing',
        title: '歌唱時間の調整',
        description: '原曲より長く歌っている傾向があります。テンポを意識して、原曲の長さに合わせて歌うように心がけましょう。',
        priority: 2,
        specificAdvice: 'テンポを意識し、原曲の長さに合わせて歌うよう時間管理を練習しましょう。',
      ));
    }

    return suggestions;
  }

  /// カテゴリ別の提案数を制限
  static List<ImprovementSuggestion> limitSuggestionsByCategory(
    List<ImprovementSuggestion> suggestions, {
    int maxPerCategory = 2,
  }) {
    Map<String, List<ImprovementSuggestion>> categorized = {};

    // カテゴリ別に分類
    for (final suggestion in suggestions) {
      categorized.putIfAbsent(suggestion.category, () => []).add(suggestion);
    }

    List<ImprovementSuggestion> limited = [];

    // 各カテゴリから優先度順に選択
    for (final category in categorized.keys) {
      final categoryList = categorized[category]!;
      categoryList.sort((a, b) => a.priority.compareTo(b.priority));
      limited.addAll(categoryList.take(maxPerCategory));
    }

    return limited;
  }

  /// 総合スコアに基づく全体的な励ましメッセージ
  static String generateEncouragementMessage(ComprehensiveScore score) {
    if (score.overall >= 90) {
      return '素晴らしい歌唱でした！あなたの歌声には人を感動させる力があります。';
    } else if (score.overall >= 80) {
      return 'とても上手に歌えています！細かい部分を調整すれば、さらに素晴らしい歌声になります。';
    } else if (score.overall >= 70) {
      return '良い調子です！基本はしっかりできているので、練習を続ければ確実に上達します。';
    } else if (score.overall >= 60) {
      return '基本的な歌唱力は身についています。提案された練習方法を試してみてください。';
    } else if (score.overall >= 50) {
      return '歌うことの楽しさを大切にしながら、基本から少しずつ上達していきましょう。';
    } else {
      return '歌に挑戦する気持ちが素晴らしいです！基本的な練習から始めて、一歩ずつ上達していきましょう。';
    }
  }
}
