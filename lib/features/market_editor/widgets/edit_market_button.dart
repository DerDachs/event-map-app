import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/user_provider.dart';
import '../screens/market_edit_screen.dart';

/// App bar action that opens the market editor. Only shown to admins.
class EditMarketButton extends ConsumerWidget {
  final String eventId;

  const EditMarketButton({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(userProfileProvider).valueOrNull?.role != 'admin') return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Markt bearbeiten',
      icon: const Icon(Icons.edit_outlined),
      onPressed: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => MarketEditScreen(eventId: eventId)),
        );
        // This page still shows the old data; the start page reloads.
        if (changed == true && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }
}
