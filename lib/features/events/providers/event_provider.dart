import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../providers/user_provider.dart';
import '../services/event_service.dart';

// Event Service Provider
final eventServiceProvider = Provider<EventService>((ref) => EventService());

// Events State Provider
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final service = ref.read(eventServiceProvider);
  return await service.fetchEvents();
});

final userParticipationProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final eventService = ref.watch(eventServiceProvider);
  final userId = ref.watch(userProfileProvider).value?.uid;
  if (userId == null) return false;

  return await eventService.isUserParticipant(eventId, userId);
});

bool isMarketOpen(List<dynamic> openingHours) {
  final now = DateTime.now();
  final today = DateFormat('E').format(now); // e.g., "Mo"
  final currentTime = DateFormat('HH:mm').format(now);

  for (var entry in openingHours) {
    if (entry['days'].contains(today)) {
      final open = entry['open'];
      final close = entry['close'];

      if (currentTime.compareTo(open) >= 0 && currentTime.compareTo(close) <= 0) {
        return true; // Market is open
      }
    }
  }
  return false; // Market is closed
}

