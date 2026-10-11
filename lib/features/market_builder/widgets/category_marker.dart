import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/stand_categories.dart';

final _cache = <String, BitmapDescriptor>{};

/// Round map marker with the category icon, drawn once per category.
Future<BitmapDescriptor> categoryMarker(StandCategory category) async {
  final cached = _cache[category.key];
  if (cached != null) return cached;

  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, Paint()..color = Colors.white);
  canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, Paint()..color = category.color);
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(category.icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.55,
        fontFamily: category.icon.fontFamily,
        package: category.icon.fontPackage,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, Offset((size - painter.width) / 2, (size - painter.height) / 2));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 32, height: 32);
  _cache[category.key] = descriptor;
  return descriptor;
}
