/// 伊勢節カラオケアプリケーション
/// 
/// このライブラリは伊勢節カラオケアプリケーションのメインエントリーポイントです。
/// 
/// 主な機能:
/// - サービス依存性の初期化（Service Locatorパターン）
/// - アプリケーション全体のProviderツリーの構築
/// - ルーティング設定
/// 
/// アーキテクチャ:
/// - Clean Architecture（Domain, Application, Infrastructure, Presentation）
/// - Providerパターンによる状態管理
/// - Service Locatorパターンによる依存性注入
/// 
/// 参照: [UMLドキュメント](../UML_DOCUMENTATION.md#main-application-architecture)
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'song_select_page.dart';
import 'presentation/pages/karaoke_page.dart';
import 'application/providers/karaoke_session_provider.dart';
import 'infrastructure/factories/service_locator.dart';

/// アプリケーションエントリーポイント
/// 
/// サービスロケーターの初期化とアプリケーションの起動を行います。
/// 
/// 初期化フロー:
/// 1. Service Locatorによる依存性注入コンテナの初期化
/// 2. Flutterアプリケーションの開始
/// 
/// エラーハンドリング:
/// - Service Locator初期化失敗時はアプリケーションが異常終了します
/// 
/// Example:
/// ```dart
/// void main() {
///   // 依存性の初期化
///   ServiceLocator().initialize();
///   
///   // アプリ開始
///   runApp(const MyApp());
/// }
/// ```
void main() {
  // Initialize service locator with all dependencies
  ServiceLocator().initialize();
  
  runApp(const MyApp());
}

/// メインアプリケーションウィジェット
/// 
/// 伊勢節カラオケアプリケーション全体のルートウィジェットです。
/// 
/// 責任:
/// - アプリケーション全体のテーマ設定
/// - Provider階層の構築（状態管理）
/// - ルーティング設定とナビゲーション
/// 
/// アーキテクチャパターン:
/// - MultiProviderによる複数のProviderの統合管理
/// - 名前付きルートによる画面遷移管理
/// 
/// Provider構成:
/// - [KaraokeSessionProvider]: カラオケセッションの状態管理
/// 
/// ルート構成:
/// - `/`: 楽曲選択画面 ([SongSelectPage])
/// - `/karaoke`: カラオケ実行画面 ([KaraokePage])
/// 
/// 設計原則:
/// - Single Responsibility: アプリケーション構成のみに責任を持つ
/// - Dependency Inversion: 具象クラスではなく抽象に依存
/// 
/// Example:
/// ```dart
/// // アプリケーションの起動
/// runApp(const MyApp());
/// 
/// // 画面遷移の例
/// Navigator.pushNamed(context, '/karaoke');
/// ```
/// 
/// 参照: [UMLドキュメント](../UML_DOCUMENTATION.md#myapp-widget-hierarchy)
class MyApp extends StatelessWidget {
  /// デフォルトコンストラクタ
  /// 
  /// [key]: ウィジェット識別用のキー（オプション）
  const MyApp({super.key});
  
  /// ウィジェットツリーの構築
  /// 
  /// アプリケーション全体の構造を定義し、以下を設定します:
  /// - マテリアルデザインテーマ
  /// - Provider階層による状態管理
  /// - ルーティング設定
  /// 
  /// Parameters:
  /// - [context]: ビルドコンテキスト
  /// 
  /// Returns:
  /// 設定済みの[MultiProvider]ウィジェット
  /// 
  /// Throws:
  /// - [FlutterError]: Provider初期化失敗時
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
