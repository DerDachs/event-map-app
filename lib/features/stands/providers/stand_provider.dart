import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/stand.dart';
import '../services/stand_service.dart';

final standServiceProvider = Provider<StandService>((ref) {
  return StandService(FirebaseFirestore.instance);
});

final standsForEventProvider = FutureProvider.family<List<Stand>, String>((ref, eventId) async {
  final standService = ref.read(standServiceProvider);
  return await standService.fetchStandsForEvent(eventId);
});