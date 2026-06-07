import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/game_screen.dart';

/// 捏爆"马虫" - 3D 手势找不同
/// Flutter 原生重构版，完全离线运行
/// 所有手势识别模型、3D 渲染、物理模拟均为本地实现
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 允许横竖屏（桌面端窗口可缩放）
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 全屏沉浸模式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const CrushTheFQApp());
}

/// 应用根组件
class CrushTheFQApp extends StatelessWidget {
  const CrushTheFQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '捏爆"马虫" - 3D手势找不同',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF3B30),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
