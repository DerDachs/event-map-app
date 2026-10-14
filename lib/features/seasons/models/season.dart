import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../theme/brand_tokens.dart';

/// Look of a season on the start page. Colours come from the brand tokens.
enum SeasonAccent {
  christmas('christmas', 'Weihnachten', BrandColors.seasonChristmas, Icons.star_rounded),
  spring('spring', 'Frühling', BrandColors.seasonSpring, Icons.local_florist),
  summer('summer', 'Sommer', BrandColors.seasonSummer, Icons.wb_sunny_rounded),
  autumn('autumn', 'Herbst', BrandColors.seasonAutumn, Icons.eco);

  final String key;
  final String label;

  /// Strong colour; white text on it has at least 5:1 contrast.
  final Color color;
  final IconData icon;

  const SeasonAccent(this.key, this.label, this.color, this.icon);

  /// Small highlight next to the main colour (the star at Christmas).
  Color get sparkle => this == SeasonAccent.christmas ? BrandColors.gold : BrandColors.white;

  static SeasonAccent fromKey(String? key) =>
      values.firstWhere((a) => a.key == key, orElse: () => SeasonAccent.christmas);
}

/// A date worth counting down to within a season, e.g. "1. Advent".
class SeasonMilestone {
  final String label;
  final DateTime date;

  const SeasonMilestone(this.label, this.date);

  Map<String, dynamic> toMap() => {'label': label, 'date': Timestamp.fromDate(date)};
}

/// A time of year with its own markets and look, e.g. "Weihnachtsmärkte
/// 2026" (`seasons` collection, maintained by admins).
class Season {
  final String id;
  final String name;

  /// Short line under the banner when there is nothing to count down to.
  final String tagline;

  /// The season shows on the start page from [startsAt] until [endsAt].
  final DateTime startsAt;
  final DateTime endsAt;

  /// Market types (event `category`) that belong to the season.
  final List<String> marketTypes;
  final SeasonAccent accent;

  /// Main countdown, e.g. Heiligabend.
  final DateTime? countdownTo;
  final String countdownLabel;

  /// Further dates, the next one is shown under the countdown.
  final List<SeasonMilestone> milestones;

  /// Switched-off seasons never show.
  final bool active;

  const Season({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    this.tagline = '',
    this.marketTypes = const [],
    this.accent = SeasonAccent.christmas,
    this.countdownTo,
    this.countdownLabel = '',
    this.milestones = const [],
    this.active = true,
  });

  bool isRunningAt(DateTime now) => active && !startsAt.isAfter(now) && endsAt.isAfter(now);

  bool includesMarketType(String? type) => marketTypes.contains(type);

  factory Season.fromMap(String id, Map<String, dynamic> data) {
    DateTime? time(Object? v) => v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v) : null);
    return Season(
      id: id,
      name: data['name'] as String? ?? '',
      tagline: data['tagline'] as String? ?? '',
      startsAt: time(data['startsAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: time(data['endsAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      marketTypes: (data['marketTypes'] as List? ?? const []).whereType<String>().toList(),
      accent: SeasonAccent.fromKey(data['accent'] as String?),
      countdownTo: time(data['countdownTo']),
      countdownLabel: data['countdownLabel'] as String? ?? '',
      milestones: [
        for (final m in (data['milestones'] as List? ?? const []).whereType<Map>())
          if (time(m['date']) != null && m['label'] is String) SeasonMilestone(m['label'] as String, time(m['date'])!),
      ]..sort((a, b) => a.date.compareTo(b.date)),
      active: data['active'] != false,
    );
  }

  factory Season.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Season.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'tagline': tagline,
        'startsAt': Timestamp.fromDate(startsAt),
        'endsAt': Timestamp.fromDate(endsAt),
        'marketTypes': marketTypes,
        'accent': accent.key,
        'countdownTo': countdownTo == null ? null : Timestamp.fromDate(countdownTo!),
        'countdownLabel': countdownLabel,
        'milestones': milestones.map((m) => m.toMap()).toList(),
        'active': active,
      };
}

/// The season to show at [now]: of all running seasons the one that started
/// last, so a short special season can sit inside a longer one.
Season? currentSeason(Iterable<Season> seasons, DateTime now) {
  Season? best;
  for (final s in seasons) {
    if (!s.isRunningAt(now)) continue;
    if (best == null || s.startsAt.isAfter(best.startsAt)) best = s;
  }
  return best;
}
