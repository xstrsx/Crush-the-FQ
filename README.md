# 💥 捏爆"马虫" - 3D 手势交互找不同游戏

> **Flutter 原生重构版** | 全平台离线运行 | GitHub Actions 自动构建发布

一个基于 MediaPipe 风格手部关键点检测 + 3D 软渲染 + 自研物理引擎的创意小游戏。在一场不断掉落的方块雨中，找出唯一带有"马虫"字样的方块，并通过真实的**手部握拳动作**将其捏爆，享受极具张力的膨胀撑破与炫彩粒子爆炸特效！

---

## ✨ 核心亮点

- 🖐️ **AI 实时手势捕捉**：基于 TFLite 离线手部关键点检测（`hand_detection`），模型内置在安装包中，纯离线运行，无需网络。
- 🧊 **自研 3D 物理引擎**：自研刚体动力学、碰撞检测、四元数旋转，替代 cannon-es，纯 Dart 实现。
- 🎨 **CustomPainter 软渲染**：基于 Flutter `CustomPainter` 的 3D 透视投影渲染，替代 Three.js/WebGL，全本地计算。
- 🎆 **炫酷视觉特效**：目标方块"吸水膨胀 → 圆润撑破 → 炫彩霓虹粒子炸裂"，与原 HTML 版 100% 对齐。
- 📱 **全平台覆盖**：Android / iOS / Windows / macOS / Linux / Web 六端统一代码库。
- 🔒 **完全离线**：除 Flutter 官方 SDK 外，所有依赖和模型全部内置在安装包中。

## 🎮 玩法说明

1. **允许摄像头权限**：进入游戏后允许摄像头访问。
2. **张开手掌（瞄准）**：对着摄像头移动手掌，控制屏幕上的绿色光标准星。当光标停留在方块上时，方块会高亮。
3. **用力握拳（捏爆）**：
   - ❌ **选错（冯强）**：方块变成红色并剧烈弹跳。
   - ✅ **选对（马虫）**：方块膨胀成球 → 撑破炸裂出炫彩粒子 → 自动进入下一关！

## 📁 项目结构

```
├── lib/
│   ├── main.dart                          # 应用入口
│   ├── constants/
│   │   ├── app_colors.dart                # 全局颜色常量（与原 HTML 完全对齐）
│   │   ├── app_strings.dart               # 全局字符串常量
│   │   └── app_dimens.dart                # 全局尺寸与动画参数
│   ├── models/
│   │   ├── game_cube.dart                 # 游戏立方体数据模型
│   │   └── explosion_particle.dart        # 爆破粒子数据模型
│   ├── services/
│   │   ├── camera_service.dart            # 摄像头管理服务
│   │   ├── hand_tracking_service.dart     # 离线手势识别服务（TFLite）
│   │   └── physics_engine.dart            # 自研 3D 刚体物理引擎
│   ├── engine/
│   │   ├── renderer_3d.dart               # CustomPainter 3D 软渲染器
│   │   └── cube_mesh.dart                 # 立方体 6 面网格生成器
│   ├── screens/
│   │   └── game_screen.dart               # 游戏主屏幕（状态管理+渲染循环）
│   ├── widgets/
│   │   ├── ui_overlay.dart                # 顶部标题呼吸动画
│   │   ├── loading_overlay.dart           # 加载画面
│   │   ├── debug_panel.dart               # 调试面板
│   │   └── github_button.dart             # GitHub 链接按钮
│   └── utils/
│       └── texture_generator.dart         # 方块纹理离屏生成
├── assets/models/                         # 离线 ML 模型目录（hand_detection 内置）
├── .github/workflows/
│   └── build_and_release.yml              # 全平台构建+自动发布流水线
├── android/                               # Android 原生配置（含摄像头权限）
├── ios/                                   # iOS 原生配置（含摄像头权限描述）
├── macos/                                 # macOS 原生配置（含摄像头权限）
├── windows/                               # Windows 原生配置
├── linux/                                 # Linux 原生配置
├── web/                                   # Flutter Web 配置
└── pubspec.yaml                           # Flutter 项目依赖配置
```

## 🚀 本地运行

