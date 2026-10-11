import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/stand_categories.dart';

final _cache = <String, BitmapDescriptor>{};

/// Round map marker with the category icon, drawn once per category.
Future<BitmapDescriptor> categoryMarker(StandCategory category) =>
    iconMarker(category.key, category.icon, category.color);

/// Round map marker with [icon] on [color]. [selected] draws it larger with a
/// dark ring. Cached per [cacheKey] and selection state.
Future<BitmapDescriptor> iconMarker(
  String cacheKey,
  IconData icon,
  Color color, {
  bool selected = false,
}) async {
  final key = '$cacheKey/$selected';
  final cached = _cache[key];
  if (cached != null) return cached;

  const size = 64.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(size / 2, size / 2);
  canvas.drawCircle(center, size / 2, Paint()..color = selected ? Colors.black87 : Colors.white);
  canvas.drawCircle(center, size / 2 - (selected ? 6 : 4), Paint()..color = color);
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.55,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, Offset((size - painter.width) / 2, (size - painter.height) / 2));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final display = selected ? 40.0 : 26.0;
  final descriptor =
      BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: display, height: display);
  _cache[key] = descriptor;
  return descriptor;
}
