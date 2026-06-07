import 'dart:math' as math;
import 'package:vector_math/vector_math.dart' as vm;
import '../constants/app_dimens.dart' as dims;
import '../models/game_cube.dart';

/// 纯离线物理引擎 —— 替代 cannon-es 功能
/// 实现刚体动力学、重力、地面碰撞、墙体碰撞
class PhysicsEngine {
  final List<GameCube> _cubes = [];
  final vm.Vector3 _gravity = vm.Vector3(0, dims.AppDimens.gravity, 0);

  // 墙体包围盒（用于碰撞检测）
  final List<_Wall> _walls = [];

  // 地面 Y 坐标
  final double _groundY = 0.0;

  PhysicsEngine() {
    _initWalls();
  }

  void _initWalls() {
    // 与原网页墙体位置一致
    _walls.addAll([
      _Wall(center: vm.Vector3(0, 15, -20), halfExtents: vm.Vector3(40, 30, 1)),
      _Wall(center: vm.Vector3(0, 15, 15), halfExtents: vm.Vector3(40, 30, 1)),
      _Wall(center: vm.Vector3(-18, 15, 0), halfExtents: vm.Vector3(1, 30, 40)),
      _Wall(center: vm.Vector3(18, 15, 0), halfExtents: vm.Vector3(1, 30, 40)),
    ]);
  }

  /// 注册立方体到物理世界
  void addCube(GameCube cube) {
    _cubes.add(cube);
  }

  /// 移除立方体
  void removeCube(GameCube cube) {
    _cubes.remove(cube);
  }

  /// 清空所有立方体
  void clear() {
    _cubes.clear();
  }

  /// 步进物理模拟
  /// [dt] 时间步长（秒）
  /// [subSteps] 子步数，提高稳定性
  void step(double dt, {int subSteps = 3}) {
    if (_cubes.isEmpty) return;

    final subDt = dt / subSteps;

    for (int s = 0; s < subSteps; s++) {
      for (final cube in _cubes) {
        if (cube.isShattered) continue;

        // 应用重力
        cube.velY += _gravity.y * subDt;

        // 更新位置
        cube.posX += cube.velX * subDt;
        cube.posY += cube.velY * subDt;
        cube.posZ += cube.velZ * subDt;

        // 线性阻尼
        final damp = math.pow(1 - dims.AppDimens.linearDamping, subDt).toDouble();
        cube.velX *= damp;
        cube.velY *= damp;
        cube.velZ *= damp;

        // 角速度阻尼
        final angDamp = math.pow(1 - dims.AppDimens.angularDamping, subDt).toDouble();
        cube.angVelX *= angDamp;
        cube.angVelY *= angDamp;
        cube.angVelZ *= angDamp;

        // 更新旋转（四元数 + 角速度）
        _updateRotation(cube, subDt);

        // 地面碰撞
        _resolveGroundCollision(cube);

        // 墙体碰撞
        _resolveWallCollisions(cube);
      }
    }
  }

  /// 使用角速度更新四元数旋转
  void _updateRotation(GameCube cube, double dt) {
    final omega = vm.Vector3(cube.angVelX, cube.angVelY, cube.angVelZ);
    final omegaLen = omega.length;
    if (omegaLen < 0.0001) return;

    // 四元数微分
    final q = vm.Quaternion(cube.rotX, cube.rotY, cube.rotZ, cube.rotW);
    final halfAngle = omegaLen * dt * 0.5;
    final axis = omega / omegaLen;
    final dq = vm.Quaternion.axisAngle(axis, halfAngle);

    final newQ = q * dq;
    newQ.normalize();

    cube.rotX = newQ.x;
    cube.rotY = newQ.y;
    cube.rotZ = newQ.z;
    cube.rotW = newQ.w;
  }

  /// 地面碰撞检测与响应
  void _resolveGroundCollision(GameCube cube) {
    final halfSize = dims.AppDimens.cubeHalfSize;
    final bottom = cube.posY - halfSize;

    if (bottom < _groundY) {
      cube.posY = _groundY + halfSize;

      // 反弹并衰减
      if (cube.velY < 0) {
        cube.velY = -cube.velY * dims.AppDimens.restitution;
        // 摩擦：减少水平速度
        cube.velX *= (1 - dims.AppDimens.friction * 0.1);
        cube.velZ *= (1 - dims.AppDimens.friction * 0.1);

        // 缓慢到停止
        if (cube.velY.abs() < 0.5) {
          cube.velY = 0;
        }
      }
    }
  }

  /// 墙体碰撞检测与响应
  void _resolveWallCollisions(GameCube cube) {
    final halfSize = dims.AppDimens.cubeHalfSize;
    final pos = vm.Vector3(cube.posX, cube.posY, cube.posZ);

    for (final wall in _walls) {
      // AABB vs AABB
      final dx = (pos.x - wall.center.x).abs();
      final dy = (pos.y - wall.center.y).abs();
      final dz = (pos.z - wall.center.z).abs();

      final overlapX = dx - (halfSize + wall.halfExtents.x);
      final overlapY = dy - (halfSize + wall.halfExtents.y);
      final overlapZ = dz - (halfSize + wall.halfExtents.z);

      if (overlapX < 0 && overlapY < 0 && overlapZ < 0) {
        // 找出最小重叠轴并推离
        final overlaps = [
          (_Overlap(-overlapX, 0)),
          (_Overlap(-overlapY, 1)),
          (_Overlap(-overlapZ, 2)),
        ];
        overlaps.sort((a, b) => b.depth.compareTo(a.depth));
        final best = overlaps.first;

        switch (best.axis) {
          case 0: // X轴
            cube.posX += (pos.x > wall.center.x ? 1 : -1) * best.depth;
            cube.velX = -cube.velX * dims.AppDimens.restitution;
            break;
          case 1: // Y轴
            cube.posY += (pos.y > wall.center.y ? 1 : -1) * best.depth;
            cube.velY = -cube.velY * dims.AppDimens.restitution;
            break;
          case 2: // Z轴
            cube.posZ += (pos.z > wall.center.z ? 1 : -1) * best.depth;
            cube.velZ = -cube.velZ * dims.AppDimens.restitution;
            break;
        }
      }
    }
  }
}

/// 墙体定义（AABB 包围盒）
class _Wall {
  final vm.Vector3 center;
  final vm.Vector3 halfExtents;

  _Wall({required this.center, required this.halfExtents});
}

/// 穿透深度 + 轴向
class _Overlap {
  final double depth;
  final int axis; // 0=x, 1=y, 2=z
  const _Overlap(this.depth, this.axis);
}
