import 'package:flutter/material.dart';

import '../../../data/models/event.dart';
import '../../../l10n/l10n.dart';
import '../widgets/event_info.dart';
import 'team_tab.dart';

/// Dates, opening hours and practical information, opened from the market map.
class MarketInfoScreen extends StatelessWidget {
  final Event event;

  const MarketInfoScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.marketInfoAction)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          child: EventInfo(event: event),
        ),
      );
}

/// The user's team at this market, opened from the market map.
class MarketTeamScreen extends StatelessWidget {
  final Event event;

  const MarketTeamScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l10n.marketTeamAction)),
        body: TeamTab(event: event),
      );
}
