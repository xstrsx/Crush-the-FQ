import 'package:flutter/material.dart';

/// GitHub 链接按钮（右下角半透明 SVG 图标）
/// 与原 HTML #github-link 样式完全对齐
class GithubButton extends StatefulWidget {
  const GithubButton({super.key});

  @override
  State<GithubButton> createState() => _GithubButtonState();
}

class _GithubButtonState extends State<GithubButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final opacity = _isHovered ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: () {
          // 打开 GitHub 链接
          // 在移动端使用 url_launcher，桌面端直接用浏览器
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: const SizedBox(
              width: 36,
              height: 36,
              child: _GitHubIcon(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 内联 GitHub SVG 图标渲染
class _GitHubIcon extends StatelessWidget {
  const _GitHubIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(36, 36),
      painter: _GitHubIconPainter(),
    );
  }
}

class _GitHubIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    // GitHub logo path data scaled to 36x36
    final s = size.width / 16.0;
    path.moveTo(8 * s, 0);
    path.cubicTo(3.58 * s, 0, 0, 3.58 * s, 0, 8 * s);
    path.cubicTo(0, 11.54 * s, 2.29 * s, 14.53 * s, 5.47 * s, 15.59 * s);
    path.cubicTo(5.87 * s, 15.66 * s, 6.02 * s, 15.42 * s, 6.02 * s, 15.21 * s);
    path.cubicTo(6.02 * s, 15.02 * s, 6.01 * s, 14.39 * s, 6.01 * s, 13.72 * s);
    path.cubicTo(4.0 * s, 14.09 * s, 3.48 * s, 13.23 * s, 3.32 * s, 12.78 * s);
    path.cubicTo(3.23 * s, 12.55 * s, 2.84 * s, 11.84 * s, 2.5 * s, 11.65 * s);
    path.cubicTo(2.22 * s, 11.5 * s, 1.82 * s, 11.13 * s, 2.49 * s, 11.12 * s);
    path.cubicTo(3.12 * s, 11.11 * s, 3.57 * s, 11.7 * s, 3.72 * s, 11.94 * s);
    path.cubicTo(4.44 * s, 13.15 * s, 5.59 * s, 12.81 * s, 6.05 * s, 12.6 * s);
    path.cubicTo(6.12 * s, 12.08 * s, 6.33 * s, 11.73 * s, 6.56 * s, 11.53 * s);
    path.cubicTo(4.78 * s, 11.33 * s, 2.92 * s, 10.64 * s, 2.92 * s, 7.58 * s);
    path.cubicTo(2.92 * s, 6.71 * s, 3.23 * s, 5.99 * s, 3.74 * s, 5.43 * s);
    path.cubicTo(3.66 * s, 5.23 * s, 3.38 * s, 4.41 * s, 3.82 * s, 3.31 * s);
    path.cubicTo(3.82 * s, 3.31 * s, 4.49 * s, 3.1 * s, 6.02 * s, 4.13 * s);
    path.cubicTo(6.66 * s, 3.95 * s, 7.34 * s, 3.86 * s, 8.02 * s, 3.86 * s);
    path.cubicTo(8.7 * s, 3.86 * s, 9.38 * s, 3.95 * s, 10.02 * s, 4.13 * s);
    path.cubicTo(11.55 * s, 3.09 * s, 12.22 * s, 3.31 * s, 12.22 * s, 3.31 * s);
    path.cubicTo(12.66 * s, 4.41 * s, 12.38 * s, 5.23 * s, 12.3 * s, 5.43 * s);
    path.cubicTo(12.81 * s, 5.99 * s, 13.12 * s, 6.7 * s, 13.12 * s, 7.58 * s);
    path.cubicTo(13.12 * s, 10.65 * s, 11.25 * s, 11.33 * s, 9.47 * s, 11.53 * s);
    path.cubicTo(9.76 * s, 11.78 * s, 10.01 * s, 12.26 * s, 10.01 * s, 13.01 * s);
    path.cubicTo(10.01 * s, 14.08 * s, 10.0 * s, 14.94 * s, 10.0 * s, 15.21 * s);
    path.cubicTo(10.0 * s, 15.42 * s, 10.15 * s, 15.67 * s, 10.55 * s, 15.59 * s);
    path.cubicTo(13.71 * s, 14.53 * s, 16.0 * s, 11.53 * s, 16.0 * s, 8.0 * s);
    path.cubicTo(16.0 * s, 3.58 * s, 12.42 * s, 0, 8.0 * s, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
