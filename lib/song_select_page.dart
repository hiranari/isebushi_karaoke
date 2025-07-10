import 'package:flutter/material.dart';

class SongSelectPage extends StatelessWidget {
  final List<String> songs;
  const SongSelectPage({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('曲を選択')),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(songs[index]),
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