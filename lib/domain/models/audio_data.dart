/// 音声データを格納するデータモデル
/// Single Responsibility Principle: 音声データの保持と基本操作のみに責任を限定
class AudioData {
  final List<int> samples;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final DateTime createdAt;

  const AudioData({
    required this.samples,
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.createdAt,
  });

  /// デフォルト値を使用した簡易コンストラクタ
  factory AudioData.simple({
    required List<int> samples,
    int sampleRate = 44100,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    return AudioData(
      samples: samples,
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
      createdAt: DateTime.now(),
    );
  }

  /// JSONからAudioDataを生成
  factory AudioData.fromJson(Map<String, dynamic> json) {
    return AudioData(
      samples: List<int>.from(json['samples']),
      sampleRate: json['sampleRate'],
      channels: json['channels'],
      bitsPerSample: json['bitsPerSample'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// AudioDataをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'samples': samples,
      'sampleRate': sampleRate,
      'channels': channels,
      'bitsPerSample': bitsPerSample,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 音声データの基本情報を取得
  Map<String, dynamic> getMetadata() {
    return {
      'duration': duration,
      'sampleCount': samples.length,
      'sampleRate': sampleRate,
      'channels': channels,
      'bitsPerSample': bitsPerSample,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 音声データの長さ（秒）
  double get duration => samples.length / (sampleRate * channels);

  /// サンプル数
  int get sampleCount => samples.length;

  /// 音声データが空かどうか
  bool get isEmpty => samples.isEmpty;

  /// 音声データが有効かどうか
  bool get isValid => samples.isNotEmpty && sampleRate > 0 && channels > 0;

  /// 音声データのコピーを作成
  AudioData copyWith({
    List<int>? samples,
    int? sampleRate,
    int? channels,
    int? bitsPerSample,
    DateTime? createdAt,
  }) {
    return AudioData(
      samples: samples ?? this.samples,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      bitsPerSample: bitsPerSample ?? this.bitsPerSample,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AudioData) return false;
    return samples == other.samples &&
        sampleRate == other.sampleRate &&
        channels == other.channels &&
        bitsPerSample == other.bitsPerSample;
  }

  @override
  int get hashCode {
    return Object.hash(
      samples,
      sampleRate,
      channels,
      bitsPerSample,
    );
  }

  @override
  String toString() {
    return 'AudioData(samples: ${samples.length}, '
        'sampleRate: $sampleRate, '
        'channels: $channels, '
        'duration: ${duration.toStringAsFixed(2)}s)';
  }
}
