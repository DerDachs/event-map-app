import 'package:cloud_firestore/cloud_firestore.dart';
import 'eventImage.dart';

class Stand {
  final String id;
  final String name;
  final String description;
  final List<EventImage>? images;
  final List<String>? menu; // Menu items for the stand
  final String? promotions; // Optional promotions for the stand
  final double? eventLatitude; // Optional event-specific latitude
  final double? eventLongitude; // Optional event-specific longitude
  final String? standCategoryId; // Optional standCategoryId


  Stand({
    required this.id,
    required this.name,
    required this.description,
    this.images,
    this.menu,
    this.promotions,
    this.eventLatitude,
    this.eventLongitude,
    this.standCategoryId,
  });

  // From Firestore
  factory Stand.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      SnapshotOptions? options,
      ) {
    final data = doc.data()!;
    return Stand(
      id: doc.id,
      name: data['name'],
      description: data['description'],
      standCategoryId: data['category'],
      images: (data['images'] as List?)
          ?.map((image) => EventImage.fromMap(image as Map<String, dynamic>))
          .toList(),
      menu: (data['menu'] as List?)?.map((item) => item.toString()).toList(),
      promotions: data['promotions'], // Allow null if missing
    );
  }
}