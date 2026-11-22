import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../data/models/team.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/brand_tokens.dart';
import '../../../widgets/awning_edge.dart';
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
      data: (team) => team == null ? _NoTeam(event: event) : _TeamView(team: team, event: event),
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
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      children: [
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(color: BrandColors.goldSoft, shape: BoxShape.circle),
            child: const Icon(Icons.groups_rounded, size: 60, color: BrandColors.red),
          ),
        ),
        const SizedBox(height: 24),
        Text(context.l10n.teamIntroTitle, textAlign: TextAlign.center, style: brandDisplay(34)),
        const SizedBox(height: 8),
        Text(
          context.l10n.teamIntroText,
          textAlign: TextAlign.center,
          style: text.bodyLarge?.copyWith(color: BrandColors.inkSoft),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: Text(context.l10n.teamCreateTitle),
          onPressed: () => _create(context, ref),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.vpn_key_outlined),
          label: Text(context.l10n.teamJoinWithCode),
          onPressed: () => _join(context, ref),
        ),
      ],
    );
  }
}

class _TeamView extends ConsumerWidget {
  final Team team;
  final Event event;

  const _TeamView({required this.team, required this.event});

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.teamLeaveTitle),
        content: Text(team.members.length == 1 ? context.l10n.teamLeaveLast : context.l10n.teamLeaveRejoin),
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

  Future<void> _renew(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.teamRenewCode),
        content: Text(context.l10n.teamRenewCodeText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.teamRenewCode)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teamServiceProvider).renewCode(team);
      if (context.mounted) _snack(context, context.l10n.teamCodeRenewed);
    } catch (e) {
      if (context.mounted) _snack(context, context.l10n.teamRenewFailed('$e'));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final membersAsync = ref.watch(teamMembersProvider(team.members.join(',')));
    final myUid = ref.watch(userProfileProvider).valueOrNull?.uid;
    final isLeader = myUid == team.leaderId;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(team.name, style: brandDisplay(40)),
        const SizedBox(height: 12),
        // The code as a market sign: awning on top, big letters below.
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AwningEdge(stripeWidth: 20, bandHeight: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Text(context.l10n.teamCodeLabel.toUpperCase(),
                        style: text.labelMedium?.copyWith(color: BrandColors.inkSoft, letterSpacing: 1.4)),
                    const SizedBox(height: 4),
                    SelectableText(
                      team.teamCode,
                      textAlign: TextAlign.center,
                      style: brandDisplay(56, letterSpacing: 8, color: BrandColors.red),
                    ),
                    const SizedBox(height: 4),
                    Text(context.l10n.teamCodeHow,
                        textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: BrandColors.inkSoft)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.ios_share),
                      label: Text(context.l10n.teamInviteCopy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: context.l10n.teamInviteText(team.name, event.name, team.teamCode),
                        ));
                        _snack(context, context.l10n.teamInviteCopied);
                      },
                    ),
                    if (isLeader)
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(context.l10n.teamRenewCode),
                        onPressed: () => _renew(context, ref),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(context.l10n.teamMembers(team.members.length), style: brandDisplay(26)),
        const SizedBox(height: 4),
        membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(context.l10n.teamMembersLoadFailed('$e')),
          data: (members) => Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final m in members)
                  ListTile(
                    leading: UserAvatar(profile: m, radius: 20),
                    title: Text(
                      m.uid == myUid
                          ? context.l10n.teamMemberYou(m.name ?? context.l10n.unknownUser)
                          : m.name ?? context.l10n.unknownUser,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: m.uid == team.leaderId
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: BrandColors.goldSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Text(
                                context.l10n.teamFounder,
                                style: const TextStyle(
                                    color: BrandColors.goldInk, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            enabled: false,
            leading: const Icon(Icons.share_location_outlined),
            title: Text(context.l10n.teamShareLocation),
            subtitle: Text(context.l10n.comingSoon),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: BrandColors.red),
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

/// Asks for one line of text in a bottom sheet that sits above the keyboard.
Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String action,
  bool capitalize = false,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      void submit() {
        final value = controller.text.trim();
        if (value.isNotEmpty) Navigator.pop(context, value);
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: brandDisplay(30)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.sentences,
              style: capitalize ? brandDisplay(30, letterSpacing: 6) : null,
              textAlign: capitalize ? TextAlign.center : TextAlign.start,
              decoration: InputDecoration(labelText: label, hintText: hint),
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: submit, child: Text(action)),
          ],
        ),
      );
    },
  );
}
