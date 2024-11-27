import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/team.dart';

class TeamService {
  final FirebaseFirestore _firestore;

  TeamService(this._firestore);

  // Create a new team
  Future<void> createTeam(String eventId, String leaderId, String teamName) async {
    final teamId = _firestore.collection('teams').doc().id;

    final team = Team(
      id: teamId,
      name: teamName,
      eventId: eventId,
      members: [leaderId],
      leaderId: leaderId,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('teams').doc(teamId).set(team.toJson());

    // Update the leader's user document to include the team
    await _firestore.collection('users').doc(leaderId).update({
      'teams': FieldValue.arrayUnion([teamId]),
    });
  }

  // Add a member to a team
  Future<void> addMemberToTeam(String teamId, String userId) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'teams': FieldValue.arrayUnion([teamId]),
    });
  }

  // Remove a member from a team
  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayRemove([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'teams': FieldValue.arrayRemove([teamId]),
    });
  }

  // Fetch teams for an event
  Stream<List<Team>> fetchTeamsForEvent(String eventId) {
    return _firestore
        .collection('teams')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromJson(doc.data())).toList());
  }

  //// Fetch teams for a user
  //Stream<List<Team>> fetchTeamsForUser(String userId) async* {
  //  final userDoc = await _firestore.collection('users').doc(userId).get();
  //  final teamIds = List<String>.from(userDoc['teams'] ?? []);
//
  //  for (final teamId in teamIds) {
  //    yield* _firestore
  //        .collection('teams')
  //        .doc(teamId)
  //        .snapshots()
  //        .map((doc) => Team.fromJson(doc.data()!));
  //  }
  //}
}