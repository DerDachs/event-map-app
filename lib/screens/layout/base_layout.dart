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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ref.watch(bottomNavIndexProvider), // From Riverpod
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: context.l10n.navInfo),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: context.l10n.navMap),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: context.l10n.navTeam),
        ],
      ),
    );
  }
}
