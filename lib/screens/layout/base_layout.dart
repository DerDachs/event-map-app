import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/profile_menu.dart';
import '../../providers/state_provider.dart';
import 'package:market_mates/l10n/l10n.dart';

class BaseLayout extends ConsumerWidget {
  final Widget body;
  final String title;
  final List<Widget> actions;

  const BaseLayout({
    Key? key,
    required this.body,
    required this.title,
    this.actions = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [...actions, const ProfileMenuButton()],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: ref.watch(bottomNavIndexProvider), // From Riverpod
        onDestinationSelected: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: context.l10n.navInfo,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: context.l10n.navMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: context.l10n.navTeam,
          ),
        ],
      ),
    );
  }
}
