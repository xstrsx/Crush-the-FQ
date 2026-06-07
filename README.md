# 💥 捏爆"马虫" — 3D 手势找不同

隔空手势操控，在一堆"冯强"方块中找出"马虫"并**握拳捏爆**。

## 🎮 玩法

张开手掌移动光标 → 对准目标 → 握拳捏爆。选错弹飞，选对膨胀爆炸 + 炫彩粒子 + 自动下一关。

## 🖥️ 平台

| 平台 | 技术 |
|------|------|
| Android | WebView |
| iOS | WKWebView |
| Windows | WebView2 |
| macOS | WKWebView |
| Web | 根目录 `index.html` |

## 🛠️ 架构

```
Flutter App
  └── 本地 HTTP 服务器 (dart:io)
        └── 离线 index.html + three.js + cannon-es + MediaPipe Hands
              └── WebView (全屏原生容器)
```

所有 JS 库和 AI 模型文件均打包在 `assets/web/` 中，安装后无需任何网络访问。

## 🚀 运行

```bash
flutter pub get
flutter run
```

## 📄 License

MIT
