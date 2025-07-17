import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'song_select_page.dart';
import 'pages/karaoke_page.dart';
import 'providers/song_result_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Phase 3: 状態管理のためのProvider
        ChangeNotifierProvider(create: (_) => SongResultProvider()),
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
