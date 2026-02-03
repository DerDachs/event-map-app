import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/stand.dart';
import '../../../providers/category_provider.dart';
import '../../events/providers/event_provider.dart';
import '../services/stand_service.dart';
import '../../../data/models/category.dart' as cat;
import 'package:google_maps_flutter/google_maps_flutter.dart';

final standServiceProvider = Provider<StandService>((ref) {
  return StandService(FirebaseFirestore.instance);
});

final standsForEventProvider = FutureProvider.family<List<Stand>, String>((ref, eventId) async {
  final standService = ref.read(standServiceProvider);
  return await standService.fetchStandsForEvent(eventId);
});


final standsGroupedByCategoryProvider =
FutureProvider.family<Map<String, List<Stand>>, String>((ref, eventId) async {
  final eventService = ref.read(eventServiceProvider);
  final categoryService = ref.read(categoryServiceProvider);

  // Fetch Event Data
  final event = await eventService.getEventById(eventId);
  if (event == null){
    if (kDebugMode) {
      print("event not found");
    }
  }

  // Fetch Stands for the Event
  final stands = await ref.read(standsForEventProvider(eventId).future);

  // Fetch Categories for the Event
  final categories = await ref.read(categoriesForEventProvider(eventId).future);

  // Map Categories to Stands
  final Map<String, List<Stand>> groupedStands = {
    for (final category in categories) category.name: [],
    "Untitled": [],
  };

  for (final stand in stands) {
    final categoryName = categories
        .firstWhere((cat) => cat.id == stand.standCategoryId, orElse: () => cat.Category.generic()).name;
      groupedStands[categoryName]?.add(stand);
  }

  return groupedStands;
});




final standIconProvider = FutureProvider.family<BitmapDescriptor, String>((ref, iconId) async {
  // Fetch or generate a custom BitmapDescriptor using the icon ID
  final icon = await _generateCustomIcon(iconId);
  return icon;
});

Future<BitmapDescriptor> _generateCustomIcon(String iconId) async {
  // Logic to generate BitmapDescriptor based on iconId
  var ui;
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint()..color = Colors.blue;
  const double size = 48.0;

  canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: iconId, // Use iconId to render or fetch a custom icon
      style: TextStyle(fontSize: size / 3, color: Colors.white),
    ),
    textDirection: ui.TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ));

  final image = await pictureRecorder
      .endRecording()
      .toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}