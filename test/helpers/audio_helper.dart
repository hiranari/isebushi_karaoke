import 'dart:math' as math;
import 'dart:typed_data';

/// Generates a sine wave as a 16-bit PCM data list.
///
/// [frequency] The frequency of the sine wave in Hz.
/// [duration] The duration of the wave in seconds.
/// [sampleRate] The sample rate in Hz.
/// Returns a [List<int>] containing the 16-bit PCM data.
List<int> generateSineWavePcm({
  required double frequency,
  double duration = 1.0,
  int sampleRate = 44100,
}) {
  final samples = (sampleRate * duration).toInt();
  final pcm16 = Int16List(samples);

  for (int i = 0; i < samples; i++) {
    final time = i / sampleRate;
    final amplitude = math.sin(2 * math.pi * frequency * time);
    final sample = (amplitude * 32767).round().clamp(-32768, 32767);
    pcm16[i] = sample;
  }

  return pcm16.toList();
}
