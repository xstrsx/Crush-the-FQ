import 'package:flutter/material.dart';

/// 全局颜色常量 —— 与原 HTML 完全对齐
class AppColors {
  AppColors._();

  // 背景色
  static const Color background = Color(0xFF1A1A1A);
  static const Color floor = Color(0xFF2A2A2A);
  static const Color gridLine = Color(0xFF444444);
  static const Color gridLineAlt = Color(0xFF222222);

  // 标题
  static const Color titleWhite = Color(0xFFFFFFFF);
  static const Color titleRed = Color(0xFFFF3B30);

  // 按钮
  static const Color btnGradientStart = Color(0xFFFF3B30);
  static const Color btnGradientEnd = Color(0xFFFF9500);

  // Debug 面板
  static const Color debugGreen = Color(0xFF00FF00);
  static const Color debugRed = Color(0xFFFF3B30);
  static const Color debugGray = Color(0xFFAAAAAA);
  static const Color debugBg = Color(0x99000000);

  // 光标
  static const Color cursorDefault = Color(0xFF00FF00);
  static const Color cursorFist = Color(0xFFFF0000);

  // 立方体高亮
  static const Color emissiveHover = Color(0xFF333333);
  static const Color wrongFlash = Color(0xFFFF3333);

  // 炫彩粒子颜色（与原版一致）
  static const List<Color> particleColors = [
    Color(0xFFFF0044),
    Color(0xFFFF8800),
    Color(0xFFFFDD00),
    Color(0xFF00FFCC),
    Color(0xFF00AAFF),
    Color(0xFFAA00FF),
    Color(0xFFFFFFFF),
  ];

  // 雾色
  static const Color fogColor = Color(0xFF1A1A1A);

  // 灯光
  static const Color ambientLight = Color(0x99FFFFFF);
  static const Color dirLight = Color(0xFFFFFFFF);

  // GitHub 图标
  static const Color githubIcon = Color(0x80FFFFFF);
}
