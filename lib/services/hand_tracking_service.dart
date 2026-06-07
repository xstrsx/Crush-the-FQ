import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_detection/hand_detection.dart' as hd;
import 'package:vector_math/vector_math.dart' as vm;

/// 手势类型 — 与原 HTML checkFist 判定逻辑对齐
enum HandGesture {
  /// 张开手掌 —— 浏览/选择模式
  open,

  /// 握拳 —— 确认/捏爆模式
  fist,

  /// 未检测到手
  none,
}

/// 手部跟踪数据
class HandTrackingData {
  final HandGesture gesture;
  final double cursorX; // 归一化 [-1, 1]
  final double cursorY; // 归一化 [-1, 1]

  const HandTrackingData({
    this.gesture = HandGesture.none,
    this.cursorX = 0,
    this.cursorY = 0,
  });
}

/// 离线手势识别服务
/// 基于 hand_detection 包（TFLite 离线推理，模型内置，无需网络）
/// 与原 HTML MediaPipe Hands 逻辑 100% 对齐
class HandTrackingService {
  hd.HandDetector? _detector;
  bool _isInitialized = false;
  bool _isProcessing = false;

  bool get isInitialized => _isInitialized;

  /// 初始化检测器（加载 TFLite 模型，纯离线，模型文件内置在 hand_detection 包中）
  Future<void> initialize() async {
    _detector = await hd.HandDetector.create(
      mode: hd.HandMode.boxesAndLandmarks,
      landmarkModel: hd.HandLandmarkModel.full,
      // 仅检测单手（与原网页 maxNumHands: 1 一致）
      maxDetections: 1,
      // 开启内置手势识别（包含 closedFist）
      enableGestures: true,
      gestureMinConfidence: 0.7, // 与原网页 minDetectionConfidence 一致
      // 掌部检测置信度
      detectorConf: 0.7,
      // 最小关键点置信度
      minLandmarkScore: 0.7,
    );
    _isInitialized = true;
  }

  /// 处理摄像头帧，返回手势跟踪数据
  /// 使用 hand_detection 的 detectFromCameraImage（直接接受 CameraImage，无需手动转换）
  Future<HandTrackingData> processFrame({
    required CameraImage image,
    required bool isFrontCamera,
  }) async {
    if (!_isInitialized || _isProcessing || _detector == null) {
      return const HandTrackingData();
    }

    _isProcessing = true;
    try {
      final hands = await _detector!.detectFromCameraImage(
        image,
        isBgra: defaultTargetPlatform == TargetPlatform.macOS,
        maxDim: 640, // 与原网页 ideal 640x480 一致
      );

      if (hands.isEmpty) {
        return const HandTrackingData(gesture: HandGesture.none);
      }

      final hand = hands.first;

      // 判定握拳
      final isFist = _determineFist(hand);

      // 以 MIDDLE_FINGER_MCP (序号 9) 作为瞄准点（与原网页一致）
      if (hand.landmarks.length <= 9) {
        return HandTrackingData(
          gesture: isFist ? HandGesture.fist : HandGesture.open,
        );
      }

      final aimPoint = hand.landmarks[9]; // MIDDLE_FINGER_MCP

      // 将像素坐标映射到 [-1, 1] 归一化空间
      // 与原网页逻辑一致：mouse.x = -((aimPoint.x - 0.5) * 3.0)
      // MediaPipe HTML 使用相对坐标 [0,1]，hand_detection 使用像素坐标
      final double nx = aimPoint.x / hand.imageWidth; // [0, 1]
      final double ny = aimPoint.y / hand.imageHeight; // [0, 1]

      double cursorX = -((nx - 0.5) * 3.0);
      double cursorY = -((ny - 0.5) * 3.0) - 0.2;

      // 前置摄像头水平翻转（与原网页一致）
      if (isFrontCamera) {
        cursorX = -cursorX;
      }

      // 钳制到 [-1, 1]
      cursorX = cursorX.clamp(-1.0, 1.0);
      cursorY = cursorY.clamp(-1.0, 1.0);

      return HandTrackingData(
        gesture: isFist ? HandGesture.fist : HandGesture.open,
        cursorX: cursorX,
        cursorY: cursorY,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// 判定是否握拳
  /// 优先使用内置手势识别，回退到原 HTML 自定义 checkFist 算法
  bool _determineFist(hd.Hand hand) {
    // 优先使用内置手势识别
    if (hand.gesture != null && hand.gesture!.confidence > 0.5) {
      if (hand.gesture!.type == hd.GestureType.closedFist) {
        return true;
      }
    }

    // 回退到原 HTML 的自定义 checkFist 算法
    // 比较 4 根手指指尖到手腕距离 vs MCP 关节到手腕距离
    if (hand.landmarks.length < 21) return false;

    return _checkFistManual(hand.landmarks);
  }

  /// 自定义握拳检测（与原 HTML checkFist 100% 一致）
  /// 比较指尖(8,12,16,20) 和 MCP(5,9,13,17) 到手腕(0)的距离
  bool _checkFistManual(List<hd.HandLandmark> landmarks) {
    final wrist = landmarks[0]; // WRIST (index 0)
    final wristPos = vm.Vector3(wrist.x, wrist.y, wrist.z);

    // 4 根手指指尖和 MCP 索引（MediaPipe 标准编号）
    const tips = [8, 12, 16, 20]; // INDEX/MIDDLE/RING/PINKY TIP
    const mcps = [5, 9, 13, 17];  // INDEX/MIDDLE/RING/PINKY MCP

    int curledCount = 0;
    for (int i = 0; i < 4; i++) {
      final tip = landmarks[tips[i]];
      final mcp = landmarks[mcps[i]];

      final tipDist = wristPos.distanceTo(vm.Vector3(tip.x, tip.y, tip.z));
      final mcpDist = wristPos.distanceTo(vm.Vector3(mcp.x, mcp.y, mcp.z));

      // 指尖比 MCP 更靠近手腕 → 手指弯曲
      if (tipDist < mcpDist) curledCount++;
    }

    return curledCount >= 3; // ≥3 根弯曲 = 握拳（与原网页完全一致）
  }

  /// 释放资源
  Future<void> dispose() async {
    await _detector?.dispose();
    _isInitialized = false;
  }
}
