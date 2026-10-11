import '../../../data/models/event.dart';

/// Listing details read from an event's web page (Cloud Function
/// importEventFromUrl). Images are already copied to our Storage.
class EventImport {
  final String sourceUrl;
  final String? name;
  final String? description;
  final String? eventTip;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<OpeningHour> openingHours;
  final String? ticketPrice;
  final String? organizerName;
  final String? organizerInfo;
  final String? locationHint;
  final List<String> imageUrls;
  final List<String> warnings;

  const EventImport({
    required this.sourceUrl,
    this.name,
    this.description,
    this.eventTip,
    this.startDate,
    this.endDate,
    this.openingHours = const [],
    this.ticketPrice,
    this.organizerName,
    this.organizerInfo,
    this.locationHint,
    this.imageUrls = const [],
    this.warnings = const [],
  });

  factory EventImport.fromMap(Map<String, dynamic> m) {
    String? text(String key) {
      final v = m[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    DateTime? date(String key) => text(key) == null ? null : DateTime.tryParse(text(key)!);

    return EventImport(
      sourceUrl: m['sourceUrl'] as String? ?? '',
      name: text('name'),
      description: text('description'),
      eventTip: text('eventTip'),
      startDate: date('startDate'),
      endDate: date('endDate'),
      openingHours: (m['openingHours'] as List? ?? const [])
          .whereType<Map>()
          .map((h) => OpeningHour.fromFirestore(Map<String, dynamic>.from(h)))
          .toList(),
      ticketPrice: text('ticketPrice'),
      organizerName: text('organizerName'),
      organizerInfo: text('organizerInfo'),
      locationHint: text('locationHint'),
      imageUrls: (m['images'] as List? ?? const [])
          .whereType<Map>()
          .map((i) => i['url'])
          .whereType<String>()
          .toList(),
      warnings: (m['warnings'] as List? ?? const []).whereType<String>().toList(),
    );
  }
}
