import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/team.dart';
import '../../../providers/user_provider.dart';
import '../services/team_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider for the TeamService
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(FirebaseFirestore.instance);
});

// Fetch teams for an event -> read event ID in teams collection
final teamsForEventProvider =
StreamProvider.family<List<Team>, String>((ref, eventId) {
  final teamService = ref.read(teamServiceProvider);
  return teamService.fetchTeamsForEvent(eventId);
});

final teamByCodeProvider = FutureProvider.family<Team?, String>((ref, teamCode) async {
  final teamService = ref.read(teamServiceProvider);
  return await teamService.getTeamByCode(teamCode);
});

// Provider for fetching teams for an event
final teamsForEventFutureProvider =
FutureProvider.family<List<Team>, String>((ref, eventId) async {
  final teamService = ref.read(teamServiceProvider);
  return teamService.fetchEventTeamIds(eventId);
});

// Fetch teams for a user
//final teamsForUserProvider =
//StreamProvider.family<List<Team>, String>((ref, userId) {
//  final teamService = ref.read(teamServiceProvider);
//  return teamService.fetchTeamsForUser(userId);
//});

final userMembershipProvider = FutureProvider.family<String?, String>((ref, eventId) async {
  final teamService = ref.read(teamServiceProvider);
  final userId = ref.read(userProfileProvider).value?.uid;

  return userId != null
      ? await teamService.getUserTeamForEvent(userId, eventId)
      : null;
});

class TeamStateNotifier extends StateNotifier<String?> {
  TeamStateNotifier() : super(null);

  void joinTeam(String teamId) {
    state = teamId;
  }

  void leaveTeam() {
    state = null;
  }
}

final teamContextProvider = StateNotifierProvider<TeamStateNotifier, String?>(
      (ref) => TeamStateNotifier(),
);