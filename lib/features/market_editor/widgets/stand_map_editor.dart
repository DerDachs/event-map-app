import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../market_builder/models/stand_categories.dart';
import '../../market_builder/services/georeference.dart';
import '../../market_builder/widgets/category_marker.dart';
import '../../market_builder/widgets/stand_editor.dart';
import '../models/market_edit_draft.dart';

/// Satellite map with every stand as a marker. Tap a marker to edit it, hold
/// and drag it to move it, long-press an empty spot to add a stand. Markets
/// from a site plan show the plan underneath.
class StandMapEditor extends StatefulWidget {
  final MarketEditDraft draft;
  final Uint8List? planImage;
  final VoidCallback onChanged;

  const StandMapEditor({super.key, required this.draft, required this.onChanged, this.planImage});

  @override
  State<StandMapEditor> createState() => _StandMapEditorState();
}

class _StandMapEditorState extends State<StandMapEditor> {
  Map<String, BitmapDescriptor> _icons = {};
  GoogleMapController? _map;
  double _planOpacity = 0.5;
  double? _planWidthPx;

  MarketEditDraft get _draft => widget.draft;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _measurePlan();
  }

  @override
  void didUpdateWidget(StandMapEditor old) {
    super.didUpdateWidget(old);
    if (old.planImage != widget.planImage) _measurePlan();
  }

  Future<void> _loadIcons() async {
    final icons = <String, BitmapDescriptor>{};
    for (final c in standCategories) {
      icons[c.key] = await categoryMarker(c);
    }
    if (mounted) setState(() => _icons = icons);
  }

  Future<void> _measurePlan() async {
    final bytes = widget.planImage;
    if (bytes == null) return;
    final image = await decodeImageFromList(bytes);
    if (mounted) setState(() => _planWidthPx = image.width.toDouble());
  }

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  Future<void> _edit(EditableStand stand) async {
    final result = await showModalBottomSheet<StandEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StandEditorSheet(
        label: stand.label,
        category: stand.category,
        description: stand.description,
      ),
    );
    if (result == null) return;
    if (result.delete) {
      _draft.removeStand(stand);
    } else {
      stand
        ..label = result.label
        ..category = result.category
        ..description = result.description ?? stand.description;
    }
    _changed();
  }

  Future<void> _add(LatLng position) async {
    final result = await showModalBottomSheet<StandEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const StandEditorSheet(label: '', category: 'other', description: '', isNew: true),
    );
    if (result == null || result.delete) return;
    _draft.stands.add(EditableStand(
      id: null,
      key: _draft.newKey(),
      label: result.label,
      description: (result.description ?? '').isEmpty
          ? standCategoryFor(result.category).name
          : result.description!,
      category: result.category,
      position: GeoPoint(position.latitude, position.longitude),
    ));
    _changed();
  }

  Future<void> _recategorize(StandCategory from) async {
    final count = _draft.stands.where((s) => s.category == from.key).length;
    final to = await showModalBottomSheet<StandCategory>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Alle $count Stände aus „${from.name}“ ändern zu:',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final c in standCategories)
              if (c.key != from.key)
                ListTile(
                  leading: Icon(c.icon, color: c.color),
                  title: Text(c.name),
                  onTap: () => Navigator.pop(context, c),
                ),
          ],
        ),
      ),
    );
    if (to == null) return;
    for (final s in _draft.stands.where((s) => s.category == from.key)) {
      s
        ..category = to.key
        ..description = updateCategoryInDescription(s.description, from, to);
    }
    _changed();
  }

  Future<void> _showList() async {
    final stand = await showModalBottomSheet<EditableStand>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StandListSheet(stands: _draft.stands),
    );
    if (stand == null) return;
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(_latLng(stand.position), 20));
    if (mounted) await _edit(stand);
  }

  LatLngBounds? _bounds() {
    if (_draft.stands.isEmpty) return null;
    var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
    for (final s in _draft.stands) {
      south = math.min(south, s.position.latitude);
      north = math.max(north, s.position.latitude);
      west = math.min(west, s.position.longitude);
      east = math.max(east, s.position.longitude);
    }
    return LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east));
  }

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in _draft.stands) {
      counts[s.category] = (counts[s.category] ?? 0) + 1;
    }
    final overlay = _draft.planOverlay;
    final plan = widget.planImage;
    final center = overlay?.center ??
        (_draft.stands.isNotEmpty ? _draft.stands.first.position : const GeoPoint(51.1657, 10.4515));

    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _latLng(center),
              zoom: _draft.stands.isEmpty && overlay == null ? 5 : 18,
            ),
            mapType: MapType.hybrid,
            onMapCreated: (c) {
              _map = c;
              final bounds = _bounds();
              if (bounds != null && _draft.stands.length > 1) {
                Future.delayed(const Duration(milliseconds: 300),
                    () => c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48)));
              }
            },
            onLongPress: _add,
            markers: {
              for (final stand in _draft.stands)
                Marker(
                  markerId: MarkerId(stand.key),
                  position: _latLng(stand.position),
                  icon: _icons[stand.category] ?? BitmapDescriptor.defaultMarker,
                  anchor: const Offset(0.5, 0.5),
                  draggable: true,
                  consumeTapEvents: true,
                  onTap: () => _edit(stand),
                  onDragEnd: (p) {
                    stand.position = GeoPoint(p.latitude, p.longitude);
                    _changed();
                  },
                ),
            },
            groundOverlays: {
              if (overlay != null && plan != null && _planWidthPx != null)
                GroundOverlay.fromPosition(
                  groundOverlayId: const GroundOverlayId('plan'),
                  image: BytesMapBitmap(plan, bitmapScaling: MapBitmapScaling.none),
                  position: _latLng(overlay.center),
                  width: overlay.widthMeters,
                  height: overlay.heightMeters,
                  bearing: overlay.bearing,
                  transparency: 1 - _planOpacity,
                  // iOS sizes position-based overlays through the zoom level.
                  zoomLevel: _overlayZoom(overlay, _planWidthPx!),
                  clickable: false,
                ),
            },
          ),
        ),
        if (overlay != null && plan != null)
          Row(
            children: [
              const SizedBox(width: 16),
              const Text('Plan'),
              Expanded(
                child: Slider(value: _planOpacity, onChanged: (v) => setState(() => _planOpacity = v)),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Text(
            'Antippen = bearbeiten · gedrückt halten & ziehen = verschieben · '
            'lange auf freie Stelle drücken = Stand hinzufügen',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  avatar: const Icon(Icons.list, size: 18),
                  label: Text('Liste (${_draft.stands.length})'),
                  onPressed: _draft.stands.isEmpty ? null : _showList,
                ),
              ),
              for (final c in standCategories)
                if (counts[c.key] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      avatar: Icon(c.icon, color: c.color, size: 18),
                      label: Text('${c.name} ${counts[c.key]}'),
                      tooltip: 'Alle ändern',
                      onPressed: () => _recategorize(c),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static double _overlayZoom(PlanOverlay overlay, double imageWidthPx) {
    final metersPerPixelAtZoom0 = 156543.03392 * math.cos(overlay.center.latitude * math.pi / 180);
    return math.log(metersPerPixelAtZoom0 * imageWidthPx / overlay.widthMeters) / math.ln2;
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);
}

class _StandListSheet extends StatefulWidget {
  final List<EditableStand> stands;

  const _StandListSheet({required this.stands});

  @override
  State<_StandListSheet> createState() => _StandListSheetState();
}

class _StandListSheetState extends State<_StandListSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final stands = widget.stands
        .where((s) => q.isEmpty || s.label.toLowerCase().contains(q) || s.description.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Stand suchen'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: stands.length,
              itemBuilder: (context, i) {
                final s = stands[i];
                final c = s.standCategory;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: c.color, child: Icon(c.icon, color: Colors.white, size: 20)),
                  title: Text(s.label),
                  subtitle: s.description.isEmpty ? null : Text(s.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: s.isNew ? const Chip(label: Text('neu'), visualDensity: VisualDensity.compact) : null,
                  onTap: () => Navigator.pop(context, s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
