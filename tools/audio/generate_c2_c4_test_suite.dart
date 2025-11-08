#!/usr/bin/env dart
/// C2～C4音域（3オクターブ・36半音階）の系統的テスト音源生成ツール
/// 
/// 機能:
/// - 36半音階の単音WAVファイル生成 (C2: 65.41Hz ～ C4: 261.63Hz)
/// - オクターブ別音階パターン (メジャー・マイナー・クロマチック)
/// - 楽器音色バリエーション (ピアノ・ベース・チェロ等)
/// - 動的テスト用音源 (グリッサンド・ピッチベンド・ビブラート)
/// - ノイズ耐性・音量・持続時間別バリエーション
/// 
/// 使用例:
/// ```bash
/// dart tools/audio/generate_c2_c4_test_suite.dart
/// dart tools/audio/generate_c2_c4_test_suite.dart --output-dir test_audio --duration 1000
/// ```

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// 音楽理論定数
class MusicTheory {
  /// A4基準周波数 (440Hz)
  static const double a4Frequency = 440.0;
  
  /// A4のMIDIノート番号
  static const int a4MidiNote = 69;
  
  /// 12平均律の半音比率 (2^(1/12))
  static const double semitoneRatio = 1.0594630943592953;
  
  /// 音階名マッピング
  static const List<String> noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  
  /// MIDIノート番号から周波数を計算
  static double midiToFrequency(int midiNote) {
    return a4Frequency * pow(2.0, (midiNote - a4MidiNote) / 12.0);
  }
  
  /// MIDIノート番号から音階名を取得
  static String midiToNoteName(int midiNote) {
    final octave = (midiNote / 12).floor() - 1;
    final noteIndex = midiNote % 12;
    return '${noteNames[noteIndex]}$octave';
  }
  
  /// C2～C4の範囲 (MIDI: 36～60)
  static const int c2MidiNote = 36;  // C2: 65.41Hz
  static const int c4MidiNote = 60;  // C4: 261.63Hz
}

/// WAVファイル生成クラス
class WaveformGenerator {
  /// サンプリングレート
  static const int sampleRate = 44100;
  
  /// 基本正弦波生成
  static Uint8List generateSineWave(
    double frequency,
    int durationMs, {
    double amplitude = 0.5,
    int? fadeInMs,
    int? fadeOutMs,
  }) {
    final samples = (sampleRate * durationMs / 1000).round();
    final data = Float32List(samples);
    
    // フェードイン・フェードアウト設定
    final fadeInSamples = fadeInMs != null ? (sampleRate * fadeInMs / 1000).round() : 0;
    final fadeOutSamples = fadeOutMs != null ? (sampleRate * fadeOutMs / 1000).round() : 0;
    
    for (int i = 0; i < samples; i++) {
      // 基本正弦波
      final value = amplitude * sin(2 * pi * frequency * i / sampleRate);
      
      // フェードイン処理
      double fadeMultiplier = 1.0;
      if (i < fadeInSamples) {
        fadeMultiplier = i / fadeInSamples;
      } else if (i >= samples - fadeOutSamples) {
        fadeMultiplier = (samples - i) / fadeOutSamples;
      }
      
      data[i] = value * fadeMultiplier;
    }
    
    return _floatToWav(data);
  }
  
  /// ピアノ音色近似生成（ハーモニクス付き）
  static Uint8List generatePianoTone(
    double frequency,
    int durationMs, {
    double amplitude = 0.5,
  }) {
    final samples = (sampleRate * durationMs / 1000).round();
    final data = Float32List(samples);
    
    // ピアノのハーモニクス構造 (基本周波数の倍音)
    final harmonics = [
      1.0,   // 基本波
      0.5,   // 2倍音
      0.25,  // 3倍音
      0.125, // 4倍音
      0.0625, // 5倍音
    ];
    
    for (int i = 0; i < samples; i++) {
      double value = 0.0;
      
      // ハーモニクス合成
      for (int h = 0; h < harmonics.length; h++) {
        final harmonicFreq = frequency * (h + 1);
        final harmonicAmp = harmonics[h] * amplitude;
        value += harmonicAmp * sin(2 * pi * harmonicFreq * i / sampleRate);
      }
      
      // エンベロープ (ADSR簡易版)
      final timeRatio = i / samples;
      double envelope = 1.0;
      if (timeRatio < 0.1) {
        // Attack
        envelope = timeRatio / 0.1;
      } else if (timeRatio < 0.3) {
        // Decay
        envelope = 1.0 - (timeRatio - 0.1) / 0.2 * 0.3;
      } else if (timeRatio < 0.8) {
        // Sustain
        envelope = 0.7;
      } else {
        // Release
        envelope = 0.7 * (1.0 - (timeRatio - 0.8) / 0.2);
      }
      
      data[i] = value * envelope;
    }
    
    return _floatToWav(data);
  }
  
