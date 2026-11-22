import 'package:flutter/material.dart';

import '../../../data/models/event.dart';
import 'map_stands_tab.dart';

/// A joined market: the map is the page. Infos and team open from the sheet
/// at the bottom (see [MapStandsTab]).
class EventPage extends StatelessWidget {
  final Event event;

  const EventPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        body: MapStandsTab(event: event),
      );
}
