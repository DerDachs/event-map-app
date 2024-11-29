import 'package:market_mates/data/models/event.dart';

String formatOpeningHours(List<OpeningHour> openingHours) {
  return openingHours.map((entry) {
    final days = (entry.days).join(', '); // Access the `days` property directly
    final open = entry.open;           // Access the `open` property directly
    final close = entry.close;
    return '$days: $open - $close';
  }).join('\n');
}