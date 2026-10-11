import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/profile_menu.dart';
import '../../providers/state_provider.dart';

class BaseLayout extends ConsumerWidget {
  final Widget body;
  final String title;

  const BaseLayout({
    Key? key,
    required this.body,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [ProfileMenuButton()],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: ref.watch(bottomNavIndexProvider), // From Riverpod
        onTap: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "Infos"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Karte"),
          BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: "Team"),
        ],
      ),
    );
  }
}
