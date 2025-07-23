/// Base exception for audio-related errors
class AudioException implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  const AudioException(
    this.message, {
    this.details,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AudioException: $message');
    if (details != null) {
      buffer.write('\nDetails: $details');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Exception for audio processing errors
class AudioProcessingException extends AudioException {
  const AudioProcessingException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception for pitch detection errors
class PitchDetectionException extends AudioException {
  const PitchDetectionException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception for file format errors
class AudioFormatException extends AudioException {
  const AudioFormatException(
    super.message, {
    super.details,
    super.originalError,
  });
}

/// Exception for score calculation errors
class ScoringException extends AudioException {
  const ScoringException(
    super.message, {
    super.details,
    super.originalError,
  });
}
