import 'package:cloud_firestore/cloud_firestore.dart';
import 'eventImage.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final double latitude; // Center location for the event
  final double longitude;
  final String category;
  final List<String> teamIds; // Team IDs participating
  final List<EventImage> images;
  final List<StandInEvent> stands; // Event-specific stand data
  final List<String>? participants;
  final List<OpeningHour>? openingHours;
  final String? organizerName;
  final String? ticketPrice;
  final String? eventTip;
  final String? organizerInfo;
  final List<String>? categories;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.teamIds,
    required this.images,
    required this.stands,
    this.participants,
    this.openingHours,
    this.organizerName,
    this.ticketPrice,
    this.eventTip,
    this.organizerInfo,
    this.categories,
    this.plan,
    this.websiteUrl,
    this.createdAt,
  });

  final String? websiteUrl;

  /// When the market was added to the app; null for older markets.
  final DateTime? createdAt;

  /// The uploaded site plan and where it lies on the map, for markets created
  /// with the market builder.
  final EventPlan? plan;

  // From Firestore. Tolerates missing fields so one incomplete document
  // doesn't break the whole event list.
  factory Event.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      SnapshotOptions? options,
      ) {
    final data = doc.data() ?? const <String, dynamic>{};
    List<String> strings(Object? v) => v is List ? v.map((e) => e.toString()).toList() : <String>[];
    List<Map<String, dynamic>> maps(Object? v) => v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    DateTime time(Object? v) => v is Timestamp ? v.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
    double number(Object? v) => v is num ? v.toDouble() : 0;

    return Event(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      startTime: time(data['startTime']),
      endTime: time(data['endTime']),
      latitude: number(data['latitude']),
      longitude: number(data['longitude']),
      category: data['category'] as String? ?? '',
      teamIds: strings(data['teamIds']),
      images: maps(data['images']).where((m) => m['url'] != null).map(EventImage.fromMap).toList(),
      stands: maps(data['stands'])
          .where((m) => m['standId'] != null && m['location'] is Map)
          .map(StandInEvent.fromFirestore)
          .toList(),
      participants: strings(data['participants']),
      openingHours: maps(data['openingHours']).map(OpeningHour.fromFirestore).toList(),
      organizerName: data['organizerName'] as String? ?? '',
      ticketPrice: data['ticketPrice'] as String? ?? '',
      eventTip: data['eventTip'] as String? ?? '',
      organizerInfo: data['organizerInfo'] as String? ?? '',
      categories: strings(data['categories']),
      plan: data['plan'] is Map ? EventPlan.fromMap(Map<String, dynamic>.from(data['plan'])) : null,
      websiteUrl: data['websiteUrl'] as String?,
      createdAt: data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }

  // Convert Event to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'latitude': latitude,
      'longitude': longitude,
      'teamIds': teamIds,
      'images': images.map((image) => image.toFirestore()).toList(),
      'stands': stands.map((stand) => stand.toFirestore()).toList(),
      'category': category,
      'participants': participants ?? [],
      'openingHours': openingHours?.map((hour) => hour.toFirestore()).toList() ?? [],
      'organizerName': organizerName ?? '',
      'ticketPrice': ticketPrice ?? '',
      'eventTip': eventTip ?? '',
      'organizerInfo': organizerInfo ?? '',
      'categories': categories ?? [],
    };
  }
}

/// Where the organiser's site plan lies on the map (see the market builder).
class EventPlan {
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double widthMeters;
  final double heightMeters;
  final double bearing;

  const EventPlan({
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.widthMeters,
    required this.heightMeters,
    required this.bearing,
  });

  static EventPlan? fromMap(Map<String, dynamic> data) {
    final overlay = data['overlay'];
    final url = data['imageUrl'];
    if (overlay is! Map || url is! String) return null;
    double n(Object? v) => v is num ? v.toDouble() : 0;
    return EventPlan(
      imageUrl: url,
      latitude: n(overlay['latitude']),
      longitude: n(overlay['longitude']),
      widthMeters: n(overlay['widthMeters']),
      heightMeters: n(overlay['heightMeters']),
      bearing: n(overlay['bearing']),
    );
  }
}

// Event specific Opening hours
class OpeningHour {
  final List<String> days; // e.g., ["Mo", "Tu"]
  final String open; // e.g., "08:00"
  final String close; // e.g., "22:00"

  OpeningHour({required this.days, required this.open, required this.close});

  factory OpeningHour.fromFirestore(Map<String, dynamic> data) {
    return OpeningHour(
      days: List<String>.from(data['days'] ?? []),
      open: data['open'] ?? '',
      close: data['close'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'days': days,
      'open': open,
      'close': close,
    };
  }
}

// Event-specific stand data
class StandInEvent {
  final String standId; // Reference to the stand
  final double latitude;
  final double longitude;
  final String? categoryId;

  StandInEvent({
    required this.standId,
    required this.latitude,
    required this.longitude,
    this.categoryId,
  });

  // From Firestore
  factory StandInEvent.fromFirestore(Map<String, dynamic> data) {
    final location = Map<String, dynamic>.from(data['location'] as Map);
    return StandInEvent(
      standId: data['standId'] as String,
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
      categoryId: data['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'standId': standId,
        'location': {'latitude': latitude, 'longitude': longitude},
        'category': categoryId,
      };
}
