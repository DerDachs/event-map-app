import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile.dart';
import '../../../data/models/team.dart';
import '../../../providers/user_provider.dart';
import '../services/team_service.dart';

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(FirebaseFirestore.instance);
});

/// The signed-in user's team at an event, kept in sync with Firestore.
final myTeamProvider = StreamProvider.family<Team?, String>((ref, eventId) {
  final uid = ref.watch(userProfileProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(teamServiceProvider).watchTeamOfUser(eventId, uid);
});

/// Profiles of a team's members, keyed by the comma-joined member IDs.
final teamMembersProvider = FutureProvider.family<List<UserProfile>, String>((ref, memberIds) {
  if (memberIds.isEmpty) return Future.value(const []);
  return ref.watch(teamServiceProvider).fetchMembers(memberIds.split(','));
});
