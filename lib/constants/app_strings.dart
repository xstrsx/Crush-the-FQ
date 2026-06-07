/// 全局字符串常量 —— 与原 HTML 文本完全对齐
class AppStrings {
  AppStrings._();

  static const String appTitle = '捏爆"马虫"';
  static const String subtitle = '3D 手势找不同';
  static const String startBtn = '开始游戏';
  static const String loadingText =
      '正在请求摄像头权限并加载 AI 模型...\n请允许访问摄像头（若黑屏请确保处于 HTTPS 环境）';
  static const String debugWaiting = '手势状态: 等待中...';
  static const String debugOpen = '张开 (选择)';
  static const String debugFist = '握拳 (确认)';
  static const String debugNoHand = '手势状态: 未检测到手';
  static const String normalText = '冯强';
  static const String targetText = '马虫';
  static const String githubUrl = 'https://github.com/xstrsx/Crush-the-FQ';
  static const String githubTitle = '查看 GitHub 源码';
  static const String cameraError = '无法访问摄像头，请检查权限设置';
  static const String cameraDenied = '摄像头权限被拒绝或被占用！';
}
