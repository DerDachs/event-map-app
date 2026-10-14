import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/feed/models/feed_post.dart';
import 'package:market_mates/features/seasons/models/market_types.dart';
import 'package:market_mates/features/seasons/models/season.dart';

void main() {
  test('example posts parse and have unique ids', () {
    final list = jsonDecode(File('assets/feed/season_2026.json').readAsStringSync()) as List;
    final ids = <String>{};
    for (final raw in list.cast<Map<String, dynamic>>()) {
      final map = Map<String, dynamic>.from(raw);
      final id = map.remove('id') as String;
      expect(ids.add(id), isTrue, reason: 'duplicate id $id');
      final post = FeedPost.fromMap(id, map);
      expect(post.title, isNotEmpty);
      expect(post.publishAt.year, 2026, reason: id);
      if (post.expiresAt != null) expect(post.expiresAt!.isAfter(post.publishAt), isTrue, reason: id);
      if (post.linkUrl != null) expect(post.linkUrl, startsWith('https://'));
    }
    expect(ids, hasLength(list.length));
  });

  test('example seasons parse, use known market types and do not overlap', () {
    final list = jsonDecode(File('assets/seasons/seasons.json').readAsStringSync()) as List;
    final seasons = [
      for (final raw in list.cast<Map<String, dynamic>>())
        Season.fromMap(raw['id'] as String, Map<String, dynamic>.from(raw)..remove('id')),
    ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final postSeasons = (jsonDecode(File('assets/feed/season_2026.json').readAsStringSync()) as List)
        .map((p) => (p as Map)['seasonId'])
        .whereType<String>()
        .toSet();
    expect(seasons.map((s) => s.id), containsAll(postSeasons));
    for (var i = 0; i < seasons.length; i++) {
      final s = seasons[i];
      expect(s.endsAt.isAfter(s.startsAt), isTrue, reason: s.id);
      expect(s.marketTypes, isNotEmpty, reason: s.id);
      for (final t in s.marketTypes) {
        expect(marketTypes.map((m) => m.key), contains(t), reason: '${s.id}: $t');
      }
      if (s.countdownTo != null) {
        expect(s.countdownTo!.isAfter(s.startsAt) && s.countdownTo!.isBefore(s.endsAt), isTrue, reason: s.id);
      }
      if (i > 0) expect(seasons[i - 1].endsAt.isAfter(s.startsAt), isFalse, reason: '${s.id} overlaps');
    }
  });
}
