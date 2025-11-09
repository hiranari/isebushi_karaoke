import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kDebugMode;
import '../../core/utils/singer_encoder.dart';
import '../../core/utils/debug_file_logger.dart';
import '../../infrastructure/services/wav_validator.dart';

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
    // デバッグセッション開始
    DebugFileLogger.startSession('楽曲選択ページ開始');
    _loadSongList();
  }

  Future<void> _loadSongList() async {
    try {
      DebugFileLogger.log('INFO', '楽曲リストの読み込み開始');
      final jsonStr = await rootBundle.loadString('assets/data/song.json');
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      setState(() {
        songs = jsonList.map((e) => Map<String, String>.from(e)).toList();
      });
      DebugFileLogger.log('SUCCESS', '楽曲リスト読み込み完了: ${songs.length}曲', data: {
        'song_count': songs.length,
        'songs': songs.take(3).map((s) => s['title']).toList(), // 最初の3曲をサンプル表示
      });
    } catch (e) {
      DebugFileLogger.log('ERROR', '楽曲リスト読み込み失敗: $e');
      rethrow;
    }
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
        appBar: AppBar(
          title: const Text('曲を選択'),
          actions: [
            // デバッグモードでのみPhase 3デモボタンを表示
            if (kDebugMode)
              IconButton(
                icon: const Icon(Icons.science, color: Colors.orange),
                onPressed: () {
                  Navigator.pushNamed(context, '/phase3-demo');
                },
                tooltip: 'Phase 3 デモ (開発用)',
              ),
          ],
        ),
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
                  onTap: () async {
                    DebugFileLogger.log('NAVIGATION', '楽曲選択: ${song['title']}', data: {
                      'selected_song': song['title'],
                      'audio_file': song['audioFile'],
                      'singer': song['singer'],
                    });
                    
                    // WAVファイル検証
                    await _validateAndNavigate(song);
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
  
  /// WAVファイル検証と画面遷移
  Future<void> _validateAndNavigate(Map<String, String> song) async {
    final audioFile = song['audioFile'];
    if (audioFile == null || audioFile.isEmpty) {
      _showErrorDialog('音声ファイルが指定されていません', 'この楽曲は音声ファイルが設定されていないため再生できません。');
      return;
    }
    
    // 検証中ダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('音声ファイルを検証中...'),
            ],
          ),
        );
      },
    );
    
    try {
      // WAVファイル検証実行
      // audioFileが既にフルパスの場合はそのまま使用、ファイル名のみの場合はパスを追加
      final filePath = audioFile.startsWith('assets/') ? audioFile : 'assets/sounds/$audioFile';
      final validationResult = await WavValidator.validateWavFile(filePath);
      
      // 検証中ダイアログを閉じる
      if (mounted) Navigator.of(context).pop();
      
      if (validationResult.isValid) {
        // 問題なし：カラオケ画面へ移動
        DebugFileLogger.log('SUCCESS', 'WAVファイル検証成功: $audioFile');
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/karaoke',
            arguments: song,
          );
        }
      } else {
        // 問題あり：エラーダイアログ表示
        DebugFileLogger.log('WARNING', 'WAVファイル検証失敗: $audioFile', data: {
          'issues': validationResult.issues.map((i) => i.message).toList(),
        });
        
        if (mounted) {
          _showDetailedErrorDialog(song['title'] ?? '不明な楽曲', validationResult);
        }
      }
    } catch (e) {
      // 検証中ダイアログを閉じる
      if (mounted) Navigator.of(context).pop();
      
      DebugFileLogger.log('ERROR', 'WAVファイル検証エラー: $e');
      if (mounted) {
        _showErrorDialog('検証エラー', '音声ファイルの検証中にエラーが発生しました。\n\nエラー詳細: $e');
      }
    }
  }
  
  /// 詳細なエラーダイアログを表示
  void _showDetailedErrorDialog(String songTitle, WavValidationResult result) {
    final issues = result.issues;
    final fileInfo = result.fileInfo;
    
    // ファイルが見つからない場合の特別処理
    if (issues.any((issue) => issue.type == WavIssueType.fileNotFound)) {
      _showFileNotFoundDialog(songTitle, issues);
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('音声ファイルに問題があります')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('楽曲: $songTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('ファイル情報:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('• ${fileInfo.channels}チャンネル, ${fileInfo.bitsPerSample}bit, ${fileInfo.sampleRate}Hz'),
                Text('• 再生時間: ${fileInfo.durationSeconds.toStringAsFixed(1)}秒'),
                if (fileInfo.silenceDurationMs > 0)
                  Text('• 初期無音: ${(fileInfo.silenceDurationMs / 1000).toStringAsFixed(1)}秒'),
                const SizedBox(height: 16),
                const Text('検出された問題:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ...issues.map((issue) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ${issue.message}', style: TextStyle(color: Colors.red[700])),
                      if (issue.actualValue != null && issue.expectedValue != null)
                        Text('  実際: ${issue.actualValue}, 期待: ${issue.expectedValue}', 
                             style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text('  解決策: ${issue.solution}', 
                           style: TextStyle(fontSize: 12, color: Colors.blue[700])),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.build, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text('修正方法', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('コマンドラインツールで修正できます:', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'dart scripts/fix_wav_file.dart "${fileInfo.channels > 0 ? 'assets/sounds/${result.issues.isNotEmpty ? 'ファイル名' : ''}' : ''}"',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
            if (result.hasBlockAlignIssue || result.hasByteRateIssue)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showToolInstructions();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('修正方法を表示', style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }
  
  /// ツール使用方法ダイアログ
  void _showToolInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.build, color: Colors.blue),
              SizedBox(width: 8),
              Text('WAVファイル修正ツール'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('以下の手順でWAVファイルを修正できます:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInstructionStep('1', 'ターミナル（コマンドプロンプト）を開く'),
                _buildInstructionStep('2', 'プロジェクトフォルダに移動'),
                _buildInstructionStep('3', '以下のコマンドを実行:'),
                Container(
                  margin: const EdgeInsets.only(left: 24, top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('# 1つのファイルを修正', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                      const Text('dart scripts/fix_wav_file.dart assets/sounds/ファイル名.wav'),
                      const SizedBox(height: 8),
                      Text('# 全ファイルをチェック・修正', style: TextStyle(fontSize: 12, color: Colors.green[700])),
                      const Text('dart scripts/validate_all_wavs.dart'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionStep('4', 'アプリを再起動して再度お試しください'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '修正ツールは安全です。元のファイルは自動的にバックアップされます。',
                          style: TextStyle(fontSize: 12, color: Colors.amber[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(instruction)),
        ],
      ),
    );
  }
  
  /// ファイルが見つからない場合の専用ダイアログ
  void _showFileNotFoundDialog(String songTitle, List<WavIssue> issues) {
    final fileNotFoundIssue = issues.firstWhere((issue) => issue.type == WavIssueType.fileNotFound);
    final isMP3Available = fileNotFoundIssue.message.contains('MP3ファイルは存在します');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('ファイルが見つかりません')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('楽曲: $songTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('問題:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text('• ${fileNotFoundIssue.message}', style: TextStyle(color: Colors.orange[700])),
                const SizedBox(height: 16),
                if (isMP3Available) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text('解決方法', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('MP3ファイルをWAV形式に変換してください:', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        const Text('1. MP3ファイルを音声変換ソフトで開く'),
                        const Text('2. WAV形式（16bit, ステレオ, 44.1kHz推奨）で保存'),
                        const Text('3. 元のMP3ファイルと同じ名前でWAV拡張子にする'),
                        const SizedBox(height: 8),
                        const Text('推奨設定:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const Text('• サンプリングレート: 44,100Hz'),
                        const Text('• ビット深度: 16bit'),
                        const Text('• チャンネル: ステレオ（2チャンネル）'),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.red[700]),
                            const SizedBox(width: 4),
                            Text('対処方法', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('音声ファイルが見つかりません。以下を確認してください:', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('• ファイルパスの確認'),
                        const Text('• WAV形式での録音または変換'),
                        const Text('• assets/soundsフォルダへの配置'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        );
      },
    );
  }

  /// 一般的なエラーダイアログ
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}