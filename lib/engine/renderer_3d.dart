import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:vector_math/vector_math.dart' as vm;
import '../constants/app_dimens.dart' as dims;

/// 3D 顶点数据
class Vertex3D {
  final vm.Vector3 position;
  final vm.Vector3 normal;

  const Vertex3D(this.position, this.normal);
}

/// 3D 面数据
class Face3D {
  final List<Vertex3D> vertices;
  final int color;
  final int textureColor;

  const Face3D({
    required this.vertices,
    required this.color,
    this.textureColor = 0xFFF0F0F0,
  });
}

/// 渲染对象（立方体）
class RenderCube {
  final List<Face3D> faces;
  vm.Vector3 position;
  vm.Quaternion rotation;
  vm.Vector3 scale;
  bool visible;

  RenderCube({
    required this.faces,
    required this.position,
    required this.rotation,
    vm.Vector3? scale,
    this.visible = true,
  }) : scale = scale ?? vm.Vector3(1, 1, 1);
}

/// 渲染粒子
class RenderParticle {
  vm.Vector3 position;
  double scale;
  final int color;
  final bool isSphere;
  vm.Quaternion rotation;

  RenderParticle({
    required this.position,
    required this.scale,
    required this.color,
    required this.isSphere,
    vm.Quaternion? rotation,
  }) : rotation = rotation ?? vm.Quaternion.identity();
}

/// 3D 软渲染器 —— 用 CustomPainter 实现纯 Flutter 3D 渲染
/// 替代 Three.js，所有计算本地完成，不依赖 WebGL
class Renderer3D {
  final vm.Matrix4 _projectionMatrix = vm.Matrix4.identity();
  final vm.Matrix4 _viewMatrix = vm.Matrix4.identity();

  // 光照方向（归一化）
  static final vm.Vector3 _lightDir = vm.Vector3(
    dims.AppDimens.dirLightX,
    dims.AppDimens.dirLightY,
    dims.AppDimens.dirLightZ,
  )..normalize();

  static const double _ambientStrength = 0.6;

  /// 更新投影矩阵
  void updateProjection(double aspectRatio) {
    final fovRad = dims.AppDimens.cameraFov * (math.pi / 180.0);
    _makePerspectiveMatrix(
      _projectionMatrix,
      fovRad,
      aspectRatio,
      dims.AppDimens.cameraNear,
      dims.AppDimens.cameraFar,
    );
  }

  /// 更新视图矩阵
  void updateView() {
    final eye = vm.Vector3(0, dims.AppDimens.cameraY, dims.AppDimens.cameraZ);
    final target = vm.Vector3(0, dims.AppDimens.cameraLookY, 0);
    final up = vm.Vector3(0, 1, 0);
    _makeViewMatrix(_viewMatrix, eye, target, up);
  }

  /// 渲染整个场景
  void render({
    required ui.Canvas canvas,
    required ui.Size canvasSize,
    required List<RenderCube> cubes,
    required List<RenderParticle> particles,
    required vm.Vector3 cursorPos,
    required double cursorScale,
    required int cursorColor,
    required bool showGrid,
  }) {
    final w = canvasSize.width;
    final h = canvasSize.height;

    updateProjection(w / h);
    updateView();

    final vpMatrix = _projectionMatrix * _viewMatrix;

    // 地板网格（先画）
    if (showGrid) {
      _renderFloorGrid(canvas, w, h, vpMatrix);
    }

    // 立方体面
    for (final cube in cubes) {
      if (!cube.visible) continue;
      final modelMatrix = _computeModelMatrix(cube);
      for (final face in cube.faces) {
        _renderFace(canvas, w, h, face, modelMatrix, vpMatrix);
      }
    }

    // 粒子（后画，在所有几何体之上）
    for (final p in particles) {
      _renderParticle(canvas, w, h, p, vpMatrix);
    }

    // 3D 光标
    _renderCursor(canvas, w, h, cursorPos, vpMatrix, cursorScale, cursorColor);
  }

