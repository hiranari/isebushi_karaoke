import 'package:flutter/material.dart';

/// アプリ内デバッグ情報表示ウィジェット
class DebugInfoOverlay extends StatefulWidget {
  final List<String> debugLogs;
  final bool isVisible;
  final VoidCallback? onToggle;

  const DebugInfoOverlay({
    super.key,
    required this.debugLogs,
    required this.isVisible,
    this.onToggle,
  });

  @override
  State<DebugInfoOverlay> createState() => _DebugInfoOverlayState();
}

class _DebugInfoOverlayState extends State<DebugInfoOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(DebugInfoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 新しいログが追加されたら自動スクロール
    if (widget.debugLogs.length > oldWidget.debugLogs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 10,
      right: 10,
      height: 300,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'リアルタイムデバッグログ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // ログ表示エリア
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: widget.debugLogs.isEmpty
                      ? const Center(
                          child: Text(
                            'デバッグログがありません',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: widget.debugLogs.length,
                          itemBuilder: (context, index) {
                            final log = widget.debugLogs[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                log,
                                style: TextStyle(
                                  color: _getLogColor(log),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              // フッター
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.debugLogs.length} ログ',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () {
                        // ログをクリアする機能を追加可能
                      },
                      child: const Text(
                        'クリア',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('✅') || log.contains('SUCCESS')) {
      return Colors.green;
    } else if (log.contains('❌') || log.contains('ERROR')) {
      return Colors.red;
    } else if (log.contains('⚠️') || log.contains('WARNING')) {
      return Colors.orange;
    } else if (log.contains('🔄') || log.contains('INFO')) {
      return Colors.blue;
    } else if (log.contains('🎵') || log.contains('🎯')) {
      return Colors.purple;
    } else {
      return Colors.white;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
