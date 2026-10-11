import 'package:flutter/material.dart';

import '../../../data/models/event.dart';
import '../widgets/event_info.dart';

class EventDetailsTab extends StatelessWidget {
  final Event event;

  const EventDetailsTab({super.key, required this.event});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16),
        child: EventInfo(event: event),
      );
}
