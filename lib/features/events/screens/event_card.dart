import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../utils/formatters.dart';
import '../../favorites/providers/favorite_provider.dart';
import 'event_detail_screen.dart';

class EventCard extends ConsumerWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites['events']?.contains(event.id) ?? false;
    final image = event.images.where((i) => i.isStandard).firstOrNull ?? event.images.firstOrNull;

    return SizedBox(
      width: 260,
      child: Card(
        margin: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image == null
                        ? const _ImagePlaceholder()
                        : Image.network(
                            image.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                          ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        tooltip: isFavorite ? 'Aus Favoriten entfernen' : 'Merken',
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                        onPressed: () =>
                            ref.read(favoritesProvider.notifier).toggleFavorite('events', event.id),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateRange(event.startTime, event.endTime),
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
      );
}
