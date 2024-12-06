import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all events from Firestore
  Future<List<Event>> fetchEvents() async {
    try {
      final querySnapshot = await _firestore.collection('events').get();
      return querySnapshot.docs.map((doc) => Event.fromFirestore(doc,null)).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<List<Stand>> fetchStandsForEvent(String eventId) async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();

    if (!eventDoc.exists) {
      throw Exception("Event not found");
    }

    // Extract stands array from event document
    final standsData = List<Map<String, dynamic>>.from(eventDoc.data()!['stands']);
    final List<Stand> stands = [];

    // Loop through each stand reference in the event
    for (final standData in standsData) {
      final standId = standData['standId'];
      final standDoc = await FirebaseFirestore.instance.collection('stands').doc(standId).get();

      if (standDoc.exists) {
        final stand = Stand.fromFirestore(standDoc,null);

        // Combine global stand data with event-specific location
        final updatedStand = Stand(
          id: stand.id,
          name: stand.name,
          description: stand.description,
          images: stand.images,
          menu: stand.menu,
          promotions: stand.promotions,
          eventLatitude: standData['latitude'], // Add event-specific latitude
          eventLongitude: standData['longitude'], // Add event-specific longitude
        );

        stands.add(updatedStand);
      }
    }

    return stands;
  }

  Future<List<Event>> fetchEventsForStand(String standId) async {
    final eventsSnapshot = await FirebaseFirestore.instance.collection('events')
        .where('stands', arrayContains: {'standId': standId})
        .get();

    return eventsSnapshot.docs.map((doc) => Event.fromFirestore(doc,null)).toList();
  }

  Future<void> createEvent(Event event) async {
    try {
      final docRef = _firestore.collection('events').doc(event.id.isEmpty ? null : event.id);
      await docRef.set(event.toFirestore());
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  Future<void> joinEvent(String eventId, String userId) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    await eventRef.update({
      'participants': FieldValue.arrayUnion([userId]) // Add user ID to participants
    });
  }

  // Check if the user has already joined the event
  Future<bool> isUserParticipant(String eventId, String userId) async {
    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return false;

    final participants = List<String>.from(eventDoc['participants'] ?? []);
    return participants.contains(userId);
  }
}