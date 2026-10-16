import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:market_mates/data/models/event.dart';
import 'package:market_mates/features/feed/logic/home_feed.dart';
import 'package:market_mates/features/feed/models/feed_post.dart';
import 'package:market_mates/features/seasons/models/season.dart';
import 'package:market_mates/l10n/app_localizations.dart';

Event _market(String id, DateTime start, DateTime end, {DateTime? createdAt, String type = 'christmas_market'}) =>
    Event(
      id: id,
      name: 'Markt $id',
      description: '',
      startTime: start,
      endTime: end,
      latitude: 0,
      longitude: 0,
      category: type,
      teamIds: const [],
      images: const [],
      stands: const [],
      createdAt: createdAt,
    );

FeedPost _post(String id, DateTime publishAt, {bool pinned = false, DateTime? expiresAt, String? seasonId}) =>
    FeedPost(
      id: id,
      type: FeedPostType.news,
      title: id,
      body: '',
      publishAt: publishAt,
      pinned: pinned,
      expiresAt: expiresAt,
      seasonId: seasonId,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'de';
  });
  final l = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('first Sunday of Advent', () {
    expect(firstAdventSunday(2026), DateTime(2026, 11, 29));
    expect(firstAdventSunday(2025), DateTime(2025, 11, 30));
    expect(firstAdventSunday(2022), DateTime(2022, 11, 27)); // Christmas on a Sunday
    expect(firstAdventSunday(2023), DateTime(2023, 12, 3)); // Christmas Eve on a Sunday
  });

  final christmas = Season(
    id: 'xmas',
    name: 'Weihnachtsmärkte 2026',
    tagline: 'Glühwein und Lichter',
    startsAt: DateTime(2026, 10, 1),
    endsAt: DateTime(2027, 1, 7),
    marketTypes: const ['christmas_market'],
    countdownTo: DateTime(2026, 12, 24),
    countdownLabel: 'Heiligabend',
    milestones: [SeasonMilestone('1. Advent', DateTime(2026, 11, 29)), SeasonMilestone('2. Advent', DateTime(2026, 12, 6))],
  );

  test('season banner counts down and names the next milestone', () {
    final b = SeasonBanner.of(christmas, DateTime(2026, 10, 14, 15), l);
    expect(b.bigNumber, 71);
    expect(b.headline, 'Tage bis Heiligabend');
    expect(b.subline, '1. Advent am 29. November');
    expect(SeasonBanner.of(christmas, DateTime(2026, 11, 28), l).subline, 'Morgen: 1. Advent');
    expect(SeasonBanner.of(christmas, DateTime(2026, 12, 1), l).subline, '2. Advent am 6. Dezember');

    final eve = SeasonBanner.of(christmas, DateTime(2026, 12, 24, 20), l);
    expect(eve.bigNumber, isNull);
    expect(eve.headline, 'Heute ist Heiligabend');
    expect(eve.subline, 'Weihnachtsmärkte 2026');

    final after = SeasonBanner.of(christmas, DateTime(2026, 12, 28), l);
    expect(after.headline, 'Weihnachtsmärkte 2026');
    expect(after.subline, 'Glühwein und Lichter');

    final english = SeasonBanner.of(christmas, DateTime(2026, 10, 14, 15), en);
    expect(english.headline, 'days until Heiligabend');
    expect(english.subline, '1. Advent on November 29');
  });

  test('current season: running and active, the most recently started wins', () {
    final autumn = Season(id: 'autumn', name: 'Herbst', startsAt: DateTime(2026, 9, 1), endsAt: DateTime(2026, 11, 1));
    final off = Season(
        id: 'off', name: 'Aus', startsAt: DateTime(2026, 10, 10), endsAt: DateTime(2026, 10, 20), active: false);
    expect(currentSeason([autumn, christmas, off], DateTime(2026, 9, 15))?.id, 'autumn');
    expect(currentSeason([autumn, christmas, off], DateTime(2026, 10, 14))?.id, 'xmas');
    expect(currentSeason([autumn, christmas], DateTime(2027, 2, 1)), isNull);
  });

  test('status labels', () {
    final now = DateTime(2026, 11, 20, 18);
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 20, 20), DateTime(2026, 12, 23)), now, l), 'Öffnet heute');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 21, 11), DateTime(2026, 12, 23)), now, l), 'Öffnet morgen');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 25, 11), DateTime(2026, 12, 23)), now, l), 'Öffnet in 5 Tagen');
    expect(marketStatusLabel(_market('a', DateTime(2026, 12, 20), DateTime(2026, 12, 23)), now, l), 'Ab 20. Dezember');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 13), DateTime(2026, 11, 20, 22)), now, l), 'Letzter Tag');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 13), DateTime(2026, 11, 30)), now, l), 'Läuft · noch 10 Tage');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 1), DateTime(2026, 11, 2)), now, l), 'Vorbei');
  });

  test('highlight prefers open favourites, then open markets, then the next one', () {
    final now = DateTime(2026, 11, 26, 12);
    final open = _market('open', DateTime(2026, 11, 16), DateTime(2026, 12, 23));
    final openFav = _market('openFav', DateTime(2026, 11, 25), DateTime(2026, 12, 24));
    final next = _market('next', DateTime(2026, 11, 27), DateTime(2026, 12, 24));
    HomeFeed feed(Set<String> favs, List<Event> events) =>
        buildHomeFeed(events: events, posts: const [], favoriteIds: favs, now: now, l: l);

    expect(feed({'openFav'}, [open, openFav, next]).highlight?.id, 'openFav');
    expect(feed({}, [open, openFav, next]).highlight?.id, 'open');
    expect(feed({}, [next]).highlight?.id, 'next');
  });

  test('feed: pinned first, hidden posts left out, markets add news', () {
    final now = DateTime(2026, 11, 20, 12);
    final events = [
      _market('running', DateTime(2026, 11, 13), DateTime(2027, 1, 3)), // highlight, no extra card
      _market('soon', DateTime(2026, 11, 25), DateTime(2026, 12, 24)),
      _market('ending', DateTime(2026, 11, 1), DateTime(2026, 11, 22)),
      _market('new', DateTime(2026, 12, 10), DateTime(2026, 12, 20), createdAt: DateTime(2026, 11, 19)),
      _market('later', DateTime(2026, 12, 10), DateTime(2026, 12, 20)),
    ];
    final posts = [
      _post('old', DateTime(2026, 10, 14)),
      _post('pinned', DateTime(2026, 10, 1), pinned: true),
      _post('scheduled', DateTime(2026, 11, 30)),
      _post('expired', DateTime(2026, 10, 14), expiresAt: DateTime(2026, 11, 1)),
    ];
    final feed = buildHomeFeed(events: events, posts: posts, favoriteIds: const {}, now: now, l: l);
    final ids = feed.items
        .map((i) => switch (i) { PostItem(:final post) => post.id, MarketItem(:final event) => event.id })
        .toList();

    expect(feed.highlight?.id, 'ending');
    expect(ids.first, 'pinned');
    expect(ids, isNot(contains('scheduled')));
    expect(ids, isNot(contains('expired')));
    expect(ids, isNot(contains('later')));
    expect(ids, containsAll(['soon', 'new', 'old']));
    expect(ids.indexOf('new'), lessThan(ids.indexOf('old')), reason: 'newest first');
  });

  test('a season prefers its own markets and hides other seasons\' posts', () {
    final now = DateTime(2026, 11, 26, 12);
    final wine = _market('wine', DateTime(2026, 11, 1), DateTime(2026, 11, 30), type: 'wine_festival');
    final xmas = _market('xmas', DateTime(2026, 11, 27), DateTime(2026, 12, 24));
    final posts = [
      _post('all-year', DateTime(2026, 10, 1)),
      _post('xmas-post', DateTime(2026, 10, 2), seasonId: 'xmas'),
      _post('spring-post', DateTime(2026, 10, 3), seasonId: 'spring'),
    ];
    final withSeason =
        buildHomeFeed(events: [wine, xmas], posts: posts, favoriteIds: const {}, now: now, l: l, season: christmas);
    expect(withSeason.highlight?.id, 'xmas', reason: 'season market beats an open market of another kind');
    final ids = withSeason.items.whereType<PostItem>().map((i) => i.post.id).toList();
    expect(ids, containsAll(['all-year', 'xmas-post']));
    expect(ids, isNot(contains('spring-post')));

    final without = buildHomeFeed(events: [wine, xmas], posts: posts, favoriteIds: const {}, now: now, l: l);
    expect(without.highlight?.id, 'wine');
    expect(without.banner, isNull);
    expect(without.items.whereType<PostItem>().map((i) => i.post.id), ['all-year']);
  });
}
