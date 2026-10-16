import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/profile.dart';
import '../../../data/models/team.dart';
import '../../../utils/custom_generators.dart';

class TeamException implements Exception {
  final String message;

  /// 'not-found' or 'other-market', for translated messages in the UI.
  final String code;
  TeamException(this.message, this.code);
  @override
  String toString() => message;
}

class TeamService {
  final FirebaseFirestore _firestore;

  TeamService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _teams => _firestore.collection('teams');

  /// The team [userId] belongs to at [eventId], live.
  Stream<Team?> watchTeamOfUser(String eventId, String userId) {
    return _teams
        .where('eventId', isEqualTo: eventId)
        .where('memberIds', arrayContains: userId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : Team.fromFirestore(s.docs.first));
  }

  Future<Team> createTeam(String eventId, String leaderId, String teamName) async {
    // Codes are short, so make sure the new one isn't taken yet.
    var code = generateTeamCode();
    while ((await _teams.where('teamCode', isEqualTo: code).limit(1).get()).docs.isNotEmpty) {
      code = generateTeamCode();
    }
    final ref = _teams.doc();
    final team = Team(
      id: ref.id,
      name: teamName,
      eventId: eventId,
      members: [leaderId],
      leaderId: leaderId,
      createdAt: DateTime.now(),
      teamCode: code,
    );
    await ref.set({
      ...team.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('events').doc(eventId).update({
      'teamIds': FieldValue.arrayUnion([ref.id]),
    });
    return team;
  }

  Future<Team> joinByCode(String code, String eventId, String userId) async {
    final query = await _teams.where('teamCode', isEqualTo: code.trim().toUpperCase()).limit(1).get();
    if (query.docs.isEmpty) throw TeamException('Kein Team mit diesem Code gefunden.', 'not-found');
    final team = Team.fromFirestore(query.docs.first);
    if (team.eventId != eventId) {
      throw TeamException('Dieses Team gehört zu einem anderen Markt.', 'other-market');
    }
    await _teams.doc(team.id).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    return team;
  }

  /// Removes [userId]; the last member leaving deletes the team.
  Future<void> leave(Team team, String userId) async {
    final remaining = team.members.where((id) => id != userId).toList();
    if (remaining.isEmpty) {
      await _teams.doc(team.id).delete();
      await _firestore.collection('events').doc(team.eventId).update({
        'teamIds': FieldValue.arrayRemove([team.id]),
      });
      return;
    }
    await _teams.doc(team.id).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      if (team.leaderId == userId) 'leaderId': remaining.first,
    });
  }

  Future<List<UserProfile>> fetchMembers(List<String> userIds) async {
    final docs = await Future.wait(userIds.map((id) => _firestore.collection('profiles').doc(id).get()));
    return [
      for (final doc in docs)
        if (doc.exists) UserProfile.fromFirestore(doc.data()!, doc.id),
    ];
  }
}
