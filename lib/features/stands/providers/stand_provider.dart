import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stand.dart';
import '../services/stand_service.dart';

// Stand Service Provider
final standServiceProvider = Provider<StandService>((ref) => StandService());

// Stands State Provider
final standsProvider =
FutureProvider.family<List<Stand>, List<String>>((ref, standIds) async {
  final service = ref.read(standServiceProvider);
  return await service.fetchStands(standIds);
});