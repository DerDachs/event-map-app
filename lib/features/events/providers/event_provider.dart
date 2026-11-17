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

/// Weekday (Monday = 1) for a day abbreviation in German or English, in any
/// spelling the app has stored: "Mo", "Mo.", "Mon", "Tue", "Di" ...
int? weekdayOf(String day) {
  const byPrefix = {
    'mo': DateTime.monday,
    'di': DateTime.tuesday,
    'tu': DateTime.tuesday,
    'mi': DateTime.wednesday,
    'we': DateTime.wednesday,
    'do': DateTime.thursday,
    'th': DateTime.thursday,
    'fr': DateTime.friday,
    'sa': DateTime.saturday,
    'so': DateTime.sunday,
    'su': DateTime.sunday,
  };
  final text = day.trim().toLowerCase();
  return text.length < 2 ? null : byPrefix[text.substring(0, 2)];
}

/// Whether one of [openingHours] ({days, open, close}) covers [now]. Days are
/// compared as weekdays, so the device language does not matter.
bool isOpenAt(List<dynamic> openingHours, DateTime now) {
  final currentTime = DateFormat('HH:mm').format(now);

  for (var entry in openingHours) {
    final days = (entry['days'] as List).map((d) => weekdayOf(d.toString()));
    if (days.contains(now.weekday)) {
      final open = entry['open'];
      final close = entry['close'];

      if (currentTime.compareTo(open) >= 0 && currentTime.compareTo(close) <= 0) {
        return true; // Market is open
      }
    }
  }
  return false; // Market is closed
}

bool isMarketOpen(List<dynamic> openingHours) => isOpenAt(openingHours, DateTime.now());
