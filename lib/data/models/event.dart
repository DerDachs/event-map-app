import 'package:cloud_firestore/cloud_firestore.dart';

import 'eventImage.dart';


class Event {
  final String id;
  final String name;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final double latitude; // Location of the event
  final double longitude;
  final List<String> teamIds;
  final List<EventImage> images;
  final List<String> stands;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.images,
    required this.latitude,
    required this.longitude,
    required this.teamIds,
    required this.stands,
  });

  // Factory to create Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      images: (data['images'] as List)
          .map((image) => EventImage.fromMap(image as Map<String, dynamic>))
          .toList(),
      latitude: data['latitude'],
      longitude: data['longitude'],
      teamIds: List<String>.from(data['teamIds'] ?? []),
      stands: List<String>.from(data['stands'] ?? []),
    );
  }
}