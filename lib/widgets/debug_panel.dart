import 'package:flutter/material.dart';
import '../constants/app_colors.dart' as colors;
import '../constants/app_strings.dart' as strings;
import '../services/hand_tracking_service.dart';

/// 调试面板 —— 与原 HTML #debug-panel 完全对齐
class DebugPanel extends StatelessWidget {
  final HandGesture gesture;

  const DebugPanel({
    super.key,
    required this.gesture,
  });

  @override
  Widget build(BuildContext context) {
    // 根据手势状态选择文本和颜色
    final String text;
    final Color textColor;

    switch (gesture) {
      case HandGesture.open:
        text = '手势状态: ${strings.AppStrings.debugOpen}';
        textColor = colors.AppColors.debugGreen;
        break;
      case HandGesture.fist:
        text = '手势状态: ${strings.AppStrings.debugFist}';
        textColor = colors.AppColors.debugRed;
        break;
      case HandGesture.none:
        text = strings.AppStrings.debugNoHand;
        textColor = colors.AppColors.debugGray;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: colors.AppColors.debugBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }
}
