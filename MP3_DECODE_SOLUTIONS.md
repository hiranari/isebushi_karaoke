# MP3デコード対応のためのライブラリ候補

## 推奨ライブラリ

### 1. ffmpeg_kit_flutter
```yaml
dependencies:
  ffmpeg_kit_flutter: ^6.0.3
```

### 2. flutter_ffmpeg（非推奨）
```yaml
dependencies:
  flutter_ffmpeg: ^0.4.2
```

### 3. just_audio + audioplayers
```yaml
dependencies:
  just_audio: ^0.9.34
  audioplayers: ^5.0.0
```

## 実装例（ffmpeg_kit_flutter）

```dart
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

Future<Int16List> convertMp3ToPcmWithFFmpeg(String mp3Path) async {
  final outputPath = '${mp3Path}_converted.wav';
  
  // MP3 → WAV変換コマンド
  final command = '-i $mp3Path -ar 44100 -ac 1 -f wav $outputPath';
  
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  
  if (returnCode?.isValueSuccess() == true) {
    // WAVファイルを読み込んでPCMデータを抽出
    return await extractPcmFromWavFile(outputPath);
  } else {
    throw Exception('MP3変換に失敗しました');
  }
}
```

## 当面の回避策

1. **WAV形式での基準音源提供**
   - MP3ファイルを事前にWAV形式に変換
   - アセットフォルダに配置

2. **オンライン変換サービス利用**
   - 録音データを一時的にサーバーに送信
   - サーバー側でピッチ解析

3. **シミュレーションデータの改良**
   - より実際の楽曲に近いピッチパターン
   - 楽曲固有のピッチデータをJSON形式で保存
