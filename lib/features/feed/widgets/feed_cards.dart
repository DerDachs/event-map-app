import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/event.dart';
import '../../../theme/brand_tokens.dart';
import '../../../utils/formatters.dart';
import '../../events/screens/event_detail_screen.dart';
import '../../seasons/models/season.dart';
import '../logic/home_feed.dart';
import '../models/feed_post.dart';

void openEvent(BuildContext context, Event event) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );

String? coverImage(Event event) =>
    (event.images.where((i) => i.isStandard).firstOrNull ?? event.images.firstOrNull)?.url;

/// "heute", "gestern", "vor 3 Tagen", else the date.
String relativeDay(DateTime time, DateTime now) {
  final days = calendarDaysBetween(time, now);
  return switch (days) {
    <= 0 => 'heute',
    1 => 'gestern',
    < 7 => 'vor $days Tagen',
    _ => DateFormat('d. MMMM', 'de').format(time),
  };
}

/// Banner of the current season in its accent colour, with countdown.
class SeasonBannerCard extends StatelessWidget {
  final SeasonBanner banner;

  const SeasonBannerCard({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = banner.season.accent;
    final number = banner.bigNumber;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(color: accent.color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          if (number != null) ...[
            Text('$number',
                style: text.displayMedium?.copyWith(
                    color: BrandColors.white, fontWeight: FontWeight.w800, height: 1, letterSpacing: -1)),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.headline,
                    style: text.titleMedium?.copyWith(color: BrandColors.white, fontWeight: FontWeight.w700)),
                if (banner.subline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(banner.subline,
                      style: text.bodyMedium?.copyWith(color: BrandColors.white.withValues(alpha: 0.85))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(accent.icon, color: accent.sparkle, size: 36),
        ],
      ),
    );
  }
}

/// The market of the moment, big, with picture and status.
class HighlightCard extends StatelessWidget {
  final Event event;
  final DateTime now;
  final bool isFavorite;

  /// Season colours for the status pill; null outside any season.
  final SeasonAccent? accent;

  const HighlightCard({super.key, required this.event, required this.now, this.isFavorite = false, this.accent});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final image = coverImage(event);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        color: BrandColors.ink,
        child: InkWell(
          onTap: () => openEvent(context, event),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                else
                  const ColoredBox(
                    color: BrandColors.ink,
                    child: Align(
                      alignment: Alignment(0.8, -0.6),
                      child: Icon(Icons.storefront_outlined, color: Colors.white24, size: 72),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.35, 1],
                      colors: [Colors.transparent, Color(0xD91E1C1B)],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(spacing: 6, children: [
                        _Pill(
                          label: marketStatusLabel(event, now),
                          color: accent == null || accent == SeasonAccent.christmas ? BrandColors.gold : accent!.color,
                          textColor:
                              accent == null || accent == SeasonAccent.christmas ? BrandColors.ink : BrandColors.white,
                        ),
                        if (isFavorite)
                          const _Pill(label: 'Favorit', color: BrandColors.white, textColor: BrandColors.ink),
                      ]),
                      const SizedBox(height: 8),
                      Text(event.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineSmall?.copyWith(color: BrandColors.white, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          formatDateRange(event.startTime, event.endTime),
                          if (event.stands.isNotEmpty) '${event.stands.length} Stände',
                        ].join(' · '),
                        style: text.bodyMedium?.copyWith(color: BrandColors.darkText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Pill({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: textColor, fontWeight: FontWeight.w700)),
      );
}

({IconData icon, Color color}) _postStyle(FeedPostType type) => switch (type) {
      FeedPostType.news => (icon: Icons.campaign_outlined, color: BrandColors.red),
      FeedPostType.opening => (icon: Icons.celebration_outlined, color: BrandColors.redDark),
      FeedPostType.tip => (icon: Icons.lightbulb_outline, color: BrandColors.goldInk),
      FeedPostType.event => (icon: Icons.theater_comedy_outlined, color: BrandColors.green),
    };

/// An editorial post. Tap to read the whole text.
class FeedPostCard extends StatefulWidget {
  final FeedPost post;
  final Event? event;
  final DateTime now;

  const FeedPostCard({super.key, required this.post, required this.now, this.event});

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool _expanded = false;

  Future<void> _openLink(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Seite konnte nicht geöffnet werden.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final text = Theme.of(context).textTheme;
    final style = _postStyle(post.type);
    final image = post.imageUrl ?? (widget.event == null ? null : coverImage(widget.event!));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null)
              AspectRatio(
                aspectRatio: 2,
                child: Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Icon(style.icon, size: 18, color: style.color),
                  const SizedBox(width: 6),
                  Text(post.type.label.toUpperCase(),
                      style: text.labelSmall?.copyWith(
                          color: style.color, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                  if (post.pinned) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.push_pin, size: 14, color: style.color),
                  ],
                  const Spacer(),
                  Text(relativeDay(post.publishAt, widget.now), style: text.labelSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(post.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (post.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  post.body,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Wrap(
                spacing: 4,
                children: [
                  if (widget.event != null)
                    TextButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Zum Markt'),
                      onPressed: () => openEvent(context, widget.event!),
                    ),
                  if (post.linkUrl != null)
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(post.linkLabel ?? 'Mehr erfahren'),
                      onPressed: () => _openLink(post.linkUrl!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card for news generated from a market (opens soon, last days …).
class MarketNewsCard extends StatelessWidget {
  final MarketItem item;
  final DateTime now;

  const MarketNewsCard({super.key, required this.item, required this.now});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final image = coverImage(item.event);
    final (icon, color) = switch (item.news) {
      MarketNews.opensToday || MarketNews.opensSoon => (Icons.door_front_door_outlined, BrandColors.green),
      MarketNews.lastDays => (Icons.hourglass_bottom, BrandColors.red),
      MarketNews.isNew => (Icons.fiber_new_outlined, BrandColors.goldInk),
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => openEvent(context, item.event),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: image == null
                  ? ColoredBox(color: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 36))
                  : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(icon, color: color)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(marketStatusLabel(item.event, now),
                          style: text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(formatDateRange(item.event.startTime, item.event.endTime), style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
