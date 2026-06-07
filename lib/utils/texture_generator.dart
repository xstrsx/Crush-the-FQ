import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../constants/app_dimens.dart' as dims;

/// 纹理生成工具 —— 与 HTML 版 Canvas 纹理生成逻辑完全一致
class TextureGenerator {
  /// 生成方块纹理（纯 Dart 离屏渲染，无需网络）
  /// [text] 显示在方块上的文字（"冯强" 或 "马虫"）
  static Future<ui.Image> generate(String text) async {
    final size = dims.AppDimens.texCanvasSize.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

    // 背景填充 #f0f0f0
    final bgPaint = ui.Paint()..color = const Color(0xFFF0F0F0);
    canvas.drawRect(rect, bgPaint);

    // 边框描边 #cccccc, 宽度 15
    final borderPaint = ui.Paint()
      ..color = const Color(0xFFCCCCCC)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = dims.AppDimens.texBorderWidth;
    final borderInset = dims.AppDimens.texBorderInset;
    canvas.drawRect(
      Rect.fromLTWH(borderInset, borderInset,
          size - borderInset * 2, size - borderInset * 2),
      borderPaint,
    );

    // 文字 #111111, 粗体 100px
    final textStyle = ui.TextStyle(
      color: const Color(0xFF111111),
      fontSize: 100,
      fontWeight: ui.FontWeight.bold,
    );

    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: ui.TextAlign.center,
      maxLines: 1,
    ))
      ..pushStyle(textStyle)
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.toDouble()));

    // 垂直居中绘制文字
    final textOffset = Offset(
      0,
      (size - paragraph.height) / 2,
    );
    canvas.drawParagraph(paragraph, textOffset);

    final picture = recorder.endRecording();
    return picture.toImage(size, size);
  }
}
