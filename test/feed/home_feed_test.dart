import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:market_mates/data/models/event.dart';
import 'package:market_mates/features/feed/logic/home_feed.dart';
import 'package:market_mates/features/feed/models/feed_post.dart';

Event _market(String id, DateTime start, DateTime end, {DateTime? createdAt}) => Event(
      id: id,
      name: 'Markt $id',
      description: '',
      startTime: start,
      endTime: end,
      latitude: 0,
      longitude: 0,
      category: 'christmas_market',
      teamIds: const [],
      images: const [],
      stands: const [],
      createdAt: createdAt,
    );

FeedPost _post(String id, DateTime publishAt, {bool pinned = false, DateTime? expiresAt}) => FeedPost(
      id: id,
      type: FeedPostType.news,
      title: id,
      body: '',
      publishAt: publishAt,
      pinned: pinned,
      expiresAt: expiresAt,
    );

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  test('first Sunday of Advent', () {
    expect(firstAdventSunday(2026), DateTime(2026, 11, 29));
    expect(firstAdventSunday(2025), DateTime(2025, 11, 30));
    expect(firstAdventSunday(2022), DateTime(2022, 11, 27)); // Christmas on a Sunday
    expect(firstAdventSunday(2023), DateTime(2023, 12, 3)); // Christmas Eve on a Sunday
  });

  test('countdown runs from October to Christmas Eve', () {
    final c = SeasonCountdown.at(DateTime(2026, 10, 14, 15))!;
    expect(c.daysToChristmasEve, 71);
    expect(c.headline, 'Noch 71 Tage bis Heiligabend');
    expect(c.subline, '1. Advent am 29. November');
    expect(SeasonCountdown.at(DateTime(2026, 12, 24, 20))!.headline, 'Heute ist Heiligabend');
    expect(SeasonCountdown.at(DateTime(2026, 9, 30)), isNull);
    expect(SeasonCountdown.at(DateTime(2026, 12, 26)), isNull);
  });

  test('status labels', () {
    final now = DateTime(2026, 11, 20, 18);
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 20, 20), DateTime(2026, 12, 23)), now), 'Öffnet heute');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 21, 11), DateTime(2026, 12, 23)), now), 'Öffnet morgen');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 25, 11), DateTime(2026, 12, 23)), now), 'Öffnet in 5 Tagen');
    expect(marketStatusLabel(_market('a', DateTime(2026, 12, 20), DateTime(2026, 12, 23)), now), 'Ab 20. Dezember');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 13), DateTime(2026, 11, 20, 22)), now), 'Letzter Tag');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 13), DateTime(2026, 11, 30)), now), 'Läuft · noch 10 Tage');
    expect(marketStatusLabel(_market('a', DateTime(2026, 11, 1), DateTime(2026, 11, 2)), now), 'Vorbei');
  });

  test('highlight prefers open favourites, then open markets, then the next one', () {
    final now = DateTime(2026, 11, 26, 12);
    final open = _market('open', DateTime(2026, 11, 16), DateTime(2026, 12, 23));
    final openFav = _market('openFav', DateTime(2026, 11, 25), DateTime(2026, 12, 24));
    final next = _market('next', DateTime(2026, 11, 27), DateTime(2026, 12, 24));
    HomeFeed feed(Set<String> favs, List<Event> events) =>
        buildHomeFeed(events: events, posts: const [], favoriteIds: favs, now: now);

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
    final feed = buildHomeFeed(events: events, posts: posts, favoriteIds: const {}, now: now);
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
}
