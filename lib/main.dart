import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'song_select_page.dart';
import 'pages/karaoke_page.dart';
import 'providers/karaoke_session_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KaraokeSessionProvider()),
      ],
      child: MaterialApp(
        title: '伊勢節カラオケ',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SongSelectPage(),
          '/karaoke': (context) => const KaraokePage(),
        },
      ),
    );
  }
}
