import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/category.dart';
import '../../../data/models/event.dart';
import '../../../data/models/stand.dart';
import '../../../providers/category_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/brand_tokens.dart';
import '../../favorites/providers/favorite_provider.dart';
import '../../feed/logic/home_feed.dart';
import '../../market_builder/widgets/category_marker.dart';
import '../../market_editor/widgets/edit_market_button.dart';
import '../../stands/models/stand_style.dart';
import '../../stands/providers/stand_provider.dart';
import '../../stands/widgets/stand_details_sheet.dart';
import '../logic/market_hours.dart';
import 'market_section_screens.dart';
import 'package:market_mates/l10n/l10n.dart';

/// The market page: the map fills the screen. Search and category filters
/// float on top; a sheet at the bottom carries the market's name, today's
/// opening status, the ways to "Infos" and "Team", and the list of stands.
class MapStandsTab extends ConsumerStatefulWidget {
  final Event event;

  const MapStandsTab({super.key, required this.event});

  @override
  ConsumerState<MapStandsTab> createState() => _MapStandsTabState();
}

class _MapStandsTabState extends ConsumerState<MapStandsTab> {
  final _searchController = TextEditingController();
  final _sheetController = DraggableScrollableController();
  GoogleMapController? _map;

  String _query = '';
  final Set<String> _activeCategories = {};
  String? _selectedStandId;
  bool _showPlan = false;

  Set<Marker> _markers = {};
  String _markersKey = '';
  GroundOverlay? _planOverlay;
  bool _planLoading = false;

  /// Last camera position, so the map can be rebuilt without jumping.
  CameraPosition? _camera;

  /// Collapsed height of the bottom sheet, as a share of the screen.
  double _minSheet = 0.22;

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  StandStyle _styleFor(String? key, Map<String, Category> categories) => standStyleFor(context, key, categories);

  bool _matches(Stand stand, StandStyle style) {
    if (_activeCategories.isNotEmpty && !_activeCategories.contains(style.key)) return false;
    if (_query.isEmpty) return true;
    return stand.name.toLowerCase().contains(_query) ||
        stand.description.toLowerCase().contains(_query) ||
        style.name.toLowerCase().contains(_query) ||
        (stand.menu ?? const <String>[]).any((m) => m.toLowerCase().contains(_query));
  }

  Future<void> _buildMarkers(List<Stand> stands, Map<String, Category> categories) async {
    final key = [
      stands.length,
      categories.length,
      _query,
      (_activeCategories.toList()..sort()).join(','),
      _selectedStandId,
    ].join('|');
    if (key == _markersKey) return;
    _markersKey = key;

    final markers = <Marker>{};
    for (final stand in stands) {
      if (stand.eventLatitude == null || stand.eventLongitude == null) continue;
      final style = _styleFor(stand.standCategoryId, categories);
      if (!_matches(stand, style)) continue;
      final selected = stand.id == _selectedStandId;
      markers.add(Marker(
        markerId: MarkerId(stand.id),
        position: LatLng(stand.eventLatitude!, stand.eventLongitude!),
        icon: await iconMarker(style.key, style.icon, style.color, selected: selected),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: selected ? 2 : 1,
        onTap: () => _open(stand, style),
      ));
    }
    if (mounted && key == _markersKey) setState(() => _markers = markers);
  }

  void _select(Stand stand) {
    setState(() => _selectedStandId = stand.id);
    if (stand.eventLatitude != null) {
      _map?.animateCamera(
        CameraUpdate.newLatLng(LatLng(stand.eventLatitude!, stand.eventLongitude!)),
      );
    }
  }

  /// Highlights [stand] on the map and shows its details.
  void _open(Stand stand, StandStyle style) {
    _select(stand);
    if (_sheetController.isAttached && _sheetController.size > _minSheet + 0.05) {
      _sheetController.animateTo(_minSheet, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    showStandDetails(context, stand: stand, style: style, marketName: widget.event.name);
  }

  void _fitToStands(List<Stand> stands) {
    final points = stands
        .where((s) => s.eventLatitude != null && s.eventLongitude != null)
        .map((s) => LatLng(s.eventLatitude!, s.eventLongitude!))
        .toList();
    if (points.length < 2 || _map == null) return;
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    _map!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
      48,
    ));
  }

