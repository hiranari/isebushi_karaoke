import 'package:flutter/material.dart';
import 'dart:math' as math;

/// リアルタイムスコア表示ウィジェット
/// 
/// 歌唱中のスコアをリアルタイムで計算・表示し、
/// フィードバックとして音程の正確性を可視化する
class RealtimeScoreWidget extends StatefulWidget {
  /// 現在のスコア（0-100）
  final double currentScore;
  
  /// 最高スコア
  final double maxScore;
  
  /// 平均スコア
  final double averageScore;
  
  /// 音程正確性の評価レベル
  final ScoreLevel scoreLevel;
  
  /// スコア履歴（最近のスコア推移）
  final List<double> scoreHistory;
  
  /// ウィジェットの高さ
  final double height;
  
  /// カスタムカラーテーマ
  final ScoreColorTheme? colorTheme;

  const RealtimeScoreWidget({
    super.key,
    required this.currentScore,
    this.maxScore = 0.0,
    this.averageScore = 0.0,
    this.scoreLevel = ScoreLevel.beginner,
    this.scoreHistory = const [],
    this.height = 120.0,
    this.colorTheme,
  });

  @override
  State<RealtimeScoreWidget> createState() => _RealtimeScoreWidgetState();
}

class _RealtimeScoreWidgetState extends State<RealtimeScoreWidget>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late AnimationController _levelUpAnimationController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _levelUpAnimation;
  
  ScoreLevel _previousLevel = ScoreLevel.beginner;

  @override
  void initState() {
    super.initState();
    
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _levelUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentScore,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _levelUpAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelUpAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _previousLevel = widget.scoreLevel;
    _scoreAnimationController.forward();
  }

  @override
  void didUpdateWidget(RealtimeScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // スコアが変更された場合のアニメーション
    if (widget.currentScore != oldWidget.currentScore) {
      _scoreAnimation = Tween<double>(
        begin: oldWidget.currentScore,
        end: widget.currentScore,
      ).animate(CurvedAnimation(
        parent: _scoreAnimationController,
        curve: Curves.easeOutCubic,
      ));
      _scoreAnimationController.forward(from: 0);
    }
    
    // レベルアップアニメーション
    if (widget.scoreLevel != _previousLevel && 
        widget.scoreLevel.index > _previousLevel.index) {
      _levelUpAnimationController.forward(from: 0);
    }
    _previousLevel = widget.scoreLevel;
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    _levelUpAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = widget.colorTheme ?? ScoreColorTheme.defaultTheme();
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorTheme.backgroundStart,
            colorTheme.backgroundEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // メインスコア表示
          _buildMainScoreDisplay(colorTheme),
          
          // レベルアップエフェクト
          if (_levelUpAnimation.value > 0)
            _buildLevelUpEffect(colorTheme),
          
          // スコア履歴グラフ
          Positioned(
            right: 16,
            top: 16,
            bottom: 16,
            width: 80,
            child: _buildScoreHistoryGraph(colorTheme),
          ),
        ],
      ),
    );
  }

  /// メインスコア表示部分
  Widget _buildMainScoreDisplay(ScoreColorTheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // スコア数値表示
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 現在のスコア
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Text(
                      '${_scoreAnimation.value.toInt()}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(_scoreAnimation.value, colorTheme),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4.0,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // スコアレベル表示
                AnimatedBuilder(
                  animation: _levelUpAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_levelUpAnimation.value * 0.2),
                      child: Text(
                        widget.scoreLevel.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.scoreLevel.color,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 統計情報
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatText('最高', widget.maxScore, colorTheme.textSecondary),
                const SizedBox(height: 4),
                _buildStatText('平均', widget.averageScore, colorTheme.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 統計テキスト作成
  Widget _buildStatText(String label, double value, Color color) {
    return Text(
      '$label: ${value.toInt()}',
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// レベルアップエフェクト
  Widget _buildLevelUpEffect(ScoreColorTheme colorTheme) {
    return AnimatedBuilder(
      animation: _levelUpAnimation,
      builder: (context, child) {
        if (_levelUpAnimation.value == 0) return const SizedBox();
        
        return Center(
          child: Transform.scale(
            scale: _levelUpAnimation.value,
            child: Opacity(
              opacity: 1.0 - _levelUpAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.scoreLevel.color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// スコア履歴グラフ
  Widget _buildScoreHistoryGraph(ScoreColorTheme colorTheme) {
    if (widget.scoreHistory.isEmpty) {
      return const SizedBox();
    }
    
    return CustomPaint(
      painter: ScoreHistoryPainter(
        scores: widget.scoreHistory,
        lineColor: colorTheme.accent,
        backgroundColor: colorTheme.backgroundStart.withValues(alpha: 0.3),
      ),
      size: Size.infinite,
    );
  }

  /// スコアに基づく色を取得
  Color _getScoreColor(double score, ScoreColorTheme colorTheme) {
    if (score >= 90) return colorTheme.excellent;
    if (score >= 80) return colorTheme.good;
    if (score >= 70) return colorTheme.average;
    return colorTheme.poor;
  }
}

/// スコア履歴グラフ描画用ペインター
class ScoreHistoryPainter extends CustomPainter {
  final List<double> scores;
  final Color lineColor;
  final Color backgroundColor;

  ScoreHistoryPainter({
    required this.scores,
    required this.lineColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;
    
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    // 背景を描画
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ),
      backgroundPaint,
    );
    
    // スコアの最大値と最小値を計算
    final maxScore = scores.reduce(math.max);
    final minScore = scores.reduce(math.min);
    final scoreRange = maxScore - minScore;
    
    if (scoreRange == 0) return;
    
    final path = Path();
    bool isFirstPoint = true;
    
    for (int i = 0; i < scores.length; i++) {
      final x = (size.width / (scores.length - 1)) * i;
      final normalizedScore = (scores[i] - minScore) / scoreRange;
      final y = size.height * (1.0 - normalizedScore);
      
      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ScoreHistoryPainter oldDelegate) {
    return scores != oldDelegate.scores ||
           lineColor != oldDelegate.lineColor;
  }
}

/// スコアレベル定義
enum ScoreLevel {
  beginner('初心者', Colors.grey),
  novice('見習い', Colors.blue),
  amateur('素人', Colors.green),
  intermediate('中級者', Colors.orange),
  advanced('上級者', Colors.purple),
  expert('専門家', Colors.red),
  master('達人', Colors.amber),
  legend('伝説', Colors.cyan);

  const ScoreLevel(this.displayName, this.color);
  
  final String displayName;
  final Color color;
  
  /// スコアからレベルを判定
  static ScoreLevel fromScore(double score) {
    if (score >= 98) return ScoreLevel.legend;
    if (score >= 95) return ScoreLevel.master;
    if (score >= 90) return ScoreLevel.expert;
    if (score >= 85) return ScoreLevel.advanced;
    if (score >= 75) return ScoreLevel.intermediate;
    if (score >= 65) return ScoreLevel.amateur;
    if (score >= 50) return ScoreLevel.novice;
    return ScoreLevel.beginner;
  }
}

/// スコア表示用カラーテーマ
class ScoreColorTheme {
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color excellent;
  final Color good;
  final Color average;
  final Color poor;

  const ScoreColorTheme({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.excellent,
    required this.good,
    required this.average,
    required this.poor,
  });

  /// デフォルトテーマ
  factory ScoreColorTheme.defaultTheme() {
    return const ScoreColorTheme(
      backgroundStart: Color(0xFF1A1A2E),
      backgroundEnd: Color(0xFF16213E),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB0B0B0),
      accent: Color(0xFF00D4FF),
      excellent: Color(0xFF00FF00),
      good: Color(0xFF00BFFF),
      average: Color(0xFFFFD700),
      poor: Color(0xFFFF6B6B),
    );
  }
}
