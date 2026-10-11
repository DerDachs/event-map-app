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

    final standsData = (eventDoc.data()!['stands'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .where((m) => m['standId'] is String && m['location'] is Map)
        .toList();

    // Load all stand documents in parallel; markets have well over 100 stands.
    final docs = await Future.wait(standsData.map(
        (standData) => _firestore.collection('stands').doc(standData['standId'] as String).get()));

    final List<Stand> stands = [];
    for (var i = 0; i < docs.length; i++) {
      final standDoc = docs[i];
      if (!standDoc.exists) continue;
      final standData = standsData[i];
      final location = Map<String, dynamic>.from(standData['location'] as Map);
      final stand = Stand.fromFirestore(standDoc, null);
      stands.add(Stand(
        id: stand.id,
        name: stand.name,
        description: stand.description,
        standCategoryId: standData['category'] as String? ?? stand.standCategoryId,
        images: stand.images,
        menu: stand.menu,
        promotions: stand.promotions,
        eventLatitude: (location['latitude'] as num).toDouble(),
        eventLongitude: (location['longitude'] as num).toDouble(),
      ));
    }
    return stands;
  }
}