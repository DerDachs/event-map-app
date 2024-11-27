import 'package:cloud_firestore/cloud_firestore.dart';
import 'eventImage.dart';

class Stand {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final List<EventImage>? images; // Optional images array
  final List<String> menu;
  final String? promotions;

  Stand({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.images,
    required this.menu,
    this.promotions,
  });

  factory Stand.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Stand(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      images: (data['images'] as List?)
          ?.map((image) => EventImage.fromMap(image as Map<String, dynamic>))
          .toList(),
      menu: List<String>.from(data['menu'] ?? []),
      promotions: data['promotions'],
    );
  }
}