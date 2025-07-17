import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'song_select_page.dart';
import 'pages/karaoke_page.dart';
import 'services/karaoke_session_notifier.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => KaraokeSessionNotifier()),
      ],
      child: MaterialApp(
        title: '伊勢節カラオケ',
        initialRoute: '/',
        routes: {
          '/': (context) => const SongSelectPage(), // songsパラメータを削除
          '/karaoke': (context) => const KaraokePage(),
        },
      ),
    );
  }
}
