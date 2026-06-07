import 'package:flutter/material.dart';
import '../constants/app_colors.dart' as colors;
import '../constants/app_strings.dart' as strings;

/// 加载画面 —— 与原 HTML #loading 完全对齐
class LoadingOverlay extends StatelessWidget {
  final bool isInitializing;
  final String? errorMessage;
  final VoidCallback? onStart;

  const LoadingOverlay({
    super.key,
    required this.isInitializing,
    this.errorMessage,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromARGB(
        (255 * 0.85).round(), 0, 0, 0,
      ), // rgba(0,0,0,0.85)
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 副标题
            const Text(
              strings.AppStrings.subtitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // 开始按钮 / 初始化中状态
            if (!isInitializing) ...[
              // 开始按钮
              if (onStart != null)
                GestureDetector(
                  onTap: onStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          colors.AppColors.btnGradientStart,
                          colors.AppColors.btnGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: colors.AppColors.btnGradientStart.withAlpha(128),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      strings.AppStrings.startBtn,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // 错误重试
              if (errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],
            ] else ...[
              // 加载中指示器
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF3B30),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                strings.AppStrings.loadingText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 19,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
