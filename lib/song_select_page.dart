import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'utils/singer_encoder.dart';

class SongSelectPage extends StatefulWidget {
  const SongSelectPage({super.key});

  @override
  State<SongSelectPage> createState() => _SongSelectPageState();
}

class _SongSelectPageState extends State<SongSelectPage> {
  List<Map<String, String>> songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongList();
  }

  Future<void> _loadSongList() async {
    final jsonStr = await rootBundle.loadString('assets/data/song.json');
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    setState(() {
      songs = jsonList.map((e) => Map<String, String>.from(e)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('曲を選択')),
      body: songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final displaySinger = song['singer'] != null 
                    ? SingerEncoder.decode(song['singer']!) 
                    : null;
                return ListTile(
                  title: Text(song['title'] ?? ''),
                  subtitle: displaySinger != null 
                      ? Text('歌手: $displaySinger', 
                             style: TextStyle(color: Colors.grey[600]))
                      : null,
                  tileColor: index % 2 == 0
                      ? Colors.grey[100] // 偶数行（薄いグレー）
                      : Colors.white, // 奇数行（白）
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/karaoke',
                      arguments: song,
                    );
                  },
                );
              },
            ),
    );
  }
}