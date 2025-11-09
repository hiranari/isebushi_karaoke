import 'package:flutter/material.dart';
import '../widgets/pitch_visualization_widget.dart';
import '../widgets/realtime_score_widget.dart';
import '../../infrastructure/services/pitch_comparison_service.dart';
import 'dart:math' as math;

/// Phase 3機能のデモページ
/// 
/// 新しく実装したリアルタイム可視化機能とスコア計算機能を
/// デモンストレーション形式で展示するページ
class Phase3DemoPage extends StatefulWidget {
  const Phase3DemoPage({super.key});

  @override
  State<Phase3DemoPage> createState() => _Phase3DemoPageState();
}

class _Phase3DemoPageState extends State<Phase3DemoPage>
    with TickerProviderStateMixin {
  
  // デモ用状態変数
  double _currentPitch = 220.0;
  double _referencePitch = 220.0;
  final List<double> _pitchHistory = [];
  final List<RealtimeScoreResult> _scoreHistory = [];
  double _currentScore = 0.0;
  double _averageScore = 0.0;
  double _maxScore = 0.0;
  ScoreLevel _currentLevel = ScoreLevel.beginner;
  bool _isDemoRunning = false;
  
  // アニメーション用
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController)
      ..addListener(_updateDemo);
    
    // 初期データを生成
    _generateInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// デモ用初期データ生成
  void _generateInitialData() {
    final random = math.Random();
    
    // 基準ピッチパターン（伊勢節風のメロディー）
    final referencePitches = [
      220.0, 246.94, 261.63, 293.66, 329.63, 349.23, 329.63, 293.66,
      261.63, 246.94, 220.0, 196.0, 220.0, 246.94, 261.63, 220.0
    ];
    
    // ピッチ履歴を初期化
    for (int i = 0; i < 50; i++) {
      final baseIndex = i % referencePitches.length;
      final basePitch = referencePitches[baseIndex];
      final variation = (random.nextDouble() - 0.5) * 20;
      _pitchHistory.add(basePitch + variation);
    }
    
    _referencePitch = referencePitches[0];
    _currentPitch = _pitchHistory.isNotEmpty ? _pitchHistory.last : 220.0;
  }

  /// デモアニメーション更新
  void _updateDemo() {
    if (!mounted || !_isDemoRunning) return;
    
    final progress = _animation.value;
    final random = math.Random();
    
    // 音程パターンの生成（歌唱の改善をシミュレート）
    final improvementFactor = progress; // 時間と共に改善
    
    // 基準ピッチを周期的に変更
    final melodyCycle = (progress * 8) % 1.0;
    final melodyNotes = [220.0, 246.94, 261.63, 293.66, 329.63, 349.23, 329.63, 293.66];
    final noteIndex = (melodyCycle * melodyNotes.length).floor() % melodyNotes.length;
    _referencePitch = melodyNotes[noteIndex];
    
    // 検出ピッチをシミュレート（徐々に上達）
    final errorRange = 30.0 * (1.0 - improvementFactor); // エラー範囲が縮小
    final error = (random.nextDouble() - 0.5) * errorRange;
    _currentPitch = _referencePitch + error;
    
    // ピッチ履歴を更新
    _pitchHistory.add(_currentPitch);
    if (_pitchHistory.length > 100) {
      _pitchHistory.removeAt(0);
    }
    
    // スコア計算
    final scoreResult = PitchComparisonService.calculateRealtimeScore(
      _currentPitch,
      _referencePitch,
    );
    
    if (scoreResult.isValid) {
      _scoreHistory.add(scoreResult);
      if (_scoreHistory.length > 200) {
        _scoreHistory.removeAt(0);
      }
      
      // 累積スコア計算
      final cumulativeResult = PitchComparisonService.calculateCumulativeScore(_scoreHistory);
      
      setState(() {
        _currentScore = scoreResult.score;
        _averageScore = cumulativeResult.averageScore;
        _maxScore = cumulativeResult.maxScore;
        _currentLevel = ScoreLevel.fromScore(_averageScore);
      });
    }
  }

  /// デモ開始/停止
  void _toggleDemo() {
    setState(() {
      _isDemoRunning = !_isDemoRunning;
    });
    
    if (_isDemoRunning) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  /// デモリセット
  void _resetDemo() {
    _animationController.reset();
    setState(() {
      _isDemoRunning = false;
      _scoreHistory.clear();
      _pitchHistory.clear();
      _currentScore = 0.0;
      _averageScore = 0.0;
      _maxScore = 0.0;
      _currentLevel = ScoreLevel.beginner;
    });
    _generateInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 3 デモ - リアルタイム可視化'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDemoRunning ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleDemo,
            tooltip: _isDemoRunning ? 'デモ停止' : 'デモ開始',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetDemo,
            tooltip: 'リセット',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phase 3 新機能デモ',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• リアルタイムピッチ可視化\n'
                      '• 音程正確性の即座判定\n'
                      '• 累積スコアと上達トレンド\n'
                      '• アニメーション付きフィードバック',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // スコア表示セクション
            Text(
              'リアルタイムスコア',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            RealtimeScoreWidget(
              currentScore: _currentScore,
              maxScore: _maxScore,
              averageScore: _averageScore,
              scoreLevel: _currentLevel,
              scoreHistory: _scoreHistory.map((s) => s.score).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // ピッチ可視化セクション
            Text(
              'ピッチ可視化',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            PitchVisualizationWidget(
              currentPitch: _currentPitch,
              referencePitch: _referencePitch,
              pitchHistory: _pitchHistory,
              height: 200.0,
            ),
            
            const SizedBox(height: 24),
            
            // 統計情報カード
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '詳細統計',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow('現在ピッチ', '${_currentPitch.toStringAsFixed(1)} Hz'),
                    _buildStatRow('基準ピッチ', '${_referencePitch.toStringAsFixed(1)} Hz'),
                    _buildStatRow('ピッチ差', '${(_currentPitch - _referencePitch).toStringAsFixed(1)} Hz'),
                    _buildStatRow('現在スコア', '${_currentScore.toStringAsFixed(1)} 点'),
                    _buildStatRow('平均スコア', '${_averageScore.toStringAsFixed(1)} 点'),
                    _buildStatRow('最高スコア', '${_maxScore.toStringAsFixed(1)} 点'),
                    _buildStatRow('現在レベル', _currentLevel.displayName),
                    _buildStatRow('データ数', '${_scoreHistory.length} サンプル'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // コントロールボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleDemo,
                  icon: Icon(_isDemoRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isDemoRunning ? 'デモ停止' : 'デモ開始'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDemoRunning ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _resetDemo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('リセット'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 統計情報行を構築
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.indigo)),
        ],
      ),
    );
  }
}
