import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
                return ListTile(
                  title: Text(songs[index]['title'] ?? ''),
                  tileColor: index % 2 == 0
                      ? Colors.grey[100] // 偶数行（薄いグレー）
                      : Colors.white, // 奇数行（白）
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/karaoke',
                      arguments: songs[index],
                    );
                  },
                );
              },
            ),
    );
  }
}