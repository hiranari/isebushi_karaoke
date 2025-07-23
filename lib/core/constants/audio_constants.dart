/// Audio processing constants
class AudioConstants {
  // Audio format constraints
  static const String supportedFormat = 'WAV';
  static const List<String> allowedExtensions = ['.wav'];
  
  // Pitch detection parameters
  static const double minValidPitch = 80.0;  // Hz
  static const double maxValidPitch = 1000.0; // Hz
  static const double pitchDetectionThreshold = 0.5;
  
  // Scoring weights
  static const double pitchAccuracyWeight = 0.7;
  static const double stabilityWeight = 0.2;
  static const double timingWeight = 0.1;
  
  // Score thresholds
  static const double excellentScoreThreshold = 90.0;
  static const double goodScoreThreshold = 75.0;
  static const double averageScoreThreshold = 60.0;
  static const double needsImprovementThreshold = 45.0;
  
  // Audio processing settings
  static const int sampleRate = 44100;
  static const int bitsPerSample = 16;
  static const int channels = 1; // Mono
  
  // Cache settings
  static const Duration defaultCacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // Number of items
  
  // Performance settings
  static const int pitchDetectionWindowSize = 1024;
  static const double pitchSmoothingFactor = 0.3;
  
  // UI constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double scoreDisplayAnimationDelay = 2.0; // seconds
}

/// Audio quality constants
class AudioQualityConstants {
  static const double minimumAudioDuration = 3.0; // seconds
  static const double maximumAudioDuration = 180.0; // seconds
  static const double minimumVolumeLevel = 0.1;
  static const double noiseFloorThreshold = 0.05;
}
