/// 全局尺寸与动画参数常量 —— 与原 HTML 完全对齐
class AppDimens {
  AppDimens._();

  // 3D 场景
  static const double cubeSize = 3.0;
  static const double cubeHalfSize = 1.5;
  static const double cursorRadius = 0.6;
  static const double gridSize = 80.0;
  static const double gridDivisions = 40.0;
  static const double floorSize = 100.0;
  static const double fogNear = 30.0;
  static const double fogFar = 80.0;
  static const double cameraFov = 45.0;
  static const double cameraNear = 0.1;
  static const double cameraFar = 1000.0;
  static const double cameraY = 25.0;
  static const double cameraZ = 40.0;
  static const double cameraLookY = 5.0;

  // 物理
  static const double gravity = -40.0;
  static const double cubeMass = 5.0;
  static const double friction = 0.5;
  static const double restitution = 0.3;
  static const double linearDamping = 0.1;
  static const double angularDamping = 0.1;
  static const double spawnSpread = 25.0;
  static const double spawnHeightMin = 30.0;
  static const double spawnHeightExtra = 10.0;
  static const double spawnVelY = -10.0;

  // 立方体生成
  static const int baseCubeCount = 15;
  static const int cubesPerLevel = 3;
  static const int maxCubes = 45;
  static const double spawnInterval = 0.05; // 秒

  // 手势识别
  static const double cursorScaleDefault = 1.0;
  static const double cursorScaleFist = 0.7;
  static const double aimScaleX = 3.0;
  static const double aimScaleY = 3.0;
  static const double aimOffsetY = 0.2;
  static const int fistMinCurled = 3;

  // 动画
  static const double swellDuration = 0.8; // 秒
  static const double levelTransitionDelay = 2.0; // 秒
  static const int particleCount = 80;
  static const double particleSpeedMin = 20.0;
  static const double particleSpeedMax = 80.0;
  static const double particleLifeMin = 1.5;
  static const double particleLifeMax = 2.3;
  static const double particleGravity = 60.0;
  static const double particleScaleDecay = 0.92;
  static const double wrongFlashDuration = 0.5;
  static const double wrongBumpVelY = 15.0;

  // 纹理
  static const double texCanvasSize = 256.0;
  static const double texBorderWidth = 15.0;
  static const double texBorderInset = 8.0;

  // 墙体位置
  static const double wallThickness = 1.0;
  static const double wallHeight = 30.0;
  static const double wallWidth = 40.0;

  // 光照
  static const double dirLightX = 15.0;
  static const double dirLightY = 30.0;
  static const double dirLightZ = 15.0;
  static const double dirLightIntensity = 1.2;
  static const double ambientIntensity = 0.6;
  static const int shadowMapSize = 2048;

  // UI
  static const double titleFontSize = 2.5;
  static const double subtitleFontSize = 1.5;
  static const double btnFontSize = 1.5;
  static const double btnPaddingH = 40.0;
  static const double btnPaddingV = 15.0;
  static const double btnBorderRadius = 30.0;
  static const double debugFontSize = 14.0;
  static const double githubIconSize = 36.0;
  static const double loadingBgOpacity = 0.85;
}
