import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../data/models/team.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/profile_menu.dart';
import '../../teams/providers/team_provider.dart';
import '../../teams/services/team_service.dart';
import 'package:market_mates/l10n/l10n.dart';

class TeamTab extends ConsumerWidget {
  final Event event;

  const TeamTab({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(myTeamProvider(event.id));
    return teamAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.teamLoadFailed('$e'), textAlign: TextAlign.center)),
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
      title: context.l10n.teamCreateTitle,
      label: context.l10n.teamNameLabel,
      hint: context.l10n.teamNameHint,
      action: context.l10n.teamCreateAction,
    );
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (name == null || uid == null) return;
    try {
      await ref.read(teamServiceProvider).createTeam(event.id, uid, name);
    } catch (e) {
      if (context.mounted) _snack(context, context.l10n.teamCreateFailed('$e'));
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final code = await _askText(
      context,
      title: context.l10n.teamJoinTitle,
      label: context.l10n.teamCodeLabel,
      hint: context.l10n.teamCodeHint,
      action: context.l10n.teamJoinAction,
      capitalize: true,
    );
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (code == null || uid == null) return;
    try {
      final team = await ref.read(teamServiceProvider).joinByCode(code, event.id, uid);
      if (context.mounted) _snack(context, context.l10n.teamWelcome(team.name));
    } on TeamException catch (e) {
      if (context.mounted) _snack(context, e.code == 'other-market' ? context.l10n.teamOtherMarket : context.l10n.teamNotFound);
    } catch (e) {
      if (context.mounted) _snack(context, context.l10n.joinFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.groups_outlined, size: 72, color: Colors.grey),
        const SizedBox(height: 16),
        Text(context.l10n.teamIntroTitle,
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          context.l10n.teamIntroText,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: Text(context.l10n.teamCreateTitle),
          onPressed: () => _create(context, ref),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.login),
          label: Text(context.l10n.teamJoinWithCode),
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
        title: Text(context.l10n.teamLeaveTitle),
        content: Text(team.members.length == 1
            ? context.l10n.teamLeaveLast
            : context.l10n.teamLeaveRejoin),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.teamLeaveAction)),
        ],
      ),
    );
    final uid = ref.read(userProfileProvider).valueOrNull?.uid;
    if (ok != true || uid == null) return;
    try {
      await ref.read(teamServiceProvider).leave(team, uid);
    } catch (e) {
      if (context.mounted) _snack(context, context.l10n.teamLeaveFailed('$e'));
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
            title: Text(context.l10n.teamCodeLabel),
            subtitle: Text(
              team.teamCode,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 4),
            ),
            trailing: IconButton(
              tooltip: context.l10n.teamCopyCode,
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: team.teamCode));
                _snack(context, context.l10n.teamCodeCopied);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(context.l10n.teamMembers(team.members.length), style: Theme.of(context).textTheme.titleMedium),
        membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(context.l10n.teamMembersLoadFailed('$e')),
          data: (members) => Column(
            children: [
              for (final m in members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(profile: m, radius: 20),
                  title: Text(m.uid == myUid ? context.l10n.teamMemberYou(m.name ?? context.l10n.unknownUser) : m.name ?? context.l10n.unknownUser),
                  trailing: m.uid == team.leaderId
                      ? Chip(label: Text(context.l10n.teamFounder), visualDensity: VisualDensity.compact)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            enabled: false,
            leading: const Icon(Icons.share_location_outlined),
            title: Text(context.l10n.teamShareLocation),
            subtitle: Text(context.l10n.comingSoon),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          icon: const Icon(Icons.logout),
          label: Text(context.l10n.teamLeave),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: submit, child: Text(action)),
        ],
      );
    },
  );
}
