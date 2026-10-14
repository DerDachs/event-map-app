import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/feed/models/feed_post.dart';

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
}
