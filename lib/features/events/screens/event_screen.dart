import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/event_card.dart';
import '../../favorites/providers/favorite_provider.dart';
import '../providers/event_provider.dart';
import 'event_detail_screen.dart';

class EventScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoriteEventIds = favorites['events'] ?? []; // Fetch favorite event IDs

    return Scaffold(
      body: eventsAsync.when(
        data: (events) {
          // Split events into categories for display
          final generalEvents = events.take(5).toList(); // Example logic
          final personalizedEvents = events.skip(5).take(3).toList(); // Example logic
          final favoriteEvents = events
              .where((event) => favoriteEventIds.contains(event.id))
              .toList(); // Filter events by favorite IDs

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Events Section
                  _buildEventSection(
                    context,
                    title: 'General Events',
                    events: generalEvents,
                  ),
                  SizedBox(height: 20),

                  // Personalized Events Section
                  _buildEventSection(
                    context,
                    title: 'For You',
                    events: personalizedEvents,
                  ),
                  SizedBox(height: 20),

                  // Favorite Events Section (only if favorites exist)
                  if (favoriteEvents.isNotEmpty)
                    _buildEventSection(
                      context,
                      title: 'Favorites',
                      events: favoriteEvents,
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading events: $error')),
      ),
    );
  }

  Widget _buildEventSection(
      BuildContext context, {
        required String title,
        required List events,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(event: event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, event) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );
        },
        child: Container(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    event.images.first.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              // Event Details
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 4),
                    Text(
                      event.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}