### 前置要求
- Flutter SDK >= 3.12.1（最新稳定版）
- Android Studio / Xcode（对应平台）
- 物理设备或模拟器（需摄像头）

### 运行步骤

```bash
# 1. 进入项目目录
cd Crush-the-FQ

# 2. 获取依赖（首次运行）
flutter pub get

# 3. 检查环境配置
flutter doctor

# 4. 运行（自动选择已连接的设备）
flutter run

# 指定平台运行：
flutter run -d android      # Android
flutter run -d ios          # iOS
flutter run -d macos        # macOS 桌面
flutter run -d windows      # Windows 桌面
flutter run -d linux        # Linux 桌面
flutter run -d chrome       # Web

# 构建发布包：
flutter build apk --release           # Android APK
flutter build ios --release           # iOS
flutter build macos --release         # macOS
flutter build windows --release       # Windows
flutter build linux --release         # Linux
flutter build web --release           # Web
```

## 🔧 GitHub Actions 自动构建 & 发布

### 触发规则
- **自动触发**：向 `main` 分支推送代码或合并 PR
- **手动触发**：在 Actions 页面点击 `workflow_dispatch`

### 构建目标

| 平台 | 产物 | 运行器 |
|------|------|------|
| 🤖 Android | `.apk` | `ubuntu-latest` |
| 🍎 iOS | `.zip` (.app) | `macos-latest` |
| 🪟 Windows | `.zip` (便携包) | `windows-latest` |
| 🍏 macOS | `.zip` (.app) | `macos-latest` |
| 🐧 Linux | `.tar.gz` (便携包) | `ubuntu-latest` |
| 🌐 Web | `.zip` (静态部署包) | `ubuntu-latest` |

### Release 发布
- 所有 6 个平台构建成功后，自动创建 GitHub Release
- Release 标签使用 `v1.0.{run_number}` 格式，每次构建唯一
- 所有平台安装包自动上传至 Release 附件区
- 需在 GitHub 仓库 `Settings → Actions → General` 中确保 **Read and write permissions** 已开启

### 添加 GitHub Secrets（可选）
```bash
# 如需 Android 签名，在仓库 Settings → Secrets 中添加：
KEYSTORE_BASE64      # Base64 编码的 keystore 文件
KEYSTORE_PASSWORD    # Keystore 密码
KEY_ALIAS            # Key alias
KEY_PASSWORD         # Key 密码
```

## 🛠️ 技术栈

| 原 HTML 版 | Flutter 重构版 |
|---|---|
| Three.js (WebGL 3D) | CustomPainter 自研 3D 软渲染器 |
| cannon-es (JS 物理) | 自研 Dart 刚体物理引擎 |
| MediaPipe Hands (CDN) | `hand_detection` (TFLite 离线，包内置) |
| HTML Canvas 2D (纹理) | `dart:ui` Canvas 离屏渲染 |
| ES Module importmap | `pubspec.yaml` 本地依赖 |

### 关键依赖包
- `hand_detection: ^3.1.0` — 离线手势识别（21 关键点 + 7 种手势，模型内置）
- `camera: ^0.11.1` — 摄像头访问
- `permission_handler: ^11.3.1` — 权限管理
- `vector_math: ^2.1.4` — 3D 向量/矩阵/四元数运算

## ⚠️ 注意事项

1. **摄像头权限**：首次运行需授予摄像头权限，否则手势识别无法工作。
2. **HTTPS 环境（Web 端）**：浏览器安全策略要求摄像头仅在 HTTPS 或 localhost 下可用。
3. **iOS 真机签名**：iOS 真机安装需 Apple Developer 账号签名，CI 构建的 .app 包为未签名版本。
4. **Android ML Kit 模型**：`hand_detection` 包的 TFLite 模型已随包内置，安装后无需任何网络下载。
5. **桌面端手势**：Windows/macOS/Linux 桌面端使用笔记本内置摄像头或外接 USB 摄像头进行手势识别。

## 📄 License

MIT License — 详见 [LICENSE](LICENSE) 文件。

---

🤖 使用 Flutter 重构 | CI/CD by GitHub Actions