  /// 计算模型矩阵
  vm.Matrix4 _computeModelMatrix(RenderCube cube) {
    final mat = vm.Matrix4.identity();
    mat.translateByVector3(cube.position);
    final rotMat = cube.rotation.asRotationMatrix();
    // 将 3x3 旋转矩阵嵌入 4x4
    final rot4 = vm.Matrix4(
      rotMat.entry(0, 0), rotMat.entry(0, 1), rotMat.entry(0, 2), 0,
      rotMat.entry(1, 0), rotMat.entry(1, 1), rotMat.entry(1, 2), 0,
      rotMat.entry(2, 0), rotMat.entry(2, 1), rotMat.entry(2, 2), 0,
      0, 0, 0, 1,
    );
    mat.multiply(rot4);
    mat.scaleByVector3(cube.scale);
    return mat;
  }

  /// 光照计算
  int _applyLighting(int baseColor, vm.Vector3 worldNormal) {
    final n = worldNormal.normalized();
    final diffuse = math.max(0.0, n.dot(_lightDir));
    final finalDiffuse = _ambientStrength + (1 - _ambientStrength) * diffuse;

    final r = (((baseColor >> 16) & 0xFF) * finalDiffuse).round().clamp(0, 255);
    final g = (((baseColor >> 8) & 0xFF) * finalDiffuse).round().clamp(0, 255);
    final b = ((baseColor & 0xFF) * finalDiffuse).round().clamp(0, 255);

    return (0xFF << 24) | (r << 16) | (g << 8) | b;
  }

  /// 渲染单个面
  void _renderFace(ui.Canvas canvas, double w, double h, Face3D face,
      vm.Matrix4 modelMatrix, vm.Matrix4 vpMatrix) {
    final screenPoints = <ui.Offset>[];
    final worldNormal = vm.Vector3.zero();

    for (final vert in face.vertices) {
      // 世界空间位置
      final worldPos = _transform3(modelMatrix, vert.position);
      worldNormal.add(_transform3Normal(modelMatrix, vert.normal));

      // 裁剪空间
      final clipPos = _transform4(vpMatrix, vm.Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0));
      if (clipPos.w <= 0) return;

      final ndcX = clipPos.x / clipPos.w;
      final ndcY = clipPos.y / clipPos.w;

      screenPoints.add(ui.Offset(
        (ndcX + 1) * 0.5 * w,
        (1 - ndcY) * 0.5 * h,
      ));
    }

    if (screenPoints.length < 3) return;

    // 背面剔除
    final edge1 = vm.Vector3(
      screenPoints[1].dx - screenPoints[0].dx,
      screenPoints[1].dy - screenPoints[0].dy,
      0,
    );
    final edge2 = vm.Vector3(
      screenPoints[2].dx - screenPoints[0].dx,
      screenPoints[2].dy - screenPoints[0].dy,
      0,
    );
    if (edge1.cross(edge2).z >= 0) return;

    // 光照着色
    final litColor = _applyLighting(face.color, worldNormal);

    // 绘制
    final path = ui.Path();
    path.moveTo(screenPoints[0].dx, screenPoints[0].dy);
    for (int i = 1; i < screenPoints.length; i++) {
      path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }
    path.close();

