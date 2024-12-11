import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/stand.dart';
import '../../../providers/category_provider.dart';
import '../../events/providers/event_provider.dart';
import '../services/stand_service.dart';
import '../../../data/models/category.dart' as cat;

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