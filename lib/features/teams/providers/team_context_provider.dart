import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeamStateNotifier extends StateNotifier<String?> {
  TeamStateNotifier() : super(null); // Null means no team joined

  void joinTeam(String teamId) {
    state = teamId; // Update with the team ID
  }

  void leaveTeam() {
    state = null; // Reset team context
  }
}

final teamContextProvider =
StateNotifierProvider<TeamStateNotifier, String?>((ref) => TeamStateNotifier());