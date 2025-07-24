import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'core/utils/singer_encoder.dart';

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final navigator = Navigator.of(context);
        
        // 最初の画面でのアプリ終了確認
        final shouldExit = await _showAppExitConfirmation();
        if (shouldExit) {
          // システムに戻る（アプリ終了）
          navigator.pop();
        }
      },
      child: Scaffold(
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
                    Navigator.pushNamed(
                      context,
                      '/karaoke',
                      arguments: song,
                    );
                  },
                );
              },
            ),
      ),
    );
  }

  /// アプリ終了確認ダイアログ
  Future<bool> _showAppExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アプリを終了しますか？'),
          content: const Text('伊勢節カラオケアプリを終了してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('終了'),
            ),
          ],
        );
      },
    ) ?? false;
  }
}