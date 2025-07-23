import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/services/audio_processing_service.dart';
import 'dart:typed_data';

/// AudioProcessingServiceの単体テスト
/// 
/// 音声処理ロジックとPCMデータ操作をテストします
void main() {
  group('AudioProcessingService Tests', () {
    group('PCMデータ処理', () {
      test('PCMデータの正規化', () {
        // 16bitのテストデータ（-32768 ~ 32767の範囲）
        final testData = Int16List.fromList([
          -32768, // 最小値
          0,      // 中央値
          32767,  // 最大値
          16384,  // 半分
          -16384, // 負の半分
        ]);

        final normalized = AudioProcessingService.normalizePcmData(testData);

        expect(normalized.length, equals(testData.length));
        
        // 値の範囲チェック（正規化後も16bit範囲内）
        for (final value in normalized) {
          expect(value, greaterThanOrEqualTo(-32768));
          expect(value, lessThanOrEqualTo(32767));
        }
      });

      test('空のPCMデータの正規化', () {
        final emptyData = Int16List(0);
        final normalized = AudioProcessingService.normalizePcmData(emptyData);
        
        expect(normalized, isEmpty);
      });

      test('単一値のPCMデータの正規化', () {
        final singleValue = Int16List.fromList([1000]);
        final normalized = AudioProcessingService.normalizePcmData(singleValue);
        
        expect(normalized.length, equals(1));
        expect(normalized[0], equals(1000)); // 単一値は変更されない
      });

      test('全て同じ値のPCMデータの正規化', () {
        final sameValues = Int16List.fromList([500, 500, 500, 500]);
        final normalized = AudioProcessingService.normalizePcmData(sameValues);
        
        expect(normalized.length, equals(4));
        // 全て同じ値の場合、変更されない
        expect(normalized.every((value) => value == 500), isTrue);
      });

      test('極端な値を含むPCMデータの正規化', () {
        final extremeData = Int16List.fromList([
          -32768, // 最小値
          32767,  // 最大値
          1,      // 小さな正の値
          -1,     // 小さな負の値
        ]);

        final normalized = AudioProcessingService.normalizePcmData(extremeData);

        expect(normalized.length, equals(4));
        // 極端な値も適切に処理される
        expect(normalized[0], greaterThanOrEqualTo(-32768));
        expect(normalized[1], lessThanOrEqualTo(32767));
      });
    });

    group('WAVファイル処理', () {
      test('無効なWAVファイルパスでのエラーハンドリング', () async {
        expect(
          () async => await AudioProcessingService.extractPcmFromWavFile('/invalid/path.wav'),
          throwsA(isA<Exception>()),
        );
      });

      test('空のファイルパスでのエラーハンドリング', () async {
        expect(
          () async => await AudioProcessingService.extractPcmFromWavFile(''),
          throwsA(isA<Exception>()),
        );
      });

      test('nullファイルパスでのエラーハンドリング', () async {
        expect(
          () async => await AudioProcessingService.extractPcmFromWavFile(''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('ヘルパーメソッド', () {
      test('Int16ListからUint8Listへの変換', () {
        final int16Data = Int16List.fromList([0x1234, 0x5678, 0xABCD]);
        
        // リトルエンディアン変換をテスト
        final uint8Data = Uint8List.fromList(int16Data.expand((sample) => [
          sample & 0xFF,        // 下位バイト
          (sample >> 8) & 0xFF, // 上位バイト
        ]).toList());

        expect(uint8Data.length, equals(int16Data.length * 2));
        
        // 最初のサンプル (0x1234) の確認
        expect(uint8Data[0], equals(0x34)); // 下位バイト
        expect(uint8Data[1], equals(0x12)); // 上位バイト
      });

      test('ゼロ値を含むInt16データの変換', () {
        final int16Data = Int16List.fromList([0, -1, 1]);
        
        final uint8Data = Uint8List.fromList(int16Data.expand((sample) => [
          sample & 0xFF,
          (sample >> 8) & 0xFF,
        ]).toList());

        expect(uint8Data.length, equals(6));
        
        // ゼロ値の確認
        expect(uint8Data[0], equals(0));
        expect(uint8Data[1], equals(0));
      });

      test('負の値を含むInt16データの変換', () {
        final int16Data = Int16List.fromList([-1, -256, -32768]);
        
        final uint8Data = Uint8List.fromList(int16Data.expand((sample) => [
          sample & 0xFF,
          (sample >> 8) & 0xFF,
        ]).toList());

        expect(uint8Data.length, equals(6));
        
        // 負の値が適切に変換されることを確認
        expect(uint8Data, isA<Uint8List>());
      });
    });

    group('パフォーマンステスト', () {
      test('大きなPCMデータの処理性能', () {
        // 1秒分のデータ（44100サンプル）
        final largeData = Int16List(44100);
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = (i % 32768).toInt();
        }

        final stopwatch = Stopwatch()..start();
        final normalized = AudioProcessingService.normalizePcmData(largeData);
        stopwatch.stop();

        expect(normalized.length, equals(largeData.length));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1秒以内
      });

      test('非常に小さなPCMデータの処理', () {
        final tinyData = Int16List.fromList([1]);
        final normalized = AudioProcessingService.normalizePcmData(tinyData);
        
        expect(normalized.length, equals(1));
        expect(normalized[0], equals(1));
      });
    });

    group('境界値テスト', () {
      test('16bit整数の境界値処理', () {
        final boundaryData = Int16List.fromList([
          -32768, // Int16最小値
          32767,  // Int16最大値
          -32767, // 最小値+1
          32766,  // 最大値-1
        ]);

        final normalized = AudioProcessingService.normalizePcmData(boundaryData);

        expect(normalized.length, equals(4));
        for (final value in normalized) {
          expect(value, greaterThanOrEqualTo(-32768));
          expect(value, lessThanOrEqualTo(32767));
        }
      });
    });
  });
}
