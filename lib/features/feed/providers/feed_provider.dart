import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_post.dart';
import '../services/feed_service.dart';

final feedServiceProvider = Provider((ref) => FeedService());

final feedPostsProvider = StreamProvider<List<FeedPost>>(
  (ref) => ref.watch(feedServiceProvider).watchPublished(),
);