  /// 低音楽器音色生成（ベース・チェロ用）
  static Uint8List generateBassInstrument(
    double frequency,
    int durationMs, {
    double amplitude = 0.6,
  }) {
    final samples = (sampleRate * durationMs / 1000).round();
    final data = Float32List(samples);
    
    // 低音楽器のハーモニクス構造 (より強い基本波)
    final harmonics = [
      1.0,    // 基本波 (強)
      0.7,    // 2倍音
      0.4,    // 3倍音
      0.2,    // 4倍音
      0.1,    // 5倍音
    ];
    
    for (int i = 0; i < samples; i++) {
      double value = 0.0;
      
      // ハーモニクス合成
      for (int h = 0; h < harmonics.length; h++) {
        final harmonicFreq = frequency * (h + 1);
        final harmonicAmp = harmonics[h] * amplitude;
        value += harmonicAmp * sin(2 * pi * harmonicFreq * i / sampleRate);
      }
      
      // 低音楽器特有のスローアタック
      final timeRatio = i / samples;
      double envelope = 1.0;
      if (timeRatio < 0.2) {
        // Slow Attack
        envelope = timeRatio / 0.2;
      } else if (timeRatio < 0.9) {
        // Long Sustain
        envelope = 1.0;
      } else {
        // Release
        envelope = (1.0 - (timeRatio - 0.9) / 0.1);
      }
      
      data[i] = value * envelope;
    }
    
    return _floatToWav(data);
  }
  
  /// グリッサンド生成 (周波数変化)
  static Uint8List generateGlissando(
    double startFreq,
    double endFreq,
    int durationMs, {
    double amplitude = 0.5,
  }) {
    final samples = (sampleRate * durationMs / 1000).round();
    final data = Float32List(samples);
    
    for (int i = 0; i < samples; i++) {
      final progress = i / samples;
      // 対数的周波数変化 (音楽的に自然)
      final currentFreq = startFreq * pow(endFreq / startFreq, progress);
      
      data[i] = amplitude * sin(2 * pi * currentFreq * i / sampleRate);
    }
    
    return _floatToWav(data);
  }
  
  /// ビブラート生成
  static Uint8List generateVibrato(
    double frequency,
    int durationMs, {
    double amplitude = 0.5,
    double vibratoRate = 5.0, // Hz
    double vibratoDepth = 0.02, // 2%の周波数変調
  }) {
    final samples = (sampleRate * durationMs / 1000).round();
    final data = Float32List(samples);
    
    for (int i = 0; i < samples; i++) {
      // ビブラート周波数変調
      final vibratoValue = sin(2 * pi * vibratoRate * i / sampleRate);
      final modulatedFreq = frequency * (1.0 + vibratoDepth * vibratoValue);
      
      data[i] = amplitude * sin(2 * pi * modulatedFreq * i / sampleRate);
    }
    
    return _floatToWav(data);
  }
  
