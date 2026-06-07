import 'package:vector_math/vector_math.dart' as vm;
import '../constants/app_dimens.dart' as dims;
import 'renderer_3d.dart';

/// 立方体网格生成器 — 创建 6 面立方体
class CubeMeshBuilder {
  /// 构建标准立方体的 6 个面
  static List<Face3D> buildCubeFaces({bool isTarget = false}) {
    final h = dims.AppDimens.cubeHalfSize;
    final faceColor = isTarget ? 0xFFFFE0E0 : 0xFFF0F0F0;

    return [
      // 前面 (+Z)
      _buildFace(
        [vm.Vector3(-h, -h, h), vm.Vector3(h, -h, h), vm.Vector3(h, h, h), vm.Vector3(-h, h, h)],
        vm.Vector3(0, 0, 1), faceColor,
      ),
      // 后面 (-Z)
      _buildFace(
        [vm.Vector3(h, -h, -h), vm.Vector3(-h, -h, -h), vm.Vector3(-h, h, -h), vm.Vector3(h, h, -h)],
        vm.Vector3(0, 0, -1), faceColor,
      ),
      // 右面 (+X)
      _buildFace(
        [vm.Vector3(h, -h, h), vm.Vector3(h, -h, -h), vm.Vector3(h, h, -h), vm.Vector3(h, h, h)],
        vm.Vector3(1, 0, 0), faceColor,
      ),
      // 左面 (-X)
      _buildFace(
        [vm.Vector3(-h, -h, -h), vm.Vector3(-h, -h, h), vm.Vector3(-h, h, h), vm.Vector3(-h, h, -h)],
        vm.Vector3(-1, 0, 0), faceColor,
      ),
      // 顶面 (+Y)
      _buildFace(
        [vm.Vector3(-h, h, h), vm.Vector3(h, h, h), vm.Vector3(h, h, -h), vm.Vector3(-h, h, -h)],
        vm.Vector3(0, 1, 0), faceColor,
      ),
      // 底面 (-Y)
      _buildFace(
        [vm.Vector3(-h, -h, -h), vm.Vector3(h, -h, -h), vm.Vector3(h, -h, h), vm.Vector3(-h, -h, h)],
        vm.Vector3(0, -1, 0), faceColor,
      ),
    ];
  }

  static Face3D _buildFace(List<vm.Vector3> positions, vm.Vector3 normal, int color) {
    return Face3D(
      vertices: positions.map((p) => Vertex3D(p, normal)).toList(),
      color: color,
    );
  }
}
