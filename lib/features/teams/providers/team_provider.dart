import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/team.dart';
import '../services/team_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider for the TeamService
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(FirebaseFirestore.instance);
});

// Fetch teams for an event
final teamsForEventProvider =
StreamProvider.family<List<Team>, String>((ref, eventId) {
  final teamService = ref.read(teamServiceProvider);
  return teamService.fetchTeamsForEvent(eventId);
});

// Fetch teams for a user
//final teamsForUserProvider =
//StreamProvider.family<List<Team>, String>((ref, userId) {
//  final teamService = ref.read(teamServiceProvider);
//  return teamService.fetchTeamsForUser(userId);
//});