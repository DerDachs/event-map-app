import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/formatters.dart';
import '../../events/providers/event_provider.dart';
import 'market_edit_screen.dart';

/// Admin list of all markets, newest first, to pick one for editing.
class MarketListScreen extends ConsumerStatefulWidget {
  const MarketListScreen({super.key});

  @override
  ConsumerState<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends ConsumerState<MarketListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Märkte bearbeiten')),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Die Märkte konnten nicht geladen werden: $e')),
        data: (events) {
          final q = _query.toLowerCase();
          final list = events.where((e) => q.isEmpty || e.name.toLowerCase().contains(q)).toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(eventsProvider),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Markt suchen'),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Keine Märkte gefunden.', textAlign: TextAlign.center),
                  ),
                for (final event in list)
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(event.name),
                    subtitle: Text('${formatDateRange(event.startTime, event.endTime)} · '
                        '${event.stands.length} Stände'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MarketEditScreen(eventId: event.id)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