  Future<void> _togglePlan() async {
    final plan = widget.event.plan;
    if (plan == null) return;
    if (_planOverlay != null || _showPlan) {
      setState(() => _showPlan = !_showPlan);
      return;
    }
    setState(() => _planLoading = true);
    try {
      final Uint8List? bytes =
          await FirebaseStorage.instance.refFromURL(plan.imageUrl).getData(10 * 1024 * 1024);
      if (bytes == null) throw Exception('leer');
      final codec = await ui.instantiateImageCodec(bytes);
      final width = (await codec.getNextFrame()).image.width;
      final metersPerPixelAtZoom0 = 156543.03392 * math.cos(plan.latitude * math.pi / 180);
      setState(() {
        _planOverlay = GroundOverlay.fromPosition(
          groundOverlayId: const GroundOverlayId('plan'),
          image: BytesMapBitmap(bytes, bitmapScaling: MapBitmapScaling.none),
          position: LatLng(plan.latitude, plan.longitude),
          width: plan.widthMeters,
          height: plan.heightMeters,
          bearing: plan.bearing,
          transparency: 0.35,
          zoomLevel: math.log(metersPerPixelAtZoom0 * width / plan.widthMeters) / math.ln2,
          clickable: false,
        );
        _showPlan = true;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.planLoadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _planLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final standsAsync = ref.watch(standsForEventProvider(widget.event.id));
    final categoriesAsync = ref.watch(categoriesForEventProvider(widget.event.id));
    final categories = {
      for (final c in categoriesAsync.valueOrNull ?? const <Category>[]) c.id: c,
    };
    final screenHeight = MediaQuery.sizeOf(context).height;
    // The collapsed sheet shows the market header (about 190 px).
    final minSheet = (190 / screenHeight).clamp(0.18, 0.4).toDouble();
    _minSheet = minSheet;
    final stands = standsAsync.valueOrNull ?? const <Stand>[];

    if (standsAsync.isLoading == false) _buildMarkers(stands, categories);
    final styles = <String, StandStyle>{};
    final counts = <String, int>{};
    for (final s in stands) {
      final style = _styleFor(s.standCategoryId, categories);
      styles[style.key] = style;
      counts[style.key] = (counts[style.key] ?? 0) + 1;
    }

    return Stack(
      children: [
        GoogleMap(
          // On iOS a ground overlay added to a running map doesn't show up, so
          // the map is rebuilt (same camera) when the plan is switched on or off.
          key: ValueKey('market-map-${_showPlan && _planOverlay != null}'),
          initialCameraPosition: _camera ??
              CameraPosition(
                target: LatLng(widget.event.latitude, widget.event.longitude),
                zoom: 17,
              ),
          onCameraMove: (position) => _camera = position,
          onMapCreated: (c) {
            _map = c;
            if (_camera == null) {
              Future.delayed(const Duration(milliseconds: 300), () => _fitToStands(stands));
            }
          },
          onTap: (_) => setState(() => _selectedStandId = null),
          markers: _markers,
          groundOverlays: {if (_showPlan && _planOverlay != null) _planOverlay!},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          tiltGesturesEnabled: false,
          padding: EdgeInsets.only(top: 140, bottom: screenHeight * minSheet),
        ),
        // Back, search, filters
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: [
                      _RoundButton(
                        tooltip: context.l10n.marketBack,
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SearchField(
                          controller: _searchController,
                          hint: context.l10n.standSearchHint,
                          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          showClear: _query.isNotEmpty,
                        ),
                      ),
                      EditMarketButton(eventId: widget.event.id),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      for (final style in styles.values)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _CategoryChip(
                            style: style,
                            count: counts[style.key] ?? 0,
                            selected: _activeCategories.contains(style.key),
                            onTap: () => setState(() {
                              _activeCategories.contains(style.key)
                                  ? _activeCategories.remove(style.key)
                                  : _activeCategories.add(style.key);
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Map buttons, just above the collapsed sheet
        Positioned(
          right: 12,
          bottom: screenHeight * minSheet + 12,
          child: Column(
            children: [
              if (widget.event.plan != null) ...[
                _RoundButton(
                  tooltip: _showPlan ? context.l10n.planHide : context.l10n.planShow,
                  icon: _planLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_showPlan ? Icons.layers_clear : Icons.layers),
                  onPressed: _planLoading ? null : _togglePlan,
                ),
                const SizedBox(height: 8),
              ],
              _RoundButton(
                tooltip: context.l10n.showWholeMarket,
                icon: const Icon(Icons.zoom_out_map),
                onPressed: () => _fitToStands(stands),
              ),
            ],
          ),
        ),
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: minSheet,
          minChildSize: minSheet,
          maxChildSize: 0.88,
          snap: true,
          snapSizes: [if (minSheet < 0.5) 0.5],
          builder: (context, scrollController) => _MarketSheet(
            event: widget.event,
            scrollController: scrollController,
            standsAsync: standsAsync,
            styleFor: (s) => _styleFor(s.standCategoryId, categories),
            matches: _matches,
            selectedId: _selectedStandId,
            onOpen: _open,
            onRetry: () => ref.invalidate(standsForEventProvider(widget.event.id)),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: BrandColors.white,
        shape: const StadiumBorder(side: BorderSide(color: BrandColors.line)),
        elevation: 2,
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: showClear ? IconButton(icon: const Icon(Icons.close), onPressed: onClear) : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: onChanged,
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  final StandStyle style;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.style, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? BrandColors.ink : BrandColors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? BrandColors.ink : BrandColors.line)),
        elevation: 1,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: style.color,
                  child: Icon(style.icon, size: 14, color: BrandColors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '${style.name} · $count',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected ? BrandColors.white : BrandColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  const _RoundButton({required this.tooltip, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: BrandColors.white,
        shape: const CircleBorder(side: BorderSide(color: BrandColors.line)),
        elevation: 2,
        child: IconButton(tooltip: tooltip, icon: icon, color: BrandColors.ink, onPressed: onPressed),
      );
}

/// Today's status of the market as a small pill: green dot while open.
class MarketStatusPill extends StatelessWidget {
  final Event event;
  final DateTime now;

  const MarketStatusPill({super.key, required this.event, required this.now});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hours = todayHours(event, now);
    final (label, open) = switch (hours) {
      OpenNow(:final close) => (l.marketOpenUntil(close), true),
      OpensLater(open: final at) => (l.marketOpensAt(at), false),
      ClosedToday() => (l.marketClosedToday, false),
      NotRunning() || HoursUnknown() => (marketStatusLabel(event, now, l), false),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: open ? BrandColors.green.withValues(alpha: 0.1) : BrandColors.sand,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: open ? BrandColors.green : BrandColors.inkSoft, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: open ? BrandColors.green : BrandColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketSheet extends ConsumerWidget {
  final Event event;
  final ScrollController scrollController;
  final AsyncValue<List<Stand>> standsAsync;
  final StandStyle Function(Stand) styleFor;
  final bool Function(Stand, StandStyle) matches;
  final String? selectedId;
  final void Function(Stand, StandStyle) onOpen;
  final VoidCallback onRetry;

  const _MarketSheet({
    required this.event,
    required this.scrollController,
    required this.standsAsync,
    required this.styleFor,
    required this.matches,
    required this.selectedId,
    required this.onOpen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider)['stands'] ?? const <String>[];
    final stands = standsAsync.valueOrNull ?? const <Stand>[];
    final visible = stands.where((s) => matches(s, styleFor(s))).toList()
      ..sort((a, b) {
        final fa = favorites.contains(a.id) ? 0 : 1, fb = favorites.contains(b.id) ? 0 : 1;
        return fa != fb ? fa - fb : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    Widget tile(Stand stand) {
      final style = styleFor(stand);
      final isFavorite = favorites.contains(stand.id);
      final selected = stand.id == selectedId;
      return ListTile(
        selected: selected,
        selectedTileColor: BrandColors.goldSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: CircleAvatar(
          backgroundColor: style.color,
          child: Icon(style.icon, color: BrandColors.white, size: 20),
        ),
        title: Text(stand.name, style: const TextStyle(fontWeight: FontWeight.w600, color: BrandColors.ink)),
        subtitle: Text(
          (stand.promotions ?? '').isNotEmpty
              ? stand.promotions!
              : stand.description.isNotEmpty
                  ? stand.description
                  : style.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: isFavorite ? context.l10n.favoriteRemove : context.l10n.favoriteAdd,
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: BrandColors.red),
          onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite('stands', stand.id),
        ),
        onTap: () => onOpen(stand, style),
      );
    }

    return Material(
      color: BrandColors.white,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: BrandColors.line, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: brandDisplay(32)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Align(alignment: Alignment.centerLeft, child: MarketStatusPill(event: event, now: DateTime.now())),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    icon: const Icon(Icons.info_outline, size: 20),
                    label: Text(context.l10n.marketInfoAction),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MarketInfoScreen(event: event)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    icon: const Icon(Icons.groups_outlined, size: 20),
                    label: Text(context.l10n.marketTeamAction),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MarketTeamScreen(event: event)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (standsAsync.isLoading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (standsAsync.hasError)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(context.l10n.standsLoadFailed, textAlign: TextAlign.center),
                  TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                visible.length == stands.length
                    ? context.l10n.standsPullUp(stands.length)
                    : context.l10n.standsFiltered(visible.length, stands.length),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: BrandColors.inkSoft),
              ),
            ),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.noStandMatches, textAlign: TextAlign.center),
              ),
            for (final stand in visible) tile(stand),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
