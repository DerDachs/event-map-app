import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/team.dart';
import '../../../utils/custom_generators.dart';

class TeamService {
  final FirebaseFirestore _firestore;

  TeamService(this._firestore);

  // Create a new team
  Future<void> createTeam(
      String eventId, String leaderId, String teamName) async {
    final teamId = _firestore.collection('teams').doc().id;
    final teamCode = generateTeamCode();

    final team = Team(
      id: teamId,
      name: teamName,
      eventId: eventId,
      members: [leaderId],
      leaderId: leaderId,
      createdAt: DateTime.now(),
      teamCode: teamCode,
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

  // Fetch teams for an event
  Future<List<Team>> fetchEventTeamIds(String eventId) async {
    final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();

    // Extract team array from event document
    final teamData = List<String>.from(eventDoc.data()!['teamIds']);
    final List<Team> teams = [];

    // Loop through each team reference in the event
    for (final teamId in teamData) {
      final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();

      if (teamDoc.exists) {
        final team = Team.fromFirestore(teamDoc);
        teams.add(team);
      }
    }

    return teams;
  }

  Future<Team?> getTeamByCode(String teamCode) async {
    final querySnapshot = await _firestore
        .collection('teams')
        .where('teamCode', isEqualTo: teamCode)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // No team found
    }

    return Team.fromJson(querySnapshot.docs.first.data());
  }

  // Start sharing location
  Future<void> shareLocation(
      String teamId, String userId, Duration duration) async {
    final expiresAt = DateTime.now().add(duration);
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([
        {
          'userId': userId,
          'isSharingLocation': true,
          'locationShareExpiresAt': expiresAt.toIso8601String(),
        }
      ]),
    });
  }

  // Stop sharing location
  Future<void> stopSharingLocation(String teamId, String userId) async {
    await _firestore.collection('teams').doc(teamId).update({
      'members': FieldValue.arrayUnion([
        {
          'userId': userId,
          'isSharingLocation': false,
          'locationShareExpiresAt': null,
        }
      ]),
    });
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
