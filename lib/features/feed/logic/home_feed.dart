import 'package:intl/intl.dart';

import '../../../data/models/event.dart';
import '../models/feed_post.dart';

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return (b.difference(a).inHours / 24).round();
}

/// First Sunday of Advent: four Sundays before Christmas Day.
DateTime firstAdventSunday(int year) {
  final christmas = DateTime(year, 12, 25);
  // Last Sunday before 25 December (weekday 7 = Sunday).
  final fourth = christmas.subtract(Duration(days: christmas.weekday == DateTime.sunday ? 7 : christmas.weekday));
  return DateTime(fourth.year, fourth.month, fourth.day - 21);
}

/// Countdown for the header, shown from October until Christmas Eve.
class SeasonCountdown {
  final int daysToChristmasEve;
  final DateTime firstAdvent;
  final int daysToFirstAdvent;

  const SeasonCountdown({
    required this.daysToChristmasEve,
    required this.firstAdvent,
    required this.daysToFirstAdvent,
  });

  static SeasonCountdown? at(DateTime now) {
    if (now.month < 10) return null;
    final days = calendarDaysBetween(now, DateTime(now.year, 12, 24));
    if (days < 0) return null;
    final advent = firstAdventSunday(now.year);
    return SeasonCountdown(
      daysToChristmasEve: days,
      firstAdvent: advent,
      daysToFirstAdvent: calendarDaysBetween(now, advent),
    );
  }

  String get headline => switch (daysToChristmasEve) {
        0 => 'Heute ist Heiligabend',
        1 => 'Morgen ist Heiligabend',
        _ => 'Noch $daysToChristmasEve Tage bis Heiligabend',
      };

  String get subline {
    if (daysToFirstAdvent > 1) return '1. Advent am ${DateFormat('d. MMMM', 'de').format(firstAdvent)}';
    if (daysToFirstAdvent == 1) return 'Morgen ist der 1. Advent';
    if (daysToFirstAdvent == 0) return 'Heute ist der 1. Advent';
    return 'Die Märkte haben geöffnet';
  }
}

/// Short status of a market relative to [now], e.g. "Öffnet in 3 Tagen".
String marketStatusLabel(Event event, DateTime now) {
  if (event.endTime.isBefore(now)) return 'Vorbei';
  if (event.startTime.isAfter(now)) {
    final days = calendarDaysBetween(now, event.startTime);
    return switch (days) {
      0 => 'Öffnet heute',
      1 => 'Öffnet morgen',
      < 15 => 'Öffnet in $days Tagen',
      _ => 'Ab ${DateFormat('d. MMMM', 'de').format(event.startTime)}',
    };
  }
  final left = calendarDaysBetween(now, event.endTime);
  return switch (left) {
    0 => 'Letzter Tag',
    1 => 'Läuft · noch bis morgen',
    _ => 'Läuft · noch $left Tage',
  };
}

enum MarketNews { opensToday, opensSoon, lastDays, isNew }

/// One card in the start page feed.
sealed class FeedItem {
  /// When the item became news; newest first.
  final DateTime time;
  const FeedItem(this.time);
}

class PostItem extends FeedItem {
  final FeedPost post;
  PostItem(this.post) : super(post.publishAt);
}

/// Generated from the markets themselves, so the feed has news even before
/// anyone writes a post.
class MarketItem extends FeedItem {
  final Event event;
  final MarketNews news;
  const MarketItem(this.event, this.news, DateTime time) : super(time);

  String get title => switch (news) {
        MarketNews.opensToday => '${event.name} öffnet heute',
        MarketNews.opensSoon => '${event.name} öffnet bald',
        MarketNews.lastDays => 'Letzte Chance: ${event.name}',
        MarketNews.isNew => 'Neu in Market Mate: ${event.name}',
      };
}

class HomeFeed {
  final SeasonCountdown? countdown;

  /// The market to show big at the top: open favourites first, then any open
  /// market, then the next one to open.
  final Event? highlight;
  final List<FeedItem> items;
  final List<Event> favorites;
  final List<Event> running;
  final List<Event> upcoming;
  final List<Event> past;

  const HomeFeed({
    required this.countdown,
    required this.highlight,
    required this.items,
    required this.favorites,
    required this.running,
    required this.upcoming,
    required this.past,
  });
}

HomeFeed buildHomeFeed({
  required List<Event> events,
  required List<FeedPost> posts,
  required Set<String> favoriteIds,
  required DateTime now,
  int maxItems = 30,
}) {
  final sorted = [...events]..sort((a, b) => a.startTime.compareTo(b.startTime));
  final running = sorted.where((e) => !e.startTime.isAfter(now) && e.endTime.isAfter(now)).toList();
  final upcoming = sorted.where((e) => e.startTime.isAfter(now)).toList();
  final past = sorted.where((e) => !e.endTime.isAfter(now)).toList().reversed.toList();
  final favorites = sorted.where((e) => favoriteIds.contains(e.id) && e.endTime.isAfter(now)).toList();

  Event? first(Iterable<Event> list) => list.isEmpty ? null : list.first;
  final highlight = first(running.where((e) => favoriteIds.contains(e.id))) ??
      first(running) ??
      first(upcoming.where((e) => favoriteIds.contains(e.id))) ??
      first(upcoming);

  final marketItems = <MarketItem>[];
  for (final event in sorted) {
    if (event.id == highlight?.id || !event.endTime.isAfter(now)) continue;
    final daysToStart = calendarDaysBetween(now, event.startTime);
    final daysToEnd = calendarDaysBetween(now, event.endTime);
    final isRunning = !event.startTime.isAfter(now);
    MarketItem? item;
    if (!isRunning && daysToStart == 0) {
      item = MarketItem(event, MarketNews.opensToday, DateTime(now.year, now.month, now.day));
    } else if (!isRunning && daysToStart <= 7) {
      item = MarketItem(event, MarketNews.opensSoon, event.startTime.subtract(const Duration(days: 7)));
    } else if (isRunning && daysToEnd <= 3) {
      item = MarketItem(event, MarketNews.lastDays, event.endTime.subtract(const Duration(days: 3)));
    } else if (event.createdAt != null && now.difference(event.createdAt!).inDays < 14) {
      item = MarketItem(event, MarketNews.isNew, event.createdAt!);
    }
    if (item != null) marketItems.add(item);
  }

  final visiblePosts = posts.where((p) => p.isVisibleAt(now)).toList();
  final pinned = visiblePosts.where((p) => p.pinned).map(PostItem.new).toList()
    ..sort((a, b) => b.time.compareTo(a.time));
  final rest = <FeedItem>[
    ...visiblePosts.where((p) => !p.pinned).map(PostItem.new),
    ...marketItems,
  ]..sort((a, b) => b.time.compareTo(a.time));

  return HomeFeed(
    countdown: SeasonCountdown.at(now),
    highlight: highlight,
    items: [...pinned, ...rest].take(maxItems).toList(),
    favorites: favorites,
    running: running,
    upcoming: upcoming,
    past: past,
  );
}
