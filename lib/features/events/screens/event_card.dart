import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../utils/formatters.dart';
import '../../../theme/brand_tokens.dart';
import '../../../widgets/awning_edge.dart';
import '../../../widgets/favorite_heart.dart';
import '../../favorites/providers/favorite_provider.dart';
import 'event_detail_screen.dart';
import 'package:market_mates/l10n/l10n.dart';

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
                    // Awning over the picture: the stall look of the brand.
                    const Positioned(top: 0, left: 0, right: 0, child: AwningEdge(stripeWidth: 20, bandHeight: 5)),
                    Positioned(
                      top: 14,
                      right: 6,
                      child: FavoriteHeart(
                        isFavorite: isFavorite,
                        tooltip: isFavorite ? context.l10n.favoriteRemove : context.l10n.favoriteAdd,
                        onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite('events', event.id),
                      ),
                    ),
                    if (event.isDemo)
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: BrandColors.goldSoft, borderRadius: BorderRadius.circular(99)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              context.l10n.demoBadge,
                              style: const TextStyle(color: BrandColors.goldInk, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDateRange(event.startTime, event.endTime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: BrandColors.inkSoft),
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
