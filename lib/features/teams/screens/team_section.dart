import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/event.dart';
import '../../../data/models/team.dart';
import '../../../providers/user_provider.dart';
import '../providers/team_provider.dart';

class TeamSection extends ConsumerWidget {
  final Event event;
  final bool isInTeam;
  final String? teamId;

  TeamSection({
    Key? key,
    required this.event,
    required this.isInTeam,
    this.teamId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isInTeam && teamId != null) {
      return _buildShareLocationSection(context, ref, teamId!);
    } else {
      final userProfile = ref.read(userProfileProvider).value;
      final userId = userProfile?.uid ?? '';
      return _buildJoinCreateTeamSection(context, ref, userId);
    }
  }

  Widget _buildJoinCreateTeamSection(BuildContext context, WidgetRef ref, String userId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Section',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => _showJoinTeamDialog(context, ref, userId),
                child: Text('Join Team'),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showCreateTeamDialog(context, ref, event.id, userId),
                icon: Icon(Icons.add),
                label: Text('Create Team'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareLocationSection(
      BuildContext context, WidgetRef ref, String userTeamId) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are in Team: $userTeamId',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final userProfile = ref.read(userProfileProvider).value;
              if (userProfile != null) {
                await shareLocation(context, const Duration(hours: 1), userProfile.uid);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location shared for 1 hour')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User not logged in')),
                );
              }
            },
            icon: Icon(Icons.location_on),
            label: Text('Share Location'),
          ),
          ElevatedButton(
            onPressed: () {
              // Logic to leave team
              ref.read(teamContextProvider.notifier).leaveTeam();
            },
            child: Text('Leave Team'),
          ),
        ],
      ),
    );
  }

  void _showJoinTeamDialog(BuildContext context, WidgetRef ref, String userId) {
    final _teamCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Join Team'),
          content: TextField(
            controller: _teamCodeController,
            decoration: InputDecoration(
              hintText: 'Enter Team Code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final teamCode = _teamCodeController.text.trim();
                if (teamCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a team code')),
                  );
                  return;
                }

                // Call join team logic
                await joinTeam(context, ref, teamCode, userId);

                ref.refresh(teamsForEventFutureProvider(event.id));

                // Wait for the state update and navigate back safely
                Future.microtask(() => Navigator.pop(context));// Trigger state update to refresh UI);
                //Future.microtask(() => ref.refresh(teamContextProvider));
              },
              child: Text('Join'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref, String eventId, String userId) {
    final _teamNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create a Team'),
          content: TextField(
            controller: _teamNameController,
            decoration: InputDecoration(
              labelText: 'Team Name',
              hintText: 'Enter your team name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final teamName = _teamNameController.text.trim();
                if (teamName.isNotEmpty) {
                  try {
                    final teamService = ref.read(teamServiceProvider);
                    await teamService.createTeam(eventId, userId, teamName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('Team "$teamName" created successfully!')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating team: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid team name')),
                  );
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> joinTeam(BuildContext context, WidgetRef ref, String teamCode, String userId) async {
    try {
      // Make a direct async call to fetch the team by code
      final teamService = ref.read(teamServiceProvider);
      final team = await teamService.getTeamByCode(teamCode);

      if (team == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team not found')),
        );
        return;
      }

      // Add user to the team
      await teamService.addMemberToTeam(team.id, userId);

      // Update the team context AFTER confirming success
      ref.read(teamContextProvider.notifier).joinTeam(team.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined the team!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining team: $e')),
      );
    }
  }

  Future<void> shareLocation(
      BuildContext context, Duration duration, String userId) async {
    // Replace with logic to update Firestore with shared location for `userId`
    print('User $userId is sharing location for $duration');
  }
}