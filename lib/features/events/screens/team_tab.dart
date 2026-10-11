import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../data/models/team.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/profile_menu.dart';
import '../../teams/providers/team_provider.dart';
import '../../teams/services/team_service.dart';

class TeamTab extends ConsumerWidget {
  final Event event;

  const TeamTab({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(myTeamProvider(event.id));
    return teamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Team konnte nicht geladen werden.\n$e', textAlign: TextAlign.center)),
      data: (team) => team == null ? _NoTeam(event: event) : _TeamView(team: team),
    );
  }
}

class _NoTeam extends ConsumerWidget {
  final Event event;

  const _NoTeam({required this.event});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _askText(
      context,
      title: 'Team gründen',
      label: 'Teamname',
      hint: 'z. B. Glühwein-Crew',
      action: 'Gründen',
    );
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (name == null || uid == null) return;
    try {
      await ref.read(teamServiceProvider).createTeam(event.id, uid, name);
    } catch (e) {
      if (context.mounted) _snack(context, 'Team konnte nicht gegründet werden: $e');
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final code = await _askText(
      context,
      title: 'Team beitreten',
      label: 'Team-Code',
      hint: '6 Zeichen, z. B. K7Q2XM',
      action: 'Beitreten',
      capitalize: true,
    );
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (code == null || uid == null) return;
    try {
      final team = await ref.read(teamServiceProvider).joinByCode(code, event.id, uid);
      if (context.mounted) _snack(context, 'Willkommen im Team „${team.name}“!');
    } on TeamException catch (e) {
      if (context.mounted) _snack(context, e.message);
    } catch (e) {
      if (context.mounted) _snack(context, 'Beitreten fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.groups_outlined, size: 72, color: Colors.grey),
        const SizedBox(height: 16),
        Text('Gemeinsam über den Markt',
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Gründe ein Team und teile den Code mit deinen Freunden – oder tritt mit einem Code bei.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Team gründen'),
          onPressed: () => _create(context, ref),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Mit Code beitreten'),
          onPressed: () => _join(context, ref),
        ),
      ],
    );
  }
}

class _TeamView extends ConsumerWidget {
  final Team team;

  const _TeamView({required this.team});

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team verlassen?'),
        content: Text(team.members.length == 1
            ? 'Du bist das letzte Mitglied – das Team wird dann gelöscht.'
            : 'Du kannst später mit dem Code wieder beitreten.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verlassen')),
        ],
      ),
    );
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (ok != true || uid == null) return;
    try {
      await ref.read(teamServiceProvider).leave(team, uid);
    } catch (e) {
      if (context.mounted) _snack(context, 'Verlassen fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(team.members.join(',')));
    final myUid = ref.watch(userProfileProvider).valueOrNull?.uid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(team.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Team-Code'),
            subtitle: Text(
              team.teamCode,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 4),
            ),
            trailing: IconButton(
              tooltip: 'Code kopieren',
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: team.teamCode));
                _snack(context, 'Code kopiert – schick ihn deinen Freunden.');
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Mitglieder (${team.members.length})', style: Theme.of(context).textTheme.titleMedium),
        membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Mitglieder konnten nicht geladen werden: $e'),
          data: (members) => Column(
            children: [
              for (final m in members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(profile: m, radius: 20),
                  title: Text(m.uid == myUid ? '${m.name ?? 'Unbekannt'} (du)' : m.name ?? 'Unbekannt'),
                  trailing: m.uid == team.leaderId
                      ? const Chip(label: Text('Gründer'), visualDensity: VisualDensity.compact)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            enabled: false,
            leading: Icon(Icons.share_location_outlined),
            title: Text('Standort mit dem Team teilen'),
            subtitle: Text('Kommt bald'),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.logout),
          label: const Text('Team verlassen'),
          onPressed: () => _leave(context, ref),
        ),
      ],
    );
  }
}

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String action,
  bool capitalize = false,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      void submit() {
        final value = controller.text.trim();
        if (value.isNotEmpty) Navigator.pop(context, value);
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label, hintText: hint),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          FilledButton(onPressed: submit, child: Text(action)),
        ],
      );
    },
  );
}