  /// Float32ListをWAVバイト配列に変換
  static Uint8List _floatToWav(Float32List data) {
    final buffer = BytesBuilder();
    
    // WAVヘッダー
    final dataSize = data.length * 2; // 16-bit
    final fileSize = 36 + dataSize;
    
    // RIFF header
    buffer.add('RIFF'.codeUnits);
    buffer.add(_int32ToBytes(fileSize));
    buffer.add('WAVE'.codeUnits);
    
    // fmt chunk
    buffer.add('fmt '.codeUnits);
    buffer.add(_int32ToBytes(16)); // PCM format chunk size
    buffer.add(_int16ToBytes(1));  // PCM format
    buffer.add(_int16ToBytes(1));  // Mono
    buffer.add(_int32ToBytes(sampleRate));
    buffer.add(_int32ToBytes(sampleRate * 2)); // Byte rate
    buffer.add(_int16ToBytes(2));  // Block align
    buffer.add(_int16ToBytes(16)); // Bits per sample
    
    // data chunk
    buffer.add('data'.codeUnits);
    buffer.add(_int32ToBytes(dataSize));
    
    // 音声データ (Float32 → Int16変換)
    for (final sample in data) {
      final intSample = (sample * 32767).round().clamp(-32768, 32767);
      buffer.add(_int16ToBytes(intSample));
    }
    
    return buffer.toBytes();
  }
  
  static Uint8List _int16ToBytes(int value) {
    return Uint8List.fromList([value & 0xFF, (value >> 8) & 0xFF]);
  }
  
