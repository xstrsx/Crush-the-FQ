import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../constants/app_colors.dart' as colors;
import '../constants/app_dimens.dart' as dims;
import '../constants/app_strings.dart' as strings;
import '../models/explosion_particle.dart';
import '../models/game_cube.dart';
import '../services/camera_service.dart';
import '../services/hand_tracking_service.dart';
import '../services/physics_engine.dart';
import '../utils/texture_generator.dart';
import '../widgets/debug_panel.dart';
import '../widgets/github_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/ui_overlay.dart';

/// 游戏状态
enum GameState { loading, initializing, playing, levelTransition }

/// 游戏主屏幕
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  // ===== 核心服务 =====
  final CameraService _cameraService = CameraService();
  final HandTrackingService _handTrackingService = HandTrackingService();
  final PhysicsEngine _physicsEngine = PhysicsEngine();

  // ===== 游戏数据 =====
  final List<GameCube> _cubes = [];
  final List<ExplosionParticle> _particles = [];
  GameState _gameState = GameState.loading;
  int _level = 1;
  bool _isAnimatingLevel = false;

  // ===== 手势状态 =====
  HandGesture _currentGesture = HandGesture.none;
  bool _wasFist = false;
  double _cursorX = 0;
  double _cursorY = 0;

  // ===== 纹理缓存 =====
  ui.Image? _texNormal;
  ui.Image? _texTarget;

  // ===== 3D 光标 =====
  vm.Vector3 _cursorWorldPos = vm.Vector3(0, 5, 0);
  GameCube? _hoveredCube;

  // ===== 游戏循环 =====
  Ticker? _gameTicker;
  double _lastTime = 0;

  // ===== 错误 =====
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateTextures();
  }

  @override
  void dispose() {
    _gameTicker?.stop();
    _cameraService.dispose();
    _handTrackingService.dispose();
    super.dispose();
  }

  Future<void> _generateTextures() async {
    _texNormal = await TextureGenerator.generate(strings.AppStrings.normalText);
    _texTarget = await TextureGenerator.generate(strings.AppStrings.targetText);
  }

  /// 开始游戏
  Future<void> _startGame() async {
    setState(() {
      _gameState = GameState.initializing;
      _errorMessage = null;
    });

    try {
      await _cameraService.initialize();
      await _handTrackingService.initialize();
      await _cameraService.startImageStream(_onCameraFrame);
      _generateLevel();

      setState(() => _gameState = GameState.playing);

      _lastTime = 0;
      _gameTicker = createTicker(_onGameTick);
      _gameTicker!.start();
    } catch (e) {
      setState(() {
        _errorMessage = '${strings.AppStrings.cameraDenied}\n$e';
        _gameState = GameState.loading;
      });
    }
  }

  /// 摄像头帧 → 手势识别
  void _onCameraFrame(CameraImage image) {
    if (_gameState != GameState.playing &&
        _gameState != GameState.levelTransition) {
      return;
    }

    _handTrackingService
        .processFrame(image: image, isFrontCamera: true)
        .then((data) {
      if (!mounted) return;
      setState(() {
        _currentGesture = data.gesture;
        _cursorX = data.cursorX;
        _cursorY = data.cursorY;
      });
    });
  }

  /// 游戏主循环
  void _onGameTick(Duration elapsed) {
    if (!mounted) return;

    final currentTime = elapsed.inMilliseconds / 1000.0;
    if (_lastTime == 0) {
      _lastTime = currentTime;
      return;
    }
    double dt = math.min(currentTime - _lastTime, 0.1);
    _lastTime = currentTime;

    _physicsEngine.step(dt);
    _updateParticles(dt);
    _handleInteraction();

    setState(() {});
  }

  /// 交互处理
  void _handleInteraction() {
    if (_isAnimatingLevel) return;

    _updateCursorWorldPos();
    _hoveredCube = _findClosestCube(_cursorWorldPos);

    final isFist = _currentGesture == HandGesture.fist;

    if (isFist && !_wasFist && _hoveredCube != null) {
      _triggerClick(_hoveredCube!);
    }

    _wasFist = isFist;
  }

  /// 归一化光标 → 3D 世界位置
  void _updateCursorWorldPos() {
    final fovRad = dims.AppDimens.cameraFov * (math.pi / 180.0);
    final halfHeight = math.tan(fovRad / 2) * dims.AppDimens.cameraZ;
    final halfWidth = halfHeight * 1.0;

    final worldX = _cursorX * halfWidth;
    final worldY = -_cursorY * halfHeight + dims.AppDimens.cameraLookY;

    final rayOrigin = vm.Vector3(0, dims.AppDimens.cameraY, dims.AppDimens.cameraZ);
    final rayDir = vm.Vector3(
      worldX,
      worldY - dims.AppDimens.cameraY,
      -dims.AppDimens.cameraZ,
    )..normalize();

    const targetY = 5.0;
    if (rayDir.y.abs() > 0.001) {
      final t = (targetY - rayOrigin.y) / rayDir.y;
      if (t > 0) {
        _cursorWorldPos = vm.Vector3(
          rayOrigin.x + rayDir.x * t,
          targetY,
          rayOrigin.z + rayDir.z * t,
        );
        return;
      }
    }
    _cursorWorldPos = vm.Vector3(_cursorX * 15, 5, -_cursorY * 10 + 5);
  }

  GameCube? _findClosestCube(vm.Vector3 cursorPos) {
    GameCube? closest;
    double minDist = double.infinity;

    for (final cube in _cubes) {
      if (cube.isShattered) {
        continue;
      }
      final cubePos = vm.Vector3(cube.posX, cube.posY, cube.posZ);
      final dist = cursorPos.distanceTo(cubePos);
      if (dist < 4.0 && dist < minDist) {
        minDist = dist;
        closest = cube;
      }
    }
    return closest;
  }

  void _triggerClick(GameCube cube) {
    if (cube.isTarget) {
      _triggerCorrect(cube);
    } else {
      _triggerWrong(cube);
    }
  }

  void _triggerWrong(GameCube cube) {
    cube.velY = dims.AppDimens.wrongBumpVelY;
    cube.angVelX = (math.Random().nextDouble() - 0.5) * 10;
    cube.angVelY = (math.Random().nextDouble() - 0.5) * 10;
    cube.angVelZ = (math.Random().nextDouble() - 0.5) * 10;
    setState(() {});
  }

  void _triggerCorrect(GameCube cube) {
    setState(() {
      _isAnimatingLevel = true;
      cube.isShattered = true;
      _gameState = GameState.levelTransition;
    });

    _physicsEngine.removeCube(cube);

    // 鼓胀动画 + 爆破
    final swellStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    const swellDuration = dims.AppDimens.swellDuration;

    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final progress = math.min((now - swellStartTime) / swellDuration, 1.0);

      if (progress < 1) {
        setState(() {}); // 触发重绘
      } else {
        timer.cancel();
        _spawnExplosionParticles(cube);
        _cubes.remove(cube);
        setState(() {});

        Future.delayed(
          Duration(
            milliseconds: (dims.AppDimens.levelTransitionDelay * 1000).round(),
          ),
          () {
            if (!mounted) return;
            setState(() {
              _level++;
              _isAnimatingLevel = false;
              _gameState = GameState.playing;
            });
            _generateLevel();
          },
        );
      }
    });
  }

  void _spawnExplosionParticles(GameCube cube) {
    final rng = math.Random();
    final cubePos = vm.Vector3(cube.posX, cube.posY, cube.posZ);

    for (int i = 0; i < dims.AppDimens.particleCount; i++) {
      final color = colors.AppColors.particleColors[
          rng.nextInt(colors.AppColors.particleColors.length)];
      final isSphere = rng.nextDouble() > 0.5;

      final radiusOffset = rng.nextDouble() * 4;
      final theta = rng.nextDouble() * math.pi * 2;
      final phi = math.acos(rng.nextDouble() * 2 - 1);

      _particles.add(ExplosionParticle(
        posX: cubePos.x + radiusOffset * math.sin(phi) * math.cos(theta),
        posY: cubePos.y + radiusOffset * math.sin(phi) * math.sin(theta),
        posZ: cubePos.z + radiusOffset * math.cos(phi),
        velX: math.sin(phi) * math.cos(theta) * (rng.nextDouble() * 60 + 20),
        velY: math.sin(phi) * math.sin(theta) * (rng.nextDouble() * 60 + 20) + 15,
        velZ: math.cos(phi) * (rng.nextDouble() * 60 + 20),
        colorValue: color.toARGB32(),
        isSphere: isSphere,
        life: dims.AppDimens.particleLifeMin +
            rng.nextDouble() *
                (dims.AppDimens.particleLifeMax - dims.AppDimens.particleLifeMin),
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.posX += p.velX * dt;
      p.posY += p.velY * dt;
      p.posZ += p.velZ * dt;
      p.velY -= dims.AppDimens.particleGravity * dt;
      p.rotX += p.velY * 0.02;
      p.rotY += p.velX * 0.02;
      p.scale *= dims.AppDimens.particleScaleDecay;
      p.life -= dt;
      if (p.life <= 0 || p.scale < 0.01) {
        _particles.removeAt(i);
      }
    }
  }

  void _generateLevel() {
    _physicsEngine.clear();
    _cubes.clear();
    _hoveredCube = null;

    final count = math.min(
      dims.AppDimens.baseCubeCount + _level * dims.AppDimens.cubesPerLevel,
      dims.AppDimens.maxCubes,
    );
    final targetIndex = math.Random().nextInt(count);
    final rng = math.Random();
    int spawned = 0;

    Timer.periodic(
      Duration(milliseconds: (dims.AppDimens.spawnInterval * 1000).round()),
      (timer) {
        if (!mounted || spawned >= count) {
          timer.cancel();
          if (mounted) setState(() => _isAnimatingLevel = false);
          return;
        }

        final cube = GameCube(
          isTarget: spawned == targetIndex,
          posX: (rng.nextDouble() - 0.5) * dims.AppDimens.spawnSpread,
          posY: dims.AppDimens.spawnHeightMin +
              rng.nextDouble() * dims.AppDimens.spawnHeightExtra,
          posZ: (rng.nextDouble() - 0.5) * dims.AppDimens.spawnSpread,
          velX: (rng.nextDouble() - 0.5) * 5,
          velY: dims.AppDimens.spawnVelY,
          velZ: (rng.nextDouble() - 0.5) * 5,
          angVelX: rng.nextDouble() * 5,
          angVelY: rng.nextDouble() * 5,
          angVelZ: rng.nextDouble() * 5,
        );

        _cubes.add(cube);
        _physicsEngine.addCube(cube);
        setState(() {});
        spawned++;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colors.AppColors.background,
      body: Stack(
        children: [
          // 3D 游戏画面
          Positioned.fill(
            child: CustomPaint(
              painter: _GamePainter(
                cubes: _cubes,
                particles: _particles,
                cursorWorldPos: _cursorWorldPos,
                currentGesture: _currentGesture,
                hoveredCube: _hoveredCube,
                texNormal: _texNormal,
                texTarget: _texTarget,
              ),
            ),
          ),

          // 标题 UI
          const Positioned(top: 0, left: 0, right: 0, child: UiOverlay()),

          // 调试面板
          Positioned(
            bottom: 20,
            left: 20,
            child: DebugPanel(gesture: _currentGesture),
          ),

          // GitHub 链接
          const Positioned(bottom: 20, right: 20, child: GithubButton()),

          // 加载画面
          if (_gameState == GameState.loading ||
              _gameState == GameState.initializing)
            Positioned.fill(
              child: LoadingOverlay(
                isInitializing: _gameState == GameState.initializing,
                errorMessage: _errorMessage,
                onStart: _gameState == GameState.loading ? _startGame : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// 3D 游戏画面 CustomPainter
class _GamePainter extends CustomPainter {
  final List<GameCube> cubes;
  final List<ExplosionParticle> particles;
  final vm.Vector3 cursorWorldPos;
  final HandGesture currentGesture;
  final GameCube? hoveredCube;
  final ui.Image? texNormal;
  final ui.Image? texTarget;

  _GamePainter({
    required this.cubes,
    required this.particles,
    required this.cursorWorldPos,
    required this.currentGesture,
    required this.hoveredCube,
    this.texNormal,
    this.texTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // 地板
    final floorY = size.height * 0.75;
    canvas.drawRect(
      Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
      Paint()..color = const Color(0xFF2A2A2A),
    );

    // 绘制网格线
    _drawGrid(canvas, size);

    // 深度排序（远→近）
    final sorted = List<GameCube>.from(cubes)
      ..sort((a, b) => b.posZ.compareTo(a.posZ));

    // 绘制立方体
    for (final cube in sorted) {
      if (cube.isShattered) {
        continue;
      }
      _drawCube(canvas, size, cube);
    }

    // 绘制粒子
    for (final p in particles) {
      _drawParticle(canvas, size, p);
    }

    // 绘制光标
    _drawCursor(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.5;

    final step = size.width / 40;
    final floorY = size.height * 0.75;

    for (int i = 0; i <= 40; i++) {
      final x = i * step;
      canvas.drawLine(Offset(x, floorY), Offset(x, size.height), paint);
    }

    final hStep = (size.height - floorY) / 20;
    for (int j = 0; j <= 20; j++) {
      final y = floorY + j * hStep;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawCube(Canvas canvas, Size size, GameCube cube) {
    final w = size.width;
    final h = size.height;

    const cameraZ = 40.0;
    const cameraY = 25.0;

    final relZ = cube.posZ + cameraZ;
    if (relZ <= 1) return;

    final scale = cameraZ / relZ;
    final sx = w / 2 + cube.posX * scale * (w / 40);
    final sy = h / 2 - (cube.posY - cameraY) * scale * (h / 40);
    final cubeSz = dims.AppDimens.cubeSize * scale * (w / 40);
    if (cubeSz < 2) return;

    final isHovered = cube == hoveredCube;

    // 光照
    final lightFactor = ((cube.posY - 5) / 30).clamp(0.3, 1.0);
    final baseColor = cube.isTarget
        ? const Color(0xFFFFE0E0)
        : const Color(0xFFF0F0F0);
    final litColor = Color.fromARGB(
      255,
      (baseColor.r.toDouble() * 255 * lightFactor).round().clamp(0, 255),
      (baseColor.g.toDouble() * 255 * lightFactor).round().clamp(0, 255),
      (baseColor.b.toDouble() * 255 * lightFactor).round().clamp(0, 255),
    );

    final rect = Rect.fromCenter(
        center: Offset(sx, sy), width: cubeSz, height: cubeSz);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2));

    canvas.drawRRect(rrect, Paint()..color = litColor);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = isHovered ? const Color(0xFF333333) : const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cube.isTarget ? 2.5 : 1.5,
    );

    // 文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: cube.isTarget ? '马虫' : '冯强',
        style: TextStyle(
          color: const Color(0xFF111111),
          fontSize: cubeSz * 0.25,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(sx - textPainter.width / 2, sy - textPainter.height / 2),
    );
  }

  void _drawParticle(Canvas canvas, Size size, ExplosionParticle p) {
    final w = size.width;
    final h = size.height;

    const cameraZ = 40.0;
    const cameraY = 25.0;

    final relZ = p.posZ + cameraZ;
    if (relZ <= 1) return;

    final scale = cameraZ / relZ;
    final sx = w / 2 + p.posX * scale * (w / 40);
    final sy = h / 2 - (p.posY - cameraY) * scale * (h / 40);

    final pSize = 5.0 * p.scale * scale * (w / 40);
    if (pSize < 0.5) return;

    final fogFactor = (1 - (relZ / 80).clamp(0.0, 1.0));
    final alpha = (255 * fogFactor * (p.life / 2.0)).round().clamp(0, 255);

    final paint = Paint()
      ..color = Color(p.colorValue).withAlpha(alpha)
      ..style = PaintingStyle.fill;

    if (p.isSphere) {
      canvas.drawCircle(Offset(sx, sy), pSize, paint);
    } else {
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(sx, sy), width: pSize * 2, height: pSize * 2),
        paint,
      );
    }
  }

  void _drawCursor(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    const cameraZ = 40.0;
    const cameraY = 25.0;

    final relZ = cursorWorldPos.z + cameraZ;
    if (relZ <= 1) return;

    final scale = cameraZ / relZ;
    final sx = w / 2 + cursorWorldPos.x * scale * (w / 40);
    final sy = h / 2 - (cursorWorldPos.y - cameraY) * scale * (h / 40);

    final cursorSz =
        12.0 * (currentGesture == HandGesture.fist ? 0.7 : 1.0) * scale * (w / 40);

    canvas.drawCircle(
      Offset(sx, sy),
      cursorSz,
      Paint()
        ..color = currentGesture == HandGesture.fist
            ? const Color(0xFFFF0000)
            : const Color(0xFF00FF00)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}
