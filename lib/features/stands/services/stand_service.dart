import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/stand.dart';

class StandService {
  final FirebaseFirestore _firestore;

  StandService(this._firestore);

  Future<List<Stand>> fetchStandsForEvent(String eventId) async {
    final eventDoc = await _firestore.collection('events').doc(eventId).get();

    if (!eventDoc.exists) {
      throw Exception("Event not found");
    }

    final standsData = List<Map<String, dynamic>>.from(eventDoc.data()!['stands']);
    final List<Stand> stands = [];

    for (final standData in standsData) {
      final standId = standData['standId'];
      final location = standData['location'];
      final standDoc = await _firestore.collection('stands').doc(standId).get();

      if (standDoc.exists) {
        final stand = Stand.fromFirestore(standDoc,null);
        final updatedStand = Stand(
          id: stand.id,
          name: stand.name,
          description: stand.description,
          images: stand.images,
          menu: stand.menu,
          promotions: stand.promotions,
          eventLatitude: location['latitude'],
          eventLongitude: location['longitude'],
        );
        stands.add(updatedStand);
      }
    }

    return stands;
  }
}