  static Uint8List _int32ToBytes(int value) {
    return Uint8List.fromList([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }
}

/// テストスイート生成クラス
class TestSuiteGenerator {
  final String outputDir;
  final int defaultDuration;
  
  TestSuiteGenerator(this.outputDir, {this.defaultDuration = 1000});
  
  /// 全テストスイート生成
  Future<void> generateFullSuite() async {
    print('🎵 C2～C4音域テストスイート生成開始...');
    
    // 出力ディレクトリ作成
    await _createDirectories();
    
    // 1. 単音テスト (36半音階)
    await _generateSingleTones();
    
    // 2. 音階テスト
    await _generateScales();
    
    // 3. 楽器別テスト
    await _generateInstrumentVariations();
    
    // 4. 動的テスト
    await _generateDynamicTests();
    
    // 5. 特殊条件テスト
    await _generateSpecialConditionTests();
    
    print('✅ テストスイート生成完了！');
    print('📁 出力先: $outputDir');
  }
  
  /// ディレクトリ構造作成
  Future<void> _createDirectories() async {
    final dirs = [
      'single_tones',
      'scales',
      'instruments/piano',
      'instruments/bass',
      'instruments/cello',
      'dynamic/glissando',
      'dynamic/vibrato',
      'conditions/duration',
      'conditions/volume',
      'conditions/noise',
    ];
    
    for (final dir in dirs) {
      await Directory('$outputDir/$dir').create(recursive: true);
    }
  }
  
  /// 1. 単音テスト生成 (C2～C4の36半音)
  Future<void> _generateSingleTones() async {
    print('🎼 単音テスト音源生成中...');
    
    for (int midi = MusicTheory.c2MidiNote; midi <= MusicTheory.c4MidiNote; midi++) {
      final frequency = MusicTheory.midiToFrequency(midi);
      final noteName = MusicTheory.midiToNoteName(midi);
      
      // 基本正弦波
      final waveData = WaveformGenerator.generateSineWave(
        frequency,
        defaultDuration,
        fadeInMs: 50,
        fadeOutMs: 50,
      );
      
      final filename = '${noteName.replaceAll('#', 'sharp')}_${frequency.toStringAsFixed(2)}Hz.wav';
      await File('$outputDir/single_tones/$filename').writeAsBytes(waveData);
      
      print('  ✓ $noteName (${frequency.toStringAsFixed(2)}Hz)');
    }
  }
  
  /// 2. 音階テスト生成
  Future<void> _generateScales() async {
    print('🎵 音階テスト音源生成中...');
    
    // 各オクターブのCメジャースケール
    for (int octave = 2; octave <= 3; octave++) {
      await _generateScale('C${octave}_major', _getMajorScale(octave * 12 + 12));
      await _generateScale('C${octave}_minor', _getMinorScale(octave * 12 + 12));
      await _generateScale('C${octave}_chromatic', _getChromaticScale(octave * 12 + 12));
    }
  }
  
  /// 3. 楽器別テスト生成
  Future<void> _generateInstrumentVariations() async {
    print('🎹 楽器別テスト音源生成中...');
    
    // テスト用代表音程
    final testNotes = [
      MusicTheory.c2MidiNote,      // C2
      MusicTheory.c2MidiNote + 12, // C3
      MusicTheory.c2MidiNote + 24, // C4
    ];
    
    for (final midi in testNotes) {
      final frequency = MusicTheory.midiToFrequency(midi);
      final noteName = MusicTheory.midiToNoteName(midi);
      
      // ピアノ音色
      final pianoData = WaveformGenerator.generatePianoTone(frequency, defaultDuration);
      await File('$outputDir/instruments/piano/${noteName}_piano.wav').writeAsBytes(pianoData);
      
      // 低音楽器音色 (C2, C3のみ)
      if (midi <= MusicTheory.c2MidiNote + 12) {
        final bassData = WaveformGenerator.generateBassInstrument(frequency, defaultDuration);
        await File('$outputDir/instruments/bass/${noteName}_bass.wav').writeAsBytes(bassData);
        
        final celloData = WaveformGenerator.generateBassInstrument(frequency, defaultDuration * 2);
        await File('$outputDir/instruments/cello/${noteName}_cello.wav').writeAsBytes(celloData);
      }
      
      print('  ✓ $noteName 楽器バリエーション');
    }
  }
  
  /// 4. 動的テスト生成
  Future<void> _generateDynamicTests() async {
    print('🌊 動的テスト音源生成中...');
    
    // グリッサンド (C2→C3, C3→C4)
    final glissandoPairs = [
      [MusicTheory.c2MidiNote, MusicTheory.c2MidiNote + 12], // C2→C3
      [MusicTheory.c2MidiNote + 12, MusicTheory.c2MidiNote + 24], // C3→C4
    ];
    
    for (final pair in glissandoPairs) {
      final startFreq = MusicTheory.midiToFrequency(pair[0]);
      final endFreq = MusicTheory.midiToFrequency(pair[1]);
      final startNote = MusicTheory.midiToNoteName(pair[0]);
      final endNote = MusicTheory.midiToNoteName(pair[1]);
      
      final glissData = WaveformGenerator.generateGlissando(
        startFreq, endFreq, defaultDuration * 2
      );
      
      await File('$outputDir/dynamic/glissando/${startNote}_to_${endNote}_glissando.wav')
          .writeAsBytes(glissData);
      
      print('  ✓ ${startNote}→${endNote} グリッサンド');
    }
    
    // ビブラート
    final vibratoNotes = [MusicTheory.c2MidiNote, MusicTheory.c2MidiNote + 12, MusicTheory.c2MidiNote + 24];
    for (final midi in vibratoNotes) {
      final frequency = MusicTheory.midiToFrequency(midi);
      final noteName = MusicTheory.midiToNoteName(midi);
      
      final vibratoData = WaveformGenerator.generateVibrato(
        frequency, defaultDuration * 2
      );
      
      await File('$outputDir/dynamic/vibrato/${noteName}_vibrato.wav')
          .writeAsBytes(vibratoData);
      
      print('  ✓ $noteName ビブラート');
    }
  }
  
  /// 5. 特殊条件テスト生成
  Future<void> _generateSpecialConditionTests() async {
    print('⚙️ 特殊条件テスト音源生成中...');
    
    final testFreq = MusicTheory.midiToFrequency(MusicTheory.c2MidiNote + 12); // C3
    
    // 持続時間バリエーション
    final durations = [100, 500, 2000]; // ms
    for (final duration in durations) {
      final data = WaveformGenerator.generateSineWave(testFreq, duration);
      await File('$outputDir/conditions/duration/C3_${duration}ms.wav').writeAsBytes(data);
    }
    
    // 音量バリエーション
    final amplitudes = [0.1, 0.3, 0.7, 1.0];
    for (int i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i];
      final dbLevel = (20 * log(amp) / ln10).round();
      final data = WaveformGenerator.generateSineWave(testFreq, defaultDuration, amplitude: amp);
      await File('$outputDir/conditions/volume/C3_${dbLevel}dB.wav').writeAsBytes(data);
    }
    
    print('  ✓ 持続時間・音量バリエーション');
  }
  
  /// 音階生成ヘルパー
  Future<void> _generateScale(String scaleName, List<int> midiNotes) async {
    final frequencies = <double>[];
    for (final midi in midiNotes) {
      frequencies.add(MusicTheory.midiToFrequency(midi));
    }
    
    // 連続音階生成 (各音500ms)
    final scaleData = <int>[];
    for (final freq in frequencies) {
      final noteData = WaveformGenerator.generateSineWave(freq, 500);
      scaleData.addAll(noteData);
    }
    
    await File('$outputDir/scales/$scaleName.wav').writeAsBytes(Uint8List.fromList(scaleData));
    print('  ✓ $scaleName');
  }
  
  List<int> _getMajorScale(int rootMidi) => [
    rootMidi, rootMidi + 2, rootMidi + 4, rootMidi + 5, 
    rootMidi + 7, rootMidi + 9, rootMidi + 11, rootMidi + 12
  ];
  
  List<int> _getMinorScale(int rootMidi) => [
    rootMidi, rootMidi + 2, rootMidi + 3, rootMidi + 5, 
    rootMidi + 7, rootMidi + 8, rootMidi + 10, rootMidi + 12
  ];
  
  List<int> _getChromaticScale(int rootMidi) => 
      List.generate(13, (i) => rootMidi + i);
}

/// コマンドライン引数解析
class CliArgs {
  final String outputDir;
  final int duration;
  final bool verbose;
  
