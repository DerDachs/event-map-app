import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../widgets/profile_menu.dart';
import '../../favorites/providers/favorite_provider.dart';
import '../providers/event_provider.dart';
import 'event_card.dart';

/// Start screen: all markets, grouped by whether they are running now.
class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final favoriteIds = ref.watch(favoritesProvider)['events'] ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Mate'),
        actions: const [ProfileMenuButton()],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Die Märkte konnten nicht geladen werden.'),
              TextButton(
                onPressed: () => ref.invalidate(eventsProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (events) {
          final now = DateTime.now();
          final sorted = [...events]..sort((a, b) => a.startTime.compareTo(b.startTime));
          final running = sorted.where((e) => !e.startTime.isAfter(now) && e.endTime.isAfter(now)).toList();
          final upcoming = sorted.where((e) => e.startTime.isAfter(now)).toList();
          final past = sorted.where((e) => !e.endTime.isAfter(now)).toList().reversed.toList();
          final favorites = sorted.where((e) => favoriteIds.contains(e.id) && e.endTime.isAfter(now)).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(eventsProvider),
            child: events.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.storefront_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('Noch keine Märkte vorhanden.')),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (favorites.isNotEmpty) _EventSection(title: 'Deine Favoriten', events: favorites),
                      if (running.isNotEmpty) _EventSection(title: 'Läuft gerade', events: running),
                      if (upcoming.isNotEmpty) _EventSection(title: 'Demnächst', events: upcoming),
                      if (past.isNotEmpty) _EventSection(title: 'Vergangene Märkte', events: past),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  final String title;
  final List<Event> events;

  const _EventSection({required this.title, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: events.length,
            itemBuilder: (context, index) => EventCard(event: events[index]),
          ),
        ),
      ],
    );
  }
}
