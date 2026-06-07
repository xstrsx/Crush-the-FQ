/// 爆破粒子数据模型
class ExplosionParticle {
  double posX, posY, posZ;
  double velX, velY, velZ;
  double rotX, rotY, rotZ;
  double scale;
  double life;
  final int colorValue; // ARGB
  final bool isSphere; // 球形还是方形粒子

  ExplosionParticle({
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.velX,
    required this.velY,
    required this.velZ,
    required this.colorValue,
    required this.isSphere,
    this.rotX = 0,
    this.rotY = 0,
    this.rotZ = 0,
    this.scale = 1.0,
    this.life = 1.0,
  });
}