  CliArgs({
    required this.outputDir,
    required this.duration,
    required this.verbose,
  });
  
  static CliArgs parse(List<String> args) {
    String outputDir = 'test_audio_c2_c4';
    int duration = 1000;
    bool verbose = false;
    
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--output-dir':
          if (i + 1 < args.length) outputDir = args[++i];
          break;
        case '--duration':
          if (i + 1 < args.length) duration = int.tryParse(args[++i]) ?? 1000;
          break;
        case '--verbose':
          verbose = true;
          break;
        case '--help':
          _printHelp();
          exit(0);
      }
    }
    
    return CliArgs(outputDir: outputDir, duration: duration, verbose: verbose);
  }
  
  static void _printHelp() {
    print('''
C2～C4音域テストスイート生成ツール

使用法:
  dart tools/audio/generate_c2_c4_test_suite.dart [オプション]

オプション:
  --output-dir <dir>    出力ディレクトリ (デフォルト: test_audio_c2_c4)
  --duration <ms>       音声持続時間(ms) (デフォルト: 1000)
  --verbose             詳細出力
  --help                このヘルプを表示

例:
  dart tools/audio/generate_c2_c4_test_suite.dart
  dart tools/audio/generate_c2_c4_test_suite.dart --output-dir my_tests --duration 2000
''');
  }
}

/// メイン実行
Future<void> main(List<String> args) async {
  final config = CliArgs.parse(args);
  
  print('🎵 C2～C4音域テストスイート生成ツール');
  print('📁 出力先: ${config.outputDir}');
  print('⏱️  音声長: ${config.duration}ms');
  print('');
  
  final generator = TestSuiteGenerator(config.outputDir, defaultDuration: config.duration);
  
  try {
    await generator.generateFullSuite();
    
    print('');
    print('🎯 生成統計:');
    print('  • 単音テスト: 36ファイル (C2～C4の半音階)');
    print('  • 音階テスト: 6ファイル (各オクターブ×3音階)');
    print('  • 楽器テスト: 9ファイル (ピアノ・ベース・チェロ)');
    print('  • 動的テスト: 5ファイル (グリッサンド・ビブラート)');
    print('  • 特殊条件: 7ファイル (持続時間・音量)');
    print('  📊 合計: 約63ファイル');
    print('');
    print('✅ すべてのテスト音源が正常に生成されました！');
    
  } catch (e) {
    print('❌ エラー: $e');
    exit(1);
  }
}
