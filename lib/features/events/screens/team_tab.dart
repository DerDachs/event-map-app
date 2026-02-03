import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_mates/features/teams/screens/team_section.dart';
import '../../../data/models/event.dart';
//import '../../teams/providers/team_context_provider.dart';
import '../../teams/providers/team_provider.dart';


class TeamTab extends ConsumerWidget {
  final Event event;

  TeamTab({required this.event});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userTeamId = ref.watch(teamContextProvider);
    //final teamContext = ref.watch(teamsForEventFutureProvider);

    return userTeamId != null
        ? Center(child: Text('You are in Team: $userTeamId'))
        : TeamSection(event: event, isInTeam: userTeamId != null,
        teamId: userTeamId);
  }
}