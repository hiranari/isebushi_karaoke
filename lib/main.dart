import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '伊勢節カラオケ',
      home: KaraokePage(),
    );
  }
}

class KaraokePage extends StatefulWidget {
  const KaraokePage({super.key});

  @override
  _KaraokePageState createState() => _KaraokePageState();
}

class _KaraokePageState extends State<KaraokePage> {
  final AudioPlayer _player = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Stream<Uint8List>>? _audioStreamSub;
  StreamSubscription<Uint8List>? _pcmStreamSub;
  PitchDetector? _pitchDetector;
  bool _isRecording = false;
  double? _currentPitch;
  final List<double> _recordedPitches = [];
  final List<double> _referencePitches = []; // 元音源のピッチ配列（例として空）

  @override
  void initState() {
    super.initState();
    _loadReferencePitches();
  }

  Future<void> _loadReferencePitches() async {
    final jsonStr = await rootBundle.loadString('assets/pitch/kiku_pitches.json');
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    setState(() {
      _referencePitches
        ..clear()
        ..addAll(jsonList.map((e) => (e as num).toDouble()));
    });
  }

  @override
  void dispose() {
    _pcmStreamSub?.cancel();
    _audioStreamSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    await _player.setAudioSource(AudioSource.asset('assets/sounds/kiku.mp3'));
    _player.play();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;

    _pitchDetector = PitchDetector();

    // onStateChangedは録音状態の監視用
    // onStreamはPCMデータのストリーム
    final pcmStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: 1,
      ),
    );

    _pcmStreamSub = pcmStream.listen((buffer) {
      if (_pitchDetector != null) {
        _pitchDetector!.getPitchFromIntBuffer(buffer).then((result) {
          setState(() {
            _currentPitch = result.pitched ? result.pitch : null;
            if (_isRecording && _currentPitch != null && _currentPitch! > 0) {
              _recordedPitches.add(_currentPitch!);
            }
          });
        });
      }
    });

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    await _pcmStreamSub?.cancel();
    setState(() => _isRecording = false);
  }

  double _calculateMatchRate() {
    if (_referencePitches.isEmpty || _recordedPitches.isEmpty) return 0;
    int minLen = _referencePitches.length < _recordedPitches.length
        ? _referencePitches.length
        : _recordedPitches.length;
    int matchCount = 0;
    for (int i = 0; i < minLen; i++) {
      if ((_referencePitches[i] - _recordedPitches[i]).abs() < 30) {
        matchCount++;
      }
    }
    return matchCount / minLen * 100;
  }

  double _calculateScore() {
    if (_referencePitches.isEmpty || _recordedPitches.isEmpty) return 0;
    int minLen = _referencePitches.length < _recordedPitches.length
        ? _referencePitches.length
        : _recordedPitches.length;
    int matchCount = 0;
    for (int i = 0; i < minLen; i++) {
      if ((_referencePitches[i] - _recordedPitches[i]).abs() < 30) {
        matchCount++;
      }
    }
    return (matchCount / minLen) * 100;
  }

  @override
  Widget build(BuildContext context) {
    double matchRate = _calculateMatchRate();
    double score = _calculateScore();
    return Scaffold(
      appBar: AppBar(title: Text('伊勢節カラオケ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _playAudio, child: Text('音源を再生')),
            if (!kIsWeb)
              ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                child: Text(_isRecording ? '録音停止' : '録音開始'),
              ),
            if (kIsWeb)
              Text('Webでは録音機能は利用できません'),
            SizedBox(height: 20),
            Text('現在のピッチ: ${_currentPitch?.toStringAsFixed(2) ?? "-"} Hz'),
            SizedBox(height: 20),
            Text('一致率: ${matchRate.toStringAsFixed(1)} %'),
            SizedBox(height: 20),
            Text('スコア: ${score.toStringAsFixed(1)} 点'),
          ],
        ),
      ),
    );
  }
}
