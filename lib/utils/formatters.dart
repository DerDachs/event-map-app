import 'package:intl/intl.dart';
import 'package:market_mates/data/models/event.dart';

/// Language of the formatted text: the app's current locale unless given.
String _lang(String? locale) => (locale ?? Intl.getCurrentLocale()).split(RegExp('[_-]')).first;

const _englishDays = {'Mo': 'Mon', 'Di': 'Tue', 'Mi': 'Wed', 'Do': 'Thu', 'Fr': 'Fri', 'Sa': 'Sat', 'So': 'Sun'};

/// "Mo, Di: 11:00 - 21:00" per line. Days are stored as German short names.
String formatOpeningHours(List<OpeningHour> openingHours, {String? locale}) {
  final english = _lang(locale) == 'en';
  return openingHours.map((entry) {
    final days = entry.days.map((d) => english ? (_englishDays[d] ?? d) : d).join(', ');
    return '$days: ${entry.open} - ${entry.close}';
  }).join('\n');
}

/// German "24.11. – 22.12.2026", English "Nov 24 – Dec 22, 2026";
/// single-day events show one date.
String formatDateRange(DateTime start, DateTime end, {String? locale}) {
  final lang = _lang(locale);
  final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
  if (lang == 'en') {
    final full = DateFormat('MMM d, y', 'en');
    if (sameDay) return full.format(start);
    final startFormat = start.year == end.year ? DateFormat('MMM d', 'en') : full;
    return '${startFormat.format(start)} – ${full.format(end)}';
  }
  final full = DateFormat('dd.MM.yyyy', 'de');
  if (sameDay) return full.format(start);
  final startFormat = start.year == end.year ? DateFormat('dd.MM.', 'de') : full;
  return '${startFormat.format(start)} – ${full.format(end)}';
}
