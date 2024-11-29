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
  });

  // From Firestore
  factory Event.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      SnapshotOptions? options,
      ) {
    final data = doc.data()!;
    return Event(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      latitude: data['latitude'],
      longitude: data['longitude'],
      category: data['category'],
      teamIds: List<String>.from(data['teamIds']),
      images: (data['images'] as List)
          .map((image) => EventImage.fromMap(image as Map<String, dynamic>))
          .toList(),
      stands: (data['stands'] as List)
          .map((stand) => StandInEvent.fromFirestore(stand))
          .toList(),
      participants: List<String>.from(data['participants']),
      openingHours: (data['openingHours'] as List<dynamic>?)
          ?.map((e) => OpeningHour.fromFirestore(e))
          .toList() ?? [],
      organizerName: data['organizerName'] ?? '',
      ticketPrice: data['ticketPrice'] ?? '',
      eventTip: data['eventTip'] ?? '',
      organizerInfo: data['organizerInfo'] ?? '',
    );
  }

  // Convert Event to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'startTime': startTime as Timestamp,
      'endTime': endTime as Timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'teamIds': teamIds,
      'images': images.map((image) => image.toFirestore()).toList(),
      'stands': stands,
      'category': category,
      'participants': participants,
      'openingHours': openingHours?.map((hour) => hour.toFirestore()).toList(),
      'organizerName': organizerName ?? '',
      'ticketPrice': ticketPrice ?? '',
      'eventTip': eventTip ?? '',
      'organizerInfo': organizerInfo ?? '',
    };
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

  StandInEvent({
    required this.standId,
    required this.latitude,
    required this.longitude,
  });

  // From Firestore
  factory StandInEvent.fromFirestore(Map<String, dynamic> data) {
    return StandInEvent(
      standId: data['standId'],
      latitude: data['location']['latitude'],
      longitude: data['location']['longitude'],
    );
  }
}