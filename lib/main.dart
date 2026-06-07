import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/webview_screen.dart';

/// 捏爆"马虫" — WebView 离线版
/// 本地 HTTP 服务器 + 全离线 JS 资源 + 原生 WebView 容器
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const CrushTheFQApp());
}

class CrushTheFQApp extends StatelessWidget {
  const CrushTheFQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '捏爆"马虫" - 3D手势找不同',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      home: const WebViewScreen(),
    );
  }
}
