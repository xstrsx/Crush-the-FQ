import 'package:flutter/material.dart';
import '../constants/app_colors.dart' as colors;

/// 顶部标题 UI —— 呼吸动画 "捏爆"马虫""
/// 与原 HTML .title 完全对齐
class UiOverlay extends StatefulWidget {
  const UiOverlay({super.key});

  @override
  State<UiOverlay> createState() => _UiOverlayState();
}

class _UiOverlayState extends State<UiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // 2s 周期，与原 CSS breathe 一致
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: child,
            );
          },
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: colors.AppColors.titleWhite,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: const [
                  Shadow(
                    color: Color(0xCC000000),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              children: [
                const TextSpan(text: '捏'),
                TextSpan(
                  text: '爆',
                  style: TextStyle(
                    fontSize: 64, // 1.6倍 "爆"
                    color: colors.AppColors.titleRed,
                    shadows: [
                      Shadow(
                        color: colors.AppColors.titleRed.withAlpha(200),
                        blurRadius: 20,
                      ),
                      const Shadow(
                        color: Color(0xCC000000),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const TextSpan(text: '"马虫"'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
