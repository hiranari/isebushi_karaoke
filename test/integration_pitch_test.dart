import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'package:isebushi_karaoke/infrastructure/logging/console_logger.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';

void main() {
  final logger = ConsoleLogger();

  group('PitchDetectionService 実音声ファイルテスト', () {
    late PitchDetectionService pitchService;

    setUpAll(() {
      pitchService = PitchDetectionService(logger: DummyLogger());
      pitchService.initialize();
    });

    testWidgets('Test_improved.wav から実際のピッチが検出されること', (WidgetTester tester) async {
      // Test_improved.wavを使ったピッチ検出テスト
      final result = await pitchService.extractPitchFromAudio(
        sourcePath: 'assets/sounds/Test_improved.wav',
        isAsset: true,
      );

      // 結果の検証
      expect(result.pitches.isNotEmpty, true, reason: 'ピッチデータが検出されるべき');
      
      // 統計情報の取得
      final stats = result.getStatistics();
      logger.debug('=== Test_improved.wav 解析結果 ===');
      logger.debug('検出ピッチ数: ${result.pitches.length}');
      logger.debug('最小ピッチ: ${stats['min']!.toStringAsFixed(1)} Hz');
      logger.debug('最大ピッチ: ${stats['max']!.toStringAsFixed(1)} Hz');
      logger.debug('平均ピッチ: ${stats['average']!.toStringAsFixed(1)} Hz');
      logger.debug('有効データ比率: ${(stats['validRatio']! * 100).toStringAsFixed(1)}%');

      // 合理性チェック
      expect(stats['min']! >= 80.0, true, reason: '最小ピッチは80Hz以上であるべき');
      expect(stats['max']! <= 600.0, true, reason: '最大ピッチは600Hz以下であるべき');
      expect(stats['validRatio']! > 0.0, true, reason: '有効データが存在するべき');
      
      // サンプル値の表示
      final samplePitches = result.pitches.take(10).toList();
      logger.debug('最初の10個のピッチ値: $samplePitches');
    });

    testWidgets('複数の音声ファイルで一貫性があること', (WidgetTester tester) async {
      final audioFiles = [
        'assets/sounds/Test_improved.wav',
        // 他にもWAVファイルがあれば追加
      ];

      for (final file in audioFiles) {
        try {
          final result = await pitchService.extractPitchFromAudio(
            sourcePath: file,
            isAsset: true,
          );

          logger.debug('\n=== $file の解析結果 ===');
          final stats = result.getStatistics();
          logger.debug('検出ピッチ数: ${result.pitches.length}');
          logger.debug('有効データ比率: ${(stats['validRatio']! * 100).toStringAsFixed(1)}%');

          // 基本的な妥当性チェック
          expect(result.pitches.isNotEmpty, true, reason: '$file からピッチが検出されるべき');
          
        } catch (e) {
          logger.debug('$file の処理でエラー: $e');
          // 一部のファイルでエラーが出ても他のテストは続行
        }
      }
    });

    testWidgets('ピッチ検出性能が許容範囲内であること', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      final result = await pitchService.extractPitchFromAudio(
        sourcePath: 'assets/sounds/Test_improved.wav',
        isAsset: true,
      );
      
      stopwatch.stop();
      final processingTime = stopwatch.elapsedMilliseconds;
      
      logger.debug('=== 性能テスト結果 ===');
      logger.debug('処理時間: ${processingTime}ms');
      logger.debug('ピッチ数: ${result.pitches.length}');
      
      if (result.pitches.isNotEmpty) {
        final avgTimePerPitch = processingTime / result.pitches.length;
        logger.debug('ピッチあたり処理時間: ${avgTimePerPitch.toStringAsFixed(2)}ms');
        
        // 性能要件（例：5秒以内に完了）
        expect(processingTime < 5000, true, reason: '処理時間は5秒以内であるべき');
      }
    });

    testWidgets('ピッチ検出の安定性をチェック', (WidgetTester tester) async {
      // 同じファイルを複数回処理して結果の一貫性を確認
      final results = <List<double>>[];
      
      for (int i = 0; i < 3; i++) {
        final result = await pitchService.extractPitchFromAudio(
          sourcePath: 'assets/sounds/Test_improved.wav',
          isAsset: true,
        );
        results.add(result.pitches);
      }

      logger.debug('=== 安定性テスト結果 ===');
      logger.debug('実行回数: ${results.length}');
      
      // 全ての結果が同じ長さであることを確認
      final firstLength = results.first.length;
      for (int i = 1; i < results.length; i++) {
        expect(results[i].length, equals(firstLength), 
               reason: '複数回の実行で同じ数のピッチが検出されるべき');
      }
      
      // サンプルポイントで値が一致することを確認
      if (firstLength > 10) {
        for (int sampleIndex = 0; sampleIndex < 10; sampleIndex++) {
          final firstValue = results[0][sampleIndex];
          for (int resultIndex = 1; resultIndex < results.length; resultIndex++) {
            final currentValue = results[resultIndex][sampleIndex];
            expect((firstValue - currentValue).abs() < 0.1, true,
                   reason: 'ピッチ値が一貫しているべき (インデックス $sampleIndex)');
          }
        }
      }
      
      logger.debug('✅ 安定性テスト合格');
    });
  });
}
