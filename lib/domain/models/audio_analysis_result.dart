/// 音声解析結果を格納するデータモデル
class AudioAnalysisResult {
  final List<double> pitches;
  final int sampleRate;
  final DateTime createdAt;
  final String sourceFile;

  const AudioAnalysisResult({
    required this.pitches,
    required this.sampleRate,
    required this.createdAt,
    required this.sourceFile,
  });

  /// JSONからAudioAnalysisResultを生成
  factory AudioAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AudioAnalysisResult(
      pitches: List<double>.from(json['pitches']),
      sampleRate: json['sampleRate'],
      createdAt: DateTime.parse(json['createdAt']),
      sourceFile: json['sourceFile'],
    );
  }

  /// AudioAnalysisResultをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'pitches': pitches,
      'sampleRate': sampleRate,
      'createdAt': createdAt.toIso8601String(),
      'sourceFile': sourceFile,
    };
  }

  /// ピッチデータの統計情報を取得
  Map<String, double> getStatistics() {
    final validPitches = pitches.where((p) => p > 0).toList();

    if (validPitches.isEmpty) {
      return {'min': 0.0, 'max': 0.0, 'average': 0.0, 'validRatio': 0.0};
    }

    validPitches.sort();
    return {
      'min': validPitches.first,
      'max': validPitches.last,
      'average': validPitches.reduce((a, b) => a + b) / validPitches.length,
      'validRatio': validPitches.length / pitches.length,
    };
  }
}
