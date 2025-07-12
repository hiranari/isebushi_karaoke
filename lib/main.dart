import 'package:flutter/material.dart';
import 'song_select_page.dart';
import 'karaoke_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '伊勢節カラオケ',
      initialRoute: '/',
      routes: {
        '/': (context) => const SongSelectPage(), // songsパラメータを削除
        '/karaoke': (context) => const KaraokePage(),
      },
    );
  }
}
