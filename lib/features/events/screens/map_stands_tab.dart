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
import '../../favorites/providers/favorite_provider.dart';
import '../../market_builder/models/stand_categories.dart';
import '../../market_builder/widgets/category_marker.dart';
import '../../stands/providers/stand_provider.dart';
import 'package:market_mates/l10n/l10n.dart';

/// How a stand category looks on the map and in the list.
class _CategoryStyle {
  final String key;
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryStyle(this.key, this.name, this.icon, this.color);
}

/// Visitor map: every stand as a coloured category icon, with search,
/// category filters and a pull-up list.
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

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  _CategoryStyle _styleFor(String? key, Map<String, Category> fromFirestore) {
    final builtIn = standCategories.where((c) => c.key == key);
    if (builtIn.isNotEmpty) {
      final c = builtIn.first;
      return _CategoryStyle(c.key, context.l10n.standCategoryName(c), c.icon, c.color);
    }
    final doc = fromFirestore[key];
    if (doc != null) {
      return _CategoryStyle(doc.id, doc.name, doc.icon ?? Icons.storefront, const Color(0xFF6D4C41));
    }
    final other = standCategories.last;
    return _CategoryStyle(key ?? other.key, context.l10n.standCategoryName(other), other.icon, other.color);
  }

  bool _matches(Stand stand, _CategoryStyle style) {
    if (_activeCategories.isNotEmpty && !_activeCategories.contains(style.key)) return false;
    if (_query.isEmpty) return true;
    return stand.name.toLowerCase().contains(_query) ||
        stand.description.toLowerCase().contains(_query) ||
        style.name.toLowerCase().contains(_query);
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
        onTap: () => _select(stand),
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
    if (_sheetController.isAttached && _sheetController.size > 0.3) {
      _sheetController.animateTo(0.12,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
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

    return standsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(
        icon: Icons.cloud_off,
        text: context.l10n.standsLoadFailed,
        onRetry: () => ref.invalidate(standsForEventProvider(widget.event.id)),
      ),
      data: (stands) {
        _buildMarkers(stands, categories);
        final styles = <String, _CategoryStyle>{};
        final counts = <String, int>{};
        for (final s in stands) {
          final style = _styleFor(s.standCategoryId, categories);
          styles[style.key] = style;
          counts[style.key] = (counts[style.key] ?? 0) + 1;
        }
        final selected = stands.where((s) => s.id == _selectedStandId).firstOrNull;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.event.latitude, widget.event.longitude),
                zoom: 17,
              ),
              onMapCreated: (c) {
                _map = c;
                Future.delayed(const Duration(milliseconds: 300), () => _fitToStands(stands));
              },
              onTap: (_) => setState(() => _selectedStandId = null),
              markers: _markers,
              groundOverlays: {if (_showPlan && _planOverlay != null) _planOverlay!},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              tiltGesturesEnabled: false,
              padding: const EdgeInsets.only(top: 112, bottom: 96),
            ),
            // Search and filters
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(28),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: context.l10n.standSearchHint,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                        ),
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
                              child: FilterChip(
                                avatar: Icon(style.icon, size: 18, color: style.color),
                                label: Text('${style.name} ${counts[style.key]}'),
                                selected: _activeCategories.contains(style.key),
                                showCheckmark: false,
                                backgroundColor: Colors.white,
                                onSelected: (on) => setState(() {
                                  on ? _activeCategories.add(style.key) : _activeCategories.remove(style.key);
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
            // Map buttons
            Positioned(
              right: 12,
              bottom: 112,
              child: Column(
                children: [
                  if (widget.event.plan != null)
                    _MapButton(
                      tooltip: _showPlan ? context.l10n.planHide : context.l10n.planShow,
                      icon: _planLoading
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_showPlan ? Icons.layers_clear : Icons.layers),
                      onPressed: _planLoading ? null : _togglePlan,
                    ),
                  const SizedBox(height: 8),
                  _MapButton(
                    tooltip: context.l10n.showWholeMarket,
                    icon: const Icon(Icons.zoom_out_map),
                    onPressed: () => _fitToStands(stands),
                  ),
                ],
              ),
            ),
            // Stand list
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.12,
              minChildSize: 0.12,
              maxChildSize: 0.85,
              snap: true,
              snapSizes: const [0.12, 0.45, 0.85],
              builder: (context, scrollController) => _StandSheet(
                scrollController: scrollController,
                stands: stands,
                styles: styles,
                styleFor: (s) => _styleFor(s.standCategoryId, categories),
                matches: _matches,
                selected: selected,
                onSelect: _select,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapButton extends StatelessWidget {
  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  const _MapButton({required this.tooltip, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: IconButton(tooltip: tooltip, icon: icon, onPressed: onPressed),
      );
}

class _StandSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final List<Stand> stands;
  final Map<String, _CategoryStyle> styles;
  final _CategoryStyle Function(Stand) styleFor;
  final bool Function(Stand, _CategoryStyle) matches;
  final Stand? selected;
  final ValueChanged<Stand> onSelect;

  const _StandSheet({
    required this.scrollController,
    required this.stands,
    required this.styles,
    required this.styleFor,
    required this.matches,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider)['stands'] ?? const <String>[];
    final visible = stands.where((s) => matches(s, styleFor(s))).toList()
      ..sort((a, b) {
        final fa = favorites.contains(a.id) ? 0 : 1, fb = favorites.contains(b.id) ? 0 : 1;
        return fa != fb ? fa - fb : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    Widget tile(Stand stand) {
      final style = styleFor(stand);
      final isFavorite = favorites.contains(stand.id);
      return ListTile(
        selected: stand.id == selected?.id,
        leading: CircleAvatar(
          backgroundColor: style.color,
          child: Icon(style.icon, color: Colors.white, size: 20),
        ),
        title: Text(stand.name),
        subtitle: Text(
          stand.description.isNotEmpty ? stand.description : style.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: isFavorite ? context.l10n.favoriteRemove : context.l10n.favoriteAdd,
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
          onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite('stands', stand.id),
        ),
        onTap: () => onSelect(stand),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          if (selected != null) ...[
            tile(selected!),
            const Divider(height: 1),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                visible.length == stands.length
                    ? context.l10n.standsPullUp(stands.length)
                    : context.l10n.standsFiltered(visible.length, stands.length),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.noStandMatches, textAlign: TextAlign.center),
            ),
          for (final stand in visible)
            if (stand.id != selected?.id) tile(stand),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  const _Message({required this.icon, required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text),
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      );
}
