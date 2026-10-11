import 'package:intl/intl.dart';
import 'package:market_mates/data/models/event.dart';

String formatOpeningHours(List<OpeningHour> openingHours) {
  return openingHours.map((entry) {
    final days = (entry.days).join(', '); // Access the `days` property directly
    final open = entry.open;           // Access the `open` property directly
    final close = entry.close;
    return '$days: $open - $close';
  }).join('\n');
}

/// "24.11. – 22.12.2026", or "24.11.2026" for single-day events.
String formatDateRange(DateTime start, DateTime end) {
  final full = DateFormat('dd.MM.yyyy', 'de');
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return full.format(start);
  }
  final startFormat = start.year == end.year ? DateFormat('dd.MM.', 'de') : full;
  return '${startFormat.format(start)} – ${full.format(end)}';
}
