import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/event.dart';
import '../services/event_service.dart';

// Event Service Provider
final eventServiceProvider = Provider<EventService>((ref) => EventService());

// Events State Provider
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final service = ref.read(eventServiceProvider);
  return await service.fetchEvents();
});

