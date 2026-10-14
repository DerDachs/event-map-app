import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/season.dart';
import '../services/season_service.dart';

final seasonServiceProvider = Provider((ref) => SeasonService());

final seasonsProvider = StreamProvider<List<Season>>(
  (ref) => ref.watch(seasonServiceProvider).watchAll(),
);
