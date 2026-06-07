# 💥 捏爆"马虫" — 3D 手势找不同

基于摄像头 + AI 手势识别的 3D 物理休闲游戏。隔空用手势操控，在一堆"冯强"方块中找出"马虫"并**握拳捏爆**。

## 🎮 玩法

张开手掌移动光标 → 对准目标方块 → **握拳捏爆**。选错方块会弹飞变红，选对则触发膨胀爆炸 + 炫彩粒子 + 自动下一关。

## 🖥️ 平台支持

| 平台 | 状态 |
|------|------|
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web | 使用根目录 `index.html`（原生网页版） |

## 🚀 快速开始

```bash
flutter pub get
flutter run          # 自动检测已连接设备
flutter run -d windows   # 指定平台
```

构建发布包：

```bash
flutter build apk --release       # Android
flutter build windows --release   # Windows
flutter build macos --release     # macOS
flutter build linux --release     # Linux
```

## 🤖 CI/CD

push 到 `main` 分支自动触发 5 平台构建，全部成功后自动创建 GitHub Release 并上传所有安装包。

> 确保仓库 Settings → Actions → General → Workflow permissions 设为 **Read and write permissions**。

## 🛠️ 技术栈

- **Flutter** — 跨平台 UI 框架
- **hand_detection** — TFLite 离线手势识别（21 关键点，模型内置）
- **自研 3D 软渲染器** — CustomPainter 透视投影 + 光照
- **自研刚体物理引擎** — 重力/碰撞/四元数旋转
- **camera + permission_handler** — 摄像头访问与权限

## ⚠️ 注意事项

- 首次运行需授予摄像头权限
- Web 端摄像头仅 HTTPS / localhost 环境可用
- iOS 真机安装需 Apple Developer 账号签名

## 📄 License

MIT
