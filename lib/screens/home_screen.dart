import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/state_provider.dart';
import 'event_screen.dart';
import 'layout/base_layout.dart';
import 'settings_screen.dart';// Import the provider

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current tab index from Riverpod
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // List of screens for the BottomNavigationBar
    final screens = [
      Center(child: Text("Home Screen Content")),
      EventScreen(),
      SettingsScreen(),
    ];

    return BaseLayout(
      body: screens[currentIndex],
      title: currentIndex == 0
          ? "Home"
          : currentIndex == 1
          ? "Events"
          : "Settings",
    );
  }
}