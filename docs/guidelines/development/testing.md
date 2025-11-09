# テスティングガイドライン

## 目的

伊勢節カラオケアプリの品質を確保するため、以下の目標を達成する：

- テストの一貫性と網羅性の確保
- 音声処理とピッチ検出の正確性の検証
- ユーザー体験の品質保証
- CI/CDパイプラインでの自動テスト実行

## テストの種類

### 1. 単体テスト（Unit Tests）

#### 基本ルール
- 1テストファイルにつき1クラス/コンポーネント
- テストファイル名: `{テスト対象}_test.dart`
- テストグループ名は機能や状況を明確に説明

```dart
void main() {
  group('PitchDetector', () {
    late PitchDetector detector;
    
    setUp(() {
      detector = PitchDetector();
    });

    test('正しい周波数を検出できること', () {
      final result = detector.detectPitch(sampleAudio);
      expect(result.frequency, closeTo(440.0, 1.0));
    });
  });
}
```

#### モック化のルール
- 外部依存（API、ファイルI/O等）は必ずモック化
- `mockito` または `mocktail` を使用
- モッククラスは `mocks` ディレクトリに配置

```dart
@GenerateMocks([AudioProcessor])
void main() {
  late MockAudioProcessor mockProcessor;
  
  setUp(() {
    mockProcessor = MockAudioProcessor();
  });
}
```

### 2. ウィジェットテスト（Widget Tests）

#### テスト対象
- 個別のウィジェット
- 画面遷移
- ユーザーインタラクション
- アニメーション

```dart
testWidgets('スコア表示が正しく更新されること', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ScoreDisplay(score: 85),
    ),
  );

  expect(find.text('85点'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

#### パフォーマンステスト
- フレームドロップの検出
- メモリリーク検出
- 描画パフォーマンス計測

### 3. 統合テスト（Integration Tests）

#### 音声処理テスト
- 録音機能
- ピッチ検出精度
- 音声エフェクト
- 遅延測定

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('録音からピッチ検出までの統合テスト', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // 録音開始
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pumpAndSettle();
    
    // 3秒間録音
    await Future.delayed(Duration(seconds: 3));
    
    // 録音停止
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    
    // ピッチ検出結果の検証
    expect(find.byType(PitchGraph), findsOneWidget);
    final pitchData = tester.widget<PitchGraph>(find.byType(PitchGraph)).data;
    expect(pitchData, isNotEmpty);
  });
}
```

### 4. ピッチ検出精度テスト

#### テストデータセット
- `test_audio/` ディレクトリに配置
- 各音域のサンプル音声
- ノイズ付きサンプル
- 実際の歌声サンプル

```dart
test('C4(261.63Hz)の音が正しく検出されること', () {
  final detector = PitchDetector();
  final audioData = loadTestAudio('c4_pure_tone.wav');
  final result = detector.detectPitch(audioData);
  
  expect(result.frequency, closeTo(261.63, 1.0));
  expect(result.confidence, greaterThan(0.9));
});
```

### 5. 性能テスト（Performance Tests）

#### 測定項目
- ピッチ検出の遅延時間
- 音声処理のCPU使用率
- メモリ使用量
- バッテリー消費

```dart
test('ピッチ検出の遅延が許容範囲内であること', () {
  final detector = PitchDetector();
  final audioData = loadTestAudio('performance_test.wav');
  
  final stopwatch = Stopwatch()..start();
  detector.detectPitch(audioData);
  stopwatch.stop();
  
  expect(stopwatch.elapsedMilliseconds, lessThan(50));
});
```

## テストカバレッジ要件

### カバレッジ目標
- 全体: 80%以上
- ビジネスロジック: 90%以上
- UI/UXコンポーネント: 75%以上
- ピッチ検出エンジン: 95%以上

### 測定方法
```bash
# カバレッジ計測
flutter test --coverage

# レポート生成
genhtml coverage/lcov.info -o coverage/html
```

## テスト実行環境

### ローカル環境
```bash
# 全テスト実行
flutter test

# 特定のテストファイル実行
flutter test test/pitch_detector_test.dart

# 特定のグループのみ実行
flutter test --name="PitchDetector"
```

### CI環境
- プルリクエスト時に自動実行
- マージ前にすべてのテストパス必須
- カバレッジレポートの自動生成

## エラー処理とアサーション

### エラーケーステスト
- 無効な入力値
- 境界値
- エッジケース
- タイムアウト

```dart
test('無効な音声データでエラーが発生すること', () {
  final detector = PitchDetector();
  expect(
    () => detector.detectPitch(invalidAudioData),
    throwsA(isA<InvalidAudioDataException>()),
  );
});
```

### アサーションのベストプラクティス
- 具体的なエラーメッセージ
- カスタムMatcher の活用
- 複数の検証ポイント

## モックデータ管理

### モックデータの配置
```
test/
├── fixtures/
│   ├── audio/
│   │   ├── pure_tones/
│   │   └── real_samples/
│   └── responses/
└── mocks/
    └── services/
```

### モックデータの作成ルール
- 実際のユースケースを反映
- エッジケースを含む
- 再現性の確保

## テストメンテナンス

### 定期的なレビュー
- 未使用テストの削除
- 重複テストの統合
- テストケースの更新

### リファクタリング
- テストコードの整理
- ヘルパー関数の抽出
- 共通セットアップの最適化

## ベストプラクティス

1. **AAA パターンの使用**
   ```dart
   test('スコア計算が正しく行われること', () {
     // Arrange
     final calculator = ScoreCalculator();
     final pitchData = createTestPitchData();
     
     // Act
     final score = calculator.calculate(pitchData);
     
     // Assert
     expect(score, greaterThanOrEqualTo(0));
     expect(score, lessThanOrEqualTo(100));
   });
   ```

2. **テストの独立性確保**
   - 各テストは独立して実行可能
   - グローバル状態への依存を避ける
   - `setUp` と `tearDown` の適切な使用

3. **命名規則**
   ```dart
   // グループ名: テスト対象の機能や状況
   group('PitchDetector - ノイズ環境での動作', () {
     // テスト名: 期待される動作を説明
     test('背景ノイズがある場合でも主要な音程を検出できること', () {
       // テストの実装
     });
   });
   ```

## トラブルシューティング

### よくある問題と解決策

1. **非同期テストの失敗**
   ```dart
   // ❌ 悪い例
   test('非同期処理のテスト', () {
     final result = asyncFunction();
     expect(result, equals(expectedValue));
   });
   
   // ✅ 良い例
   test('非同期処理のテスト', () async {
     final result = await asyncFunction();
     expect(result, equals(expectedValue));
   });
   ```

2. **フレーキーテスト（不安定なテスト）**
   - タイミング依存の最小化
   - 適切なウェイト処理
   - テスト環境の安定化

## 付録

### A. テストテンプレート
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/feature/pitch_detection.dart';

void main() {
  late FeatureClass sut; // System Under Test
  
  setUp(() {
    sut = FeatureClass();
  });
  
  tearDown(() {
    // クリーンアップ処理
  });
  
  group('機能名', () {
    test('テストケース説明', () {
      // テスト実装
    });
  });
}
```

### B. カスタムMatchers
```dart
class PitchMatcher extends Matcher {
  final double expectedFrequency;
  final double tolerance;
  
  const PitchMatcher(this.expectedFrequency, {this.tolerance = 1.0});
  
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! PitchResult) return false;
    return (item.frequency - expectedFrequency).abs() <= tolerance;
  }
  
  @override
  Description describe(Description description) =>
    description.add('周波数が $expectedFrequency Hz ± $tolerance Hz');
}
```