    canvas.drawPath(
      path,
      ui.Paint()
        ..color = ui.Color(litColor)
        ..style = ui.PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      ui.Paint()
        ..color = const ui.Color(0xFFCCCCCC)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  /// 渲染粒子
  void _renderParticle(ui.Canvas canvas, double w, double h,
      RenderParticle p, vm.Matrix4 vpMatrix) {
    final clipPos = _transform4(
        vpMatrix, vm.Vector4(p.position.x, p.position.y, p.position.z, 1.0));
    if (clipPos.w <= 0) return;

    final sx = (clipPos.x / clipPos.w + 1) * 0.5 * w;
    final sy = (1 - clipPos.y / clipPos.w) * 0.5 * h;
    final radius = 5.0 * p.scale;

    final paint = ui.Paint()
      ..color = ui.Color(p.color)
      ..style = ui.PaintingStyle.fill;

    if (p.isSphere) {
      canvas.drawCircle(ui.Offset(sx, sy), radius, paint);
    } else {
      canvas.drawRect(
        ui.Rect.fromCenter(
            center: ui.Offset(sx, sy), width: radius * 2, height: radius * 2),
        paint,
      );
    }
  }

  /// 渲染 3D 光标
  void _renderCursor(ui.Canvas canvas, double w, double h, vm.Vector3 cursorPos,
      vm.Matrix4 vpMatrix, double scale, int color) {
    final clipPos = _transform4(
        vpMatrix, vm.Vector4(cursorPos.x, cursorPos.y, cursorPos.z, 1.0));
    if (clipPos.w <= 0) return;

    final sx = (clipPos.x / clipPos.w + 1) * 0.5 * w;
    final sy = (1 - clipPos.y / clipPos.w) * 0.5 * h;
    final radius = 12.0 * scale;

    canvas.drawCircle(
      ui.Offset(sx, sy),
      radius,
      ui.Paint()
        ..color = ui.Color(color)
        ..style = ui.PaintingStyle.fill,
    );
  }

  /// 渲染地板网格
  void _renderFloorGrid(
      ui.Canvas canvas, double w, double h, vm.Matrix4 vpMatrix) {
    final paint = ui.Paint()
      ..color = const ui.Color(0xFF444444)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = -20; i <= 20; i++) {
      final lineX = i * 2.0;
      final p1 = _worldToScreen(vm.Vector3(lineX, 0.01, -40), vpMatrix, w, h);
      final p2 = _worldToScreen(vm.Vector3(lineX, 0.01, 40), vpMatrix, w, h);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }

      final lineZ = i * 2.0;
      final p3 = _worldToScreen(vm.Vector3(-40, 0.01, lineZ), vpMatrix, w, h);
      final p4 = _worldToScreen(vm.Vector3(40, 0.01, lineZ), vpMatrix, w, h);
      if (p3 != null && p4 != null) {
        canvas.drawLine(p3, p4, paint);
      }
    }
  }

  /// 世界坐标 → 屏幕坐标
  ui.Offset? _worldToScreen(
      vm.Vector3 worldPos, vm.Matrix4 vpMatrix, double w, double h) {
    final clipPos =
        _transform4(vpMatrix, vm.Vector4(worldPos.x, worldPos.y, worldPos.z, 1.0));
    if (clipPos.w <= 0) return null;
    return ui.Offset(
      (clipPos.x / clipPos.w + 1) * 0.5 * w,
      (1 - clipPos.y / clipPos.w) * 0.5 * h,
    );
  }

  // ---- 矩阵运算辅助 ----

  vm.Vector3 _transform3(vm.Matrix4 mat, vm.Vector3 v) {
    final result = mat.transform(vm.Vector4(v.x, v.y, v.z, 1.0));
    return vm.Vector3(result.x, result.y, result.z);
  }

  vm.Vector3 _transform3Normal(vm.Matrix4 mat, vm.Vector3 n) {
    final result = mat.transform(vm.Vector4(n.x, n.y, n.z, 0.0));
    return vm.Vector3(result.x, result.y, result.z);
  }

  vm.Vector4 _transform4(vm.Matrix4 mat, vm.Vector4 v) {
    return mat.transform(v);
  }

  static void _makePerspectiveMatrix(
      vm.Matrix4 mat, double fovY, double aspect, double near, double far) {
    final f = 1.0 / math.tan(fovY / 2.0);
    final nf = 1.0 / (near - far);
    mat
      ..setEntry(0, 0, f / aspect)
      ..setEntry(1, 1, f)
      ..setEntry(2, 2, (far + near) * nf)
      ..setEntry(2, 3, 2 * far * near * nf)
      ..setEntry(3, 2, -1)
      ..setEntry(3, 3, 0);
  }

  static void _makeViewMatrix(
      vm.Matrix4 mat, vm.Vector3 eye, vm.Vector3 target, vm.Vector3 up) {
    final zAxis = (eye - target)..normalize();
    final xAxis = up.cross(zAxis)..normalize();
    final yAxis = zAxis.cross(xAxis);

    mat
      ..setEntry(0, 0, xAxis.x)
      ..setEntry(0, 1, xAxis.y)
      ..setEntry(0, 2, xAxis.z)
      ..setEntry(0, 3, -xAxis.dot(eye))
      ..setEntry(1, 0, yAxis.x)
      ..setEntry(1, 1, yAxis.y)
      ..setEntry(1, 2, yAxis.z)
      ..setEntry(1, 3, -yAxis.dot(eye))
      ..setEntry(2, 0, zAxis.x)
      ..setEntry(2, 1, zAxis.y)
      ..setEntry(2, 2, zAxis.z)
      ..setEntry(2, 3, -zAxis.dot(eye))
      ..setEntry(3, 0, 0)
      ..setEntry(3, 1, 0)
      ..setEntry(3, 2, 0)
      ..setEntry(3, 3, 1);
  }
}
