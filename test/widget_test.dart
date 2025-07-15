// Phase 3 統合テスト
// 総合スコアリングシステムのインテグレーションテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:isebushi_karaoke/main.dart';
import 'package:isebushi_karaoke/services/karaoke_session_notifier.dart';

void main() {
  testWidgets('MyApp should initialize correctly', (WidgetTester tester) async {
    // アプリを起動
    await tester.pumpWidget(const MyApp());

    // アプリタイトルが表示されることを確認
    expect(find.text('伊勢節カラオケ'), findsOneWidget);
  });

  testWidgets('Provider should be properly configured', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Providerが正しく設定されていることを確認
    final BuildContext context = tester.element(find.byType(MaterialApp));
    expect(
      Provider.of<KaraokeSessionNotifier>(context, listen: false),
      isA<KaraokeSessionNotifier>(),
    );
  });

  testWidgets('Navigation should work correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 初期ルートが正しく表示される
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // 適切なルートが設定されている
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.initialRoute, equals('/'));
    expect(app.routes.containsKey('/'), isTrue);
    expect(app.routes.containsKey('/karaoke'), isTrue);
  });
}
