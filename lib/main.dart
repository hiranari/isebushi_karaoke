import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart' as ja;

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
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _playAudio() async {
    await _player.setAudioSource(ja.AudioSource.asset('assets/sounds/kiku.mp3'));
    _player.play();
    //await _player.setFilePath('/path/to/isebushi.mp3'); // ローカル音源のパス
    //_player.play();
  }

  Future<void> _startRecording() async {
    await _recorder.startRecorder(toFile: 'my_voice.aac');
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
  }

  @override
  void dispose() {
    _player.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('伊勢節カラオケ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: _playAudio, child: Text('音源を再生')),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? '録音停止' : '録音開始'),
            ),
          ],
        ),
      ),
    );
  }
}
