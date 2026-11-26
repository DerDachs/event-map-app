import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/stand.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/brand_tokens.dart';
import '../../../widgets/favorite_heart.dart';
import '../../favorites/providers/favorite_provider.dart';
import '../models/stand_style.dart';

/// Opens the details of [stand] as a bottom sheet over the market map.
Future<void> showStandDetails(
  BuildContext context, {
  required Stand stand,
  required StandStyle style,
  required String marketName,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StandDetailsSheet(stand: stand, style: style, marketName: marketName),
    );

/// Name, category, offer and special of a stand, with favourite and a
/// meeting point to send to friends.
class StandDetailsSheet extends StatelessWidget {
  final Stand stand;
  final StandStyle style;
  final String marketName;

  const StandDetailsSheet({super.key, required this.stand, required this.style, required this.marketName});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, controller) => StandDetailsContent(
        stand: stand,
        style: style,
        marketName: marketName,
        controller: controller,
      ),
    );
  }
}

/// The scrollable content of [StandDetailsSheet]; also used for store screenshots.
class StandDetailsContent extends ConsumerWidget {
  final Stand stand;
  final StandStyle style;
  final String marketName;
  final ScrollController? controller;

  const StandDetailsContent({
    super.key,
    required this.stand,
    required this.style,
    required this.marketName,
    this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final isFavorite = ref.watch(favoritesProvider)['stands']?.contains(stand.id) ?? false;
    final menu = (stand.menu ?? const <String>[]).where((m) => m.trim().isNotEmpty).toList();
    final promotion = stand.promotions?.trim() ?? '';
    final image = stand.images?.firstOrNull?.url;
    final hasDetails = stand.description.isNotEmpty || menu.isNotEmpty || promotion.isNotEmpty;

    return ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: BrandColors.white, width: 3),
                ),
                child: Icon(style.icon, color: BrandColors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(style.name.toUpperCase(),
                        style: text.labelMedium?.copyWith(color: BrandColors.inkSoft, letterSpacing: 1.2)),
                    const SizedBox(height: 2),
                    Text(stand.name, style: brandDisplay(32)),
                  ],
                ),
              ),
              FavoriteHeart(
                isFavorite: isFavorite,
                tooltip: isFavorite ? context.l10n.favoriteRemove : context.l10n.favoriteAdd,
                onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite('stands', stand.id),
              ),
            ],
          ),
          if (image != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ),
          ],
          if (promotion.isNotEmpty) ...[
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(color: BrandColors.goldSoft, borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_offer_outlined, color: BrandColors.goldInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.standPromotion,
                              style: text.titleSmall?.copyWith(color: BrandColors.goldInk, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(promotion, style: text.bodyMedium?.copyWith(color: BrandColors.goldInk)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (stand.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(stand.description, style: text.bodyLarge),
          ],
          if (menu.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(context.l10n.standOffer, style: brandDisplay(24)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in menu)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrandColors.sand,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(item, style: text.bodyMedium),
                    ),
                  ),
              ],
            ),
          ],
          if (!hasDetails) ...[
            const SizedBox(height: 16),
            Text(context.l10n.standNoDetails, style: text.bodyMedium?.copyWith(color: BrandColors.inkSoft)),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.place_outlined),
            label: Text(context.l10n.standCopyMeet),
            onPressed: () {
              final l10n = context.l10n;
              final messenger = ScaffoldMessenger.of(context);
              Clipboard.setData(ClipboardData(text: l10n.standMeetText(stand.name, marketName)));
              Navigator.pop(context);
              messenger.showSnackBar(SnackBar(content: Text(l10n.standMeetCopied)));
            },
          ),
        ],
    );
  }
}
