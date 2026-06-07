import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 摄像头服务 —— 管理摄像头生命周期与帧获取
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// 初始化前置摄像头（user-facing）
  Future<void> initialize() async {
    // 请求权限
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw CameraException('permission_denied', '摄像头权限被拒绝');
    }

    _cameras = await availableCameras();

    // 优先选择前置摄像头（与原网页 facingMode: 'user' 一致）
    CameraDescription? frontCamera;
    for (final cam in _cameras!) {
      if (cam.lensDirection == CameraLensDirection.front) {
        frontCamera = cam;
        break;
      }
    }
    // 如果没有前置摄像头，使用后置
    frontCamera ??= _cameras!.first;

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium, // 接近 640x480
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    _isInitialized = true;
  }

  /// 开始预览流
  Future<void> startImageStream(void Function(CameraImage image) onImage) async {
    if (_controller == null || !_isInitialized) return;
    await _controller!.startImageStream(onImage);
  }

  /// 停止预览流
  Future<void> stopImageStream() async {
    if (_controller == null || !_isInitialized) return;
    await _controller!.stopImageStream();
  }

  /// 获取当前帧尺寸
  Size? get previewSize => _controller?.value.previewSize;

  /// 释放资源
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _isInitialized = false;
  }
}
