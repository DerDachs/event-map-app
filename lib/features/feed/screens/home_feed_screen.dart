import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/event.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/user_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/brand_tokens.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/awning_edge.dart';
import '../../../widgets/empty_state.dart';
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

/// Start page: a big greeting with market search, then season banner, the
/// market of the moment, favourites, news and all markets.
class HomeFeedScreen extends ConsumerStatefulWidget {
  /// Current time; replaceable for store screenshots of other seasons.
  final DateTime Function() clock;

  const HomeFeedScreen({super.key, this.clock = DateTime.now});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    // News are a bonus: if they fail to load, the markets still show.
    final posts = ref.watch(feedPostsProvider).valueOrNull ?? const <FeedPost>[];
    final favoriteIds = {...?ref.watch(favoritesProvider)['events']};
    final seasons = ref.watch(seasonsProvider).valueOrNull ?? const <Season>[];
    final name = ref.watch(userProfileProvider).valueOrNull?.name?.trim();

    return Scaffold(
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off,
          title: context.l10n.marketsLoadFailed,
          actionLabel: context.l10n.retry,
          onAction: () => ref.invalidate(eventsProvider),
        ),
        data: (events) {
          final now = widget.clock();
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
          final header = _HomeHeader(
            greeting: (name ?? '').isEmpty ? null : context.l10n.homeGreeting(name!.split(' ').first),
            controller: _search,
            showClear: _query.isNotEmpty,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            onClear: () {
              _search.clear();
              setState(() => _query = '');
            },
          );

          if (_query.isNotEmpty) {
            final hits = matchingMarkets(events, _query, now);
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                header,
                _SectionTitle(context.l10n.homeSearchResults),
                if (hits.isEmpty)
                  EmptyState(icon: Icons.search_off, title: context.l10n.marketSearchNone)
                else
                  for (final e in hits) _MarketResultTile(event: e, now: now),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventsProvider);
              ref.invalidate(feedPostsProvider);
              ref.invalidate(seasonsProvider);
            },
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                header,
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
                if (feed.running.isNotEmpty) _EventRow(title: context.l10n.homeRunning, events: feed.running),
                if (feed.upcoming.isNotEmpty) _EventRow(title: context.l10n.homeUpcoming, events: feed.upcoming),
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
                  EmptyState(
                    icon: Icons.storefront_outlined,
                    title: context.l10n.noMarkets,
                    hint: context.l10n.noMarketsHint,
                  ),
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
        child: Text(title, style: brandDisplay(28)),
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

/// Awning, greeting with profile button, the big question and market search.
class _HomeHeader extends StatelessWidget {
  final String? greeting;
  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _HomeHeader({
    required this.greeting,
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top),
        const AwningEdge(stripeWidth: 26, bandHeight: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  greeting ?? context.l10n.appTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: BrandColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const ProfileMenuButton(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(context.l10n.homeHeadline, style: brandDisplay(52)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: context.l10n.marketSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: showClear ? IconButton(icon: const Icon(Icons.close), onPressed: onClear) : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: BrandColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: BrandColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: BrandColors.red, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One market in the search results: picture, name, dates and status.
class _MarketResultTile extends StatelessWidget {
  final Event event;
  final DateTime now;

  const _MarketResultTile({required this.event, required this.now});

  @override
  Widget build(BuildContext context) {
    final image = coverImage(event);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEvent(context, event),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 84,
                child: image == null
                    ? const ColoredBox(
                        color: BrandColors.sand,
                        child: Icon(Icons.storefront_outlined, color: BrandColors.inkSoft),
                      )
                    : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: BrandColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDateRange(event.startTime, event.endTime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: BrandColors.inkSoft, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        marketStatusLabel(event, now, context.l10n),
                        style: const TextStyle(color: BrandColors.red, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: BrandColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
