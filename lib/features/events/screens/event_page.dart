import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/event.dart';
import '../../../providers/state_provider.dart';
import '../../../screens/layout/base_layout.dart';
import 'event_details_tab.dart';
import 'map_stands_tab.dart';
import 'team_tab.dart';

class EventPage extends ConsumerStatefulWidget {
  final Event event;

  EventPage({required this.event});

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends ConsumerState<EventPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the current tab index from Riverpod
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // List of screens for the BottomNavigationBar
    final screens = [
      EventDetailsTab(event: widget.event),
      MapStandsTab(event: widget.event,),
      TeamTab(event: widget.event),
    ];

    return BaseLayout(
      title: widget.event.name,
      body: screens[currentIndex],
    );
  }
}