import 'dart:ui';

/// 游戏立方体数据模型
class GameCube {
  /// 是否为"马虫"目标方块
  final bool isTarget;

  /// 是否已被捏爆
  bool isShattered;

  // 3D 变换状态
  double posX, posY, posZ;
  double rotX, rotY, rotZ, rotW; // 四元数旋转
  double velX, velY, velZ;
  double angVelX, angVelY, angVelZ;

  /// 纹理（Canvas 离屏渲染生成）
  final Image? texture;

  GameCube({
    required this.isTarget,
    this.isShattered = false,
    this.posX = 0,
    this.posY = 0,
    this.posZ = 0,
    this.rotX = 0,
    this.rotY = 0,
    this.rotZ = 0,
    this.rotW = 1,
    this.velX = 0,
    this.velY = 0,
    this.velZ = 0,
    this.angVelX = 0,
    this.angVelY = 0,
    this.angVelZ = 0,
    this.texture,
  });
}
