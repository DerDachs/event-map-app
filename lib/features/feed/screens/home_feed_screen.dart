import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/profile_menu.dart';
import '../../events/providers/event_provider.dart';
import '../../events/screens/event_card.dart';
import '../../favorites/providers/favorite_provider.dart';
import '../../seasons/models/season.dart';
import '../../seasons/providers/season_provider.dart';
import '../logic/home_feed.dart';
import '../models/feed_post.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_cards.dart';

/// Start page: season banner, the market of the moment, favourites, news
/// and all markets.
class HomeFeedScreen extends ConsumerWidget {
  /// Current time; replaceable for store screenshots of other seasons.
  final DateTime Function() clock;

  const HomeFeedScreen({super.key, this.clock = DateTime.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    // News are a bonus: if they fail to load, the markets still show.
    final posts = ref.watch(feedPostsProvider).valueOrNull ?? const <FeedPost>[];
    final favoriteIds = {...?ref.watch(favoritesProvider)['events']};
    final seasons = ref.watch(seasonsProvider).valueOrNull ?? const <Season>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
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
              Text(context.l10n.marketsLoadFailed),
              TextButton(
                onPressed: () => ref.invalidate(eventsProvider),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
        data: (events) {
          final now = clock();
          final lang = Localizations.localeOf(context).languageCode;
          final feed = buildHomeFeed(
            events: events,
            posts: [for (final p in posts) p.localized(lang)],
            favoriteIds: favoriteIds,
            now: now,
            l: context.l10n,
            season: currentSeason(seasons, now)?.localized(lang),
          );
          final eventsById = {for (final e in events) e.id: e};

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventsProvider);
              ref.invalidate(feedPostsProvider);
              ref.invalidate(seasonsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (feed.banner != null) SeasonBannerCard(banner: feed.banner!),
                if (feed.highlight != null)
                  HighlightCard(
                    event: feed.highlight!,
                    now: now,
                    isFavorite: favoriteIds.contains(feed.highlight!.id),
                    accent: feed.season?.accent,
                  ),
                if (feed.favorites.any((e) => e.id != feed.highlight?.id))
                  _EventRow(title: context.l10n.homeFavorites, events: feed.favorites),
                if (feed.items.isNotEmpty) ...[
                  _SectionTitle(context.l10n.homeNews),
                  for (final item in feed.items)
                    switch (item) {
                      PostItem(:final post) => FeedPostCard(
                          key: ValueKey('post_${post.id}'),
                          post: post,
                          event: post.eventId == null ? null : eventsById[post.eventId],
                          now: now,
                        ),
                      MarketItem() => MarketNewsCard(key: ValueKey('market_${item.event.id}'), item: item, now: now),
                    },
                ],
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(context.l10n.noMarkets),
                      ],
                    ),
                  ),
                if (feed.running.isNotEmpty) _EventRow(title: context.l10n.homeRunning, events: feed.running),
                if (feed.upcoming.isNotEmpty) _EventRow(title: context.l10n.homeUpcoming, events: feed.upcoming),
                if (feed.past.isNotEmpty) _EventRow(title: context.l10n.homePast, events: feed.past),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _EventRow extends StatelessWidget {
  final String title;
  final List<Event> events;

  const _EventRow({required this.title, required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
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
