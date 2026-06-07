import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 本地 HTTP 服务器 —— 离线提供 index.html + 所有 JS/模型文件
/// ES module importmap 和 MediaPipe locateFile 均通过 localhost 加载
class LocalServer {
  HttpServer? _server;
  final int port;
  bool _running = false;

  LocalServer({this.port = 8080});

  bool get isRunning => _running;
  String get url => 'http://localhost:$port/index.html';

  /// 启动服务器：复制 asset 文件到临时目录，然后启动 HttpServer
  Future<void> start() async {
    if (_running) return;

    // 复制 Flutter assets/web/ 到临时目录
    final tempDir = Directory(p.join(
      (await getTemporaryDirectory()).path,
      'crush_the_fq_web',
    ));
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    tempDir.createSync(recursive: true);

    await _copyAssets(tempDir.path);

    // 启动 HTTP 服务器
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _running = true;

    _server!.listen((request) {
      final requestPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
      final filePath = p.join(tempDir.path, requestPath.substring(1));
      final file = File(filePath);

      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        request.response
          ..statusCode = 200
          ..headers.contentType = _contentType(filePath)
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..headers.set('Cross-Origin-Opener-Policy', 'same-origin')
          ..headers.set('Cross-Origin-Embedder-Policy', 'require-corp')
          ..add(bytes)
          ..close();
      } else {
        request.response
          ..statusCode = 404
          ..close();
      }
    });
  }

  /// 从 Flutter assets 复制所有 web 文件到目标目录
  Future<void> _copyAssets(String targetDir) async {
    // 主文件列表（assets/web/ 下的顶层文件）
    const topFiles = [
      'index.html',
      'hands.js',
      'three.module.js',
      'cannon-es.js',
    ];

    for (final file in topFiles) {
      await _copyAsset('assets/web/$file', p.join(targetDir, file));
    }

    // mediapipe/hands/ 子目录的文件
    const modelFiles = [
      'hands.binarypb',
      'hand_landmark_full.tflite',
      'hand_landmark_lite.tflite',
      'hands_solution_packed_assets_loader.js',
      'hands_solution_simd_wasm_bin.js',
      'hands_solution_wasm_bin.js',
    ];

    final modelDir = Directory(p.join(targetDir, 'mediapipe', 'hands'));
    modelDir.createSync(recursive: true);

    for (final file in modelFiles) {
      await _copyAsset(
        'assets/web/mediapipe/hands/$file',
        p.join(modelDir.path, file),
      );
    }
  }

  Future<void> _copyAsset(String assetPath, String targetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final file = File(targetPath);
      await file.writeAsBytes(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('⚠️ Failed to copy asset $assetPath: $e');
    }
  }

  /// MIME 类型映射
  ContentType _contentType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.html':
        return ContentType.html;
      case '.js':
        return ContentType('application', 'javascript', charset: 'utf-8');
      case '.tflite':
        return ContentType('application', 'octet-stream');
      case '.binarypb':
        return ContentType('application', 'octet-stream');
      case '.data':
        return ContentType('application', 'octet-stream');
      case '.wasm':
        return ContentType('application', 'wasm');
      case '.css':
        return ContentType('text', 'css', charset: 'utf-8');
      default:
        return ContentType('application', 'octet-stream');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _running = false;
  }
}
