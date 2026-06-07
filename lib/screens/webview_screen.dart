import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/local_server.dart';

/// WebView 主屏幕 —— 全屏显示原始 HTML 手势游戏
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final LocalServer _server = LocalServer();
  WebViewController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _server.start();

      // 平台适配：Android 需要一些额外配置
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF1A1A1A))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {},
            onPageFinished: (_) {},
            onWebResourceError: (error) {
              debugPrint('WebView error: ${error.description}');
            },
          ),
        )
        ..enableZoom(false);

      await controller.loadRequest(Uri.parse(_server.url));

      if (mounted) {
        setState(() {
          _controller = controller;
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '启动失败: $_error',
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_ready || _controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3B30)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
