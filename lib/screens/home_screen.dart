import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_mates/screens/discover_screen.dart';
import 'package:market_mates/screens/social_hub_screen.dart';
import '../providers/state_provider.dart';
import '../features/events/screens/event_screen.dart';
import 'layout/base_layout.dart';

class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current tab index from Riverpod
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // List of screens for the BottomNavigationBar
    final screens = [
      EventScreen(),
      DiscoverScreen(),
      SocialHubScreen()
    ];

    return BaseLayout(
      body: screens[currentIndex],
      title: currentIndex == 0
          ? "Home"
          : currentIndex == 1
          ? "Discover"
          : "Social Hub",
    );
  }
}