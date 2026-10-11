import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../events/services/event_service.dart';
import '../../../utils/formatters.dart';
import '../models/event_import.dart';
import '../models/plan_draft.dart';
import '../models/stand_categories.dart';
import '../services/georeference.dart';
import '../services/market_builder_service.dart';
import '../widgets/category_marker.dart';
import '../widgets/plan_canvas.dart';

final marketBuilderServiceProvider = Provider((ref) => MarketBuilderService());

enum _Step { upload, analyzing, review, place, saving }

/// Admin wizard: upload a market plan, let the AI find the stands, check
/// them, align the plan with the real map and save it as an event.
class MarketBuilderScreen extends ConsumerStatefulWidget {
  const MarketBuilderScreen({super.key});

  @override
  ConsumerState<MarketBuilderScreen> createState() => _MarketBuilderScreenState();
}

class _MarketBuilderScreenState extends ConsumerState<MarketBuilderScreen> {
  _Step _step = _Step.upload;

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  DateTimeRange? _dates;
  EventImport? _import;
  final Set<String> _selectedImages = {};
  bool _importing = false;
  Uint8List? _imageBytes;
  String? _contentType;
  double _aspectRatio = 1;
  double _imageWidthPx = 1;

  PlanDraft? _draft;
  int _nextStandId = 0;

  // Placing
  final List<ControlPoint> _manualPoints = [];
  final List<ControlPoint> _rejectedGeocoded = [];
  PlanPoint? _pendingPlanPoint;
  double _overlayOpacity = 0.6;
  GoogleMapController? _map;
  Map<String, BitmapDescriptor> _markerIcons = {};

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- Upload

  Future<void> _pickImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 3000,
      maxHeight: 3000,
      imageQuality: 90,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final contentType = _detectContentType(bytes);
    if (contentType == null) {
      _showError('Bitte ein PNG-, JPG- oder WebP-Bild wählen. PDFs vorher als Bild exportieren.');
      return;
    }
    final image = await decodeImageFromList(bytes);
    setState(() {
      _imageBytes = bytes;
      _contentType = contentType;
      _aspectRatio = image.width / image.height;
      _imageWidthPx = image.width.toDouble();
    });
  }

  static String? _detectContentType(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
      return 'image/png';
    }
    if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length > 12 && String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') return 'image/webp';
    return null;
  }

  Future<void> _importFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _importing = true);
    try {
      final result = await ref.read(marketBuilderServiceProvider).importFromUrl(url);
      if (!mounted) return;
      setState(() {
        _import = result;
        _selectedImages
          ..clear()
          ..addAll(result.imageUrls);
        // Only fill what the organiser hasn't typed yet.
        void fill(TextEditingController c, String? value) {
          if (value != null && c.text.trim().isEmpty) c.text = value;
        }

        fill(_nameController, result.name);
        fill(_locationController, result.locationHint);
        fill(_descriptionController, result.description);
        if (_dates == null && result.startDate != null) {
          final end = result.endDate ?? result.startDate!;
          _dates = DateTimeRange(
            start: result.startDate!,
            end: end.add(const Duration(hours: 23, minutes: 59)),
          );
        }
      });
    } on FirebaseFunctionsException catch (e) {
      _showError(e.message ?? 'Die Webseite konnte nicht ausgewertet werden.');
    } catch (e) {
      _showError('Die Webseite konnte nicht ausgewertet werden: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  bool get _canAnalyze =>
      _imageBytes != null && _nameController.text.trim().isNotEmpty && _dates != null;

  Future<void> _analyze() async {
    if (_imageBytes!.lengthInBytes > 5 * 1024 * 1024) {
      _showError('Das Bild ist größer als 5 MB. Bitte verkleinern.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = _Step.analyzing);
    final service = ref.read(marketBuilderServiceProvider);
    try {
      final (path, url) = await service.uploadPlan(_imageBytes!, _contentType!);
      final location = _locationController.text.trim();
      final draft = await service.analyzePlan(
        storagePath: path,
        imageUrl: url,
        aspectRatio: _aspectRatio,
        locationHint: location.isEmpty ? null : location,
      );
      await _loadMarkerIcons();
      setState(() {
        _draft = draft;
        _nextStandId = draft.stands.length;
        _step = _Step.review;
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() => _step = _Step.upload);
      _showError(e.message ?? 'Die Analyse ist fehlgeschlagen.');
    } catch (e) {
      setState(() => _step = _Step.upload);
      _showError('Die Analyse ist fehlgeschlagen: $e');
    }
  }

  Future<void> _loadMarkerIcons() async {
    final icons = <String, BitmapDescriptor>{};
    for (final c in standCategories) {
      icons[c.key] = await categoryMarker(c);
    }
    _markerIcons = icons;
  }

  // ---------------------------------------------------------------- Review

  Future<void> _editStand(DraftStand stand) async {
    final result = await showModalBottomSheet<_StandEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StandEditor(stand: stand),
    );
    if (result == null) return;
    setState(() {
      if (result.delete) {
        _draft!.stands.remove(stand);
      } else {
        stand
          ..label = result.label
          ..category = result.category
          ..confidence = 'high';
      }
    });
  }

  Future<void> _addStand(PlanPoint position) async {
    final stand = DraftStand(
      id: 'stand_${_nextStandId++}',
      label: '',
      category: 'other',
      position: position,
    );
    final result = await showModalBottomSheet<_StandEdit>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StandEditor(stand: stand, isNew: true),
    );
    if (result == null || result.delete) return;
    setState(() {
      stand
        ..label = result.label
        ..category = result.category;
      _draft!.stands.add(stand);
    });
  }

  void _showWarnings(List<String> warnings) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('Hinweise der KI', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final w in warnings)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(w),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _recategorize(StandCategory from) async {
    final count = _draft!.stands.where((s) => s.category == from.key).length;
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
    setState(() {
      for (final s in _draft!.stands.where((s) => s.category == from.key)) {
        s.category = to.key;
      }
    });
  }

  // ----------------------------------------------------------------- Place

  /// Two points placed by the organiser beat any number of geocoded ones.
  Georeference? get _georeference {
    final draft = _draft!;
    if (_manualPoints.length >= 2) {
      return Georeference.fit(_manualPoints, aspectRatio: draft.aspectRatio);
    }
    final points = [
      ...draft.controlPoints.where((p) => !_rejectedGeocoded.contains(p)),
      ..._manualPoints,
    ];
    return Georeference.fitRobust(points, aspectRatio: draft.aspectRatio);
  }

  Future<void> _startAlignmentPoint() async {
    final point = await Navigator.of(context).push<PlanPoint>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PickPlanPointPage(
          imageBytes: _imageBytes!,
          aspectRatio: _draft!.aspectRatio,
          stands: _draft!.stands,
        ),
      ),
    );
    if (point != null) setState(() => _pendingPlanPoint = point);
  }

  void _onMapTap(LatLng position) {
    final planPoint = _pendingPlanPoint;
    if (planPoint == null) return;
    setState(() {
      _manualPoints.add(ControlPoint(
        label: 'Punkt ${_manualPoints.length + 1}',
        plan: planPoint,
        geo: GeoPoint(position.latitude, position.longitude),
        source: 'manual',
      ));
      _pendingPlanPoint = null;
    });
  }

  Future<void> _save(Georeference georeference) async {
    setState(() => _step = _Step.saving);
    try {
      final id = await ref.read(marketBuilderServiceProvider).saveMarket(
            draft: _draft!,
            georeference: georeference,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            start: _dates!.start,
            end: _dates!.end,
            imageUrls: [
              for (final url in _import?.imageUrls ?? const <String>[])
                if (_selectedImages.contains(url)) url,
            ],
            openingHours: _import?.openingHours ?? const [],
            ticketPrice: _import?.ticketPrice,
            organizerName: _import?.organizerName,
            organizerInfo: _import?.organizerInfo,
            eventTip: _import?.eventTip,
            websiteUrl: _import?.sourceUrl,
          );
      final event = await EventService().getEventById(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_draft!.stands.length} Stände gespeichert.')),
      );
      if (event != null) {
        Navigator.of(context).pushReplacementNamed('/event-details', arguments: event);
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _step = _Step.place);
      _showError('Speichern fehlgeschlagen: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ----------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final titles = {
      _Step.upload: 'Neuer Markt · 1/3 Lageplan',
      _Step.analyzing: 'KI liest den Plan …',
      _Step.review: 'Neuer Markt · 2/3 Stände prüfen',
      _Step.place: 'Neuer Markt · 3/3 Auf Karte ausrichten',
      _Step.saving: 'Speichern …',
    };
    return PopScope(
      canPop: _step == _Step.upload,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() {
          if (_step == _Step.place) {
            _step = _Step.review;
          } else if (_step == _Step.review) {
            _step = _Step.upload;
          }
        });
      },
      child: Scaffold(
        appBar: AppBar(title: Text(titles[_step]!)),
        body: switch (_step) {
          _Step.upload => _buildUpload(),
          _Step.analyzing => const _Busy(
              text: 'Die KI erkennt Stände und Orientierungspunkte.\nDas dauert meist 1–3 Minuten.',
            ),
          _Step.review => _buildReview(),
          _Step.place => _buildPlace(),
          _Step.saving => const _Busy(text: 'Markt wird gespeichert …'),
        },
      ),
    );
  }

  Widget _buildUpload() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return ListView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _buildImportCard(),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Name des Marktes *'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Ort',
            hintText: 'z. B. Marienplatz, München',
            helperText: 'Hilft, den Plan automatisch auf der Karte zu platzieren.',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(labelText: 'Beschreibung'),
          minLines: 2,
          maxLines: 6,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(_dates == null
              ? 'Zeitraum wählen *'
              : '${dateFormat.format(_dates!.start)} – ${dateFormat.format(_dates!.end)}'),
          onPressed: () async {
            final now = DateTime.now();
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 2),
              initialDateRange: _dates,
            );
            if (range != null) {
              // Include the whole last day.
              setState(() => _dates = DateTimeRange(
                    start: range.start,
                    end: range.end.add(const Duration(hours: 23, minutes: 59)),
                  ));
            }
          },
        ),
        const SizedBox(height: 24),
        if (_imageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: Image.memory(_imageBytes!, fit: BoxFit.contain),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.map_outlined),
          label: Text(_imageBytes == null ? 'Lageplan auswählen *' : 'Anderen Plan wählen'),
          onPressed: _pickImage,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Mit KI analysieren'),
          onPressed: _canAnalyze ? _analyze : null,
        ),
      ],
    );
  }

  Widget _buildImportCard() {
    final result = _import;
    final details = <(IconData, String)>[
      if (result != null && result.openingHours.isNotEmpty)
        (Icons.schedule, formatOpeningHours(result.openingHours)),
      if (result?.ticketPrice != null) (Icons.confirmation_number_outlined, result!.ticketPrice!),
      if (result?.organizerName != null) (Icons.business_outlined, result!.organizerName!),
      if (result?.eventTip != null) (Icons.lightbulb_outline, result!.eventTip!),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Infos von der Webseite übernehmen', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Optional: Beschreibung, Zeitraum, Öffnungszeiten und Bilder werden automatisch ausgefüllt.'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textInputAction: TextInputAction.go,
                    decoration: const InputDecoration(
                      labelText: 'Webadresse des Marktes',
                      hintText: 'https://…',
                    ),
                    onSubmitted: (_) => _importFromUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                _importing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : FilledButton.tonal(onPressed: _importFromUrl, child: const Text('Infos laden')),
              ],
            ),
            if (_importing)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Die KI liest die Seite … (ca. 20–60 Sekunden)'),
              ),
            if (result != null) ...[
              const SizedBox(height: 12),
              if (result.imageUrls.isNotEmpty) ...[
                const Text('Bilder – antippen zum Abwählen:'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final url in result.imageUrls)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImages.contains(url)
                                ? _selectedImages.remove(url)
                                : _selectedImages.add(url)),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Opacity(
                                    opacity: _selectedImages.contains(url) ? 1 : 0.35,
                                    child: Image.network(url, width: 140, height: 96, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Icon(
                                    _selectedImages.contains(url) ? Icons.check_circle : Icons.circle_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nur Bilder verwenden, die ihr nutzen dürft (z. B. vom eigenen Markt).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              for (final (icon, text) in details)
                ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(text)),
              for (final w in result.warnings)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text(w),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _import = null;
                    _selectedImages.clear();
                  }),
                  child: const Text('Bilder & Zusatzinfos verwerfen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final draft = _draft!;
    final counts = <String, int>{};
    for (final s in draft.stands) {
      counts[s.category] = (counts[s.category] ?? 0) + 1;
    }
    final uncertain = draft.stands.where((s) => s.confidence == 'low').length;

    return Column(
      children: [
        if (draft.warnings.isNotEmpty || uncertain > 0)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.info_outline),
              title: Text([
                if (draft.warnings.isNotEmpty)
                  '${draft.warnings.length} ${draft.warnings.length == 1 ? 'Hinweis' : 'Hinweise'} der KI',
                if (uncertain > 0) '$uncertain unsicher (gelber Rand)',
              ].join(' · ')),
              trailing: draft.warnings.isEmpty ? null : const Icon(Icons.expand_more),
              onTap: draft.warnings.isEmpty ? null : () => _showWarnings(draft.warnings),
            ),
          ),
        Expanded(
          child: PlanCanvas(
            imageBytes: _imageBytes!,
            aspectRatio: draft.aspectRatio,
            stands: draft.stands,
            onStandTap: _editStand,
            onStandMoved: (stand, position) => setState(() => stand.position = position),
            onTapPlan: _addStand,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(
            'Tippen = bearbeiten · gedrückt halten & ziehen = verschieben · '
            'freie Stelle antippen = Stand hinzufügen · Kategorie unten antippen = alle ändern',
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
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton(
              onPressed: draft.stands.isEmpty ? null : () => setState(() => _step = _Step.place),
              child: Text('${draft.stands.length} Stände übernehmen · Weiter'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlace() {
    final draft = _draft!;
    final georeference = _georeference;
    final overlay = georeference?.overlay();

    final markers = <Marker>{
      if (georeference != null)
        for (final stand in draft.stands)
          Marker(
            markerId: MarkerId(stand.id),
            position: _latLng(georeference.toGeo(stand.position)),
            icon: _markerIcons[stand.category] ?? BitmapDescriptor.defaultMarker,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(title: stand.label),
          ),
      for (final cp in georeference?.usedPoints ?? const <ControlPoint>[])
        Marker(
          markerId: MarkerId('cp_${cp.label}_${cp.plan.x}_${cp.plan.y}'),
          position: _latLng(cp.geo),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: cp.label),
          zIndexInt: 1,
        ),
    };

    final groundOverlays = <GroundOverlay>{
      if (overlay != null)
        GroundOverlay.fromPosition(
          groundOverlayId: const GroundOverlayId('plan'),
          image: BytesMapBitmap(_imageBytes!, bitmapScaling: MapBitmapScaling.none),
          position: _latLng(overlay.center),
          width: overlay.widthMeters,
          height: overlay.heightMeters,
          bearing: overlay.bearing,
          transparency: 1 - _overlayOpacity,
          // iOS sizes position-based overlays through the zoom level instead of
          // width/height: at this zoom one image pixel covers the right distance.
          zoomLevel: _overlayZoom(overlay),
          clickable: false,
        ),
    };

    final initialTarget = overlay?.center ?? draft.center ?? const GeoPoint(51.1657, 10.4515);
    final status = _alignmentStatus(georeference);

    return Column(
      children: [
        Material(
          color: georeference == null
              ? Colors.orange.shade100
              : (status.$2 ? Colors.green.shade50 : Colors.amber.shade100),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(georeference == null ? Icons.touch_app : Icons.check_circle_outline),
                const SizedBox(width: 12),
                Expanded(child: Text(status.$1)),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _latLng(initialTarget),
                  zoom: overlay != null ? 18 : (draft.center != null ? 17 : 5),
                ),
                mapType: MapType.hybrid,
                markers: markers,
                groundOverlays: groundOverlays,
                onMapCreated: (c) => _map = c,
                onTap: _onMapTap,
              ),
              if (_pendingPlanPoint != null)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.ads_click),
                      title: const Text('Tippe jetzt auf dieselbe Stelle auf der Karte.'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _pendingPlanPoint = null),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (overlay != null)
          Row(
            children: [
              const SizedBox(width: 16),
              const Text('Plan'),
              Expanded(
                child: Slider(
                  value: _overlayOpacity,
                  onChanged: (v) => setState(() => _overlayOpacity = v),
                ),
              ),
            ],
          ),
        if (_manualPoints.isNotEmpty || draft.controlPoints.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final cp in [...draft.controlPoints, ..._manualPoints])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _controlPointChip(cp, georeference),
                  ),
              ],
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Punkt zuordnen'),
                    onPressed: _startAlignmentPoint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Speichern'),
                    onPressed: georeference == null ? null : () => _save(georeference),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlPointChip(ControlPoint cp, Georeference? georeference) {
    final isManual = cp.source == 'manual';
    final rejected = _rejectedGeocoded.contains(cp);
    final used = georeference?.usedPoints.contains(cp) ?? false;
    return InputChip(
      avatar: Icon(isManual ? Icons.push_pin : Icons.place, size: 18),
      label: Text(cp.label, style: TextStyle(decoration: used ? null : TextDecoration.lineThrough)),
      selected: used,
      showCheckmark: false,
      onPressed: () => _map?.animateCamera(CameraUpdate.newLatLng(_latLng(cp.geo))),
      onDeleted: () => setState(() {
        if (isManual) {
          _manualPoints.remove(cp);
        } else if (rejected) {
          _rejectedGeocoded.remove(cp);
        } else {
          _rejectedGeocoded.add(cp);
        }
      }),
      deleteIcon: Icon(!isManual && rejected ? Icons.undo : Icons.close, size: 18),
    );
  }

  /// Message for the status bar and whether the alignment looks trustworthy.
  (String, bool) _alignmentStatus(Georeference? g) {
    if (g == null) {
      return (
        'Der Plan konnte nicht automatisch platziert werden. Tippe auf „Punkt zuordnen“, '
            'wähle eine markante Stelle auf dem Plan und tippe dann auf dieselbe Stelle auf der '
            'Karte. Zwei Punkte reichen.',
        false,
      );
    }
    final manual = g.usedPoints.where((p) => p.source == 'manual').length;
    final auto = g.usedPoints.length - manual;
    final source = manual == 0
        ? 'Automatisch platziert anhand von $auto Orientierungspunkten'
        : 'Platziert anhand von ${g.usedPoints.length} Punkten';
    final rms = g.rmsErrorMeters;
    if (rms == null) {
      return (
        '$source. Passt der Plan zur Karte? Sonst weitere Punkte zuordnen.',
        manual >= 2,
      );
    }
    final ok = rms < 10;
    return (
      '$source (Abweichung ca. ${rms.toStringAsFixed(0)} m). '
          '${ok ? 'Sieht gut aus.' : 'Bitte prüfen und ggf. Punkte zuordnen.'}',
      ok,
    );
  }

  double _overlayZoom(PlanOverlay overlay) {
    final metersPerPixelAtZoom0 = 156543.03392 * math.cos(overlay.center.latitude * math.pi / 180);
    return math.log(metersPerPixelAtZoom0 * _imageWidthPx / overlay.widthMeters) / math.ln2;
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);
}

class _Busy extends StatelessWidget {
  final String text;

  const _Busy({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _StandEdit {
  final String label;
  final String category;
  final bool delete;

  const _StandEdit(this.label, this.category, {this.delete = false});
}

class _StandEditor extends StatefulWidget {
  final DraftStand stand;
  final bool isNew;

  const _StandEditor({required this.stand, this.isNew = false});

  @override
  State<_StandEditor> createState() => _StandEditorState();
}

class _StandEditorState extends State<_StandEditor> {
  late final _label = TextEditingController(text: widget.stand.label);
  late String _category = widget.stand.category;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.isNew ? 'Stand hinzufügen' : 'Stand bearbeiten',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            autofocus: widget.isNew,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in standCategories)
                ChoiceChip(
                  avatar: Icon(c.icon, size: 18, color: c.color),
                  label: Text(c.name),
                  selected: _category == c.key,
                  onSelected: (_) => setState(() => _category = c.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!widget.isNew)
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Löschen', style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(context, const _StandEdit('', '', delete: true)),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final label = _label.text.trim();
                  if (label.isEmpty) return;
                  Navigator.pop(context, _StandEdit(label, _category));
                },
                child: const Text('Übernehmen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickPlanPointPage extends StatelessWidget {
  final Uint8List imageBytes;
  final double aspectRatio;
  final List<DraftStand> stands;

  const _PickPlanPointPage({
    required this.imageBytes,
    required this.aspectRatio,
    required this.stands,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stelle auf dem Plan wählen')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Tippe auf eine Stelle, die du auch auf der Karte sicher findest – '
              'z. B. eine Kirchenecke, einen Brunnen oder eine Straßenkreuzung. '
              'Punkte weit auseinander funktionieren am besten.',
            ),
          ),
          Expanded(
            child: PlanCanvas(
              imageBytes: imageBytes,
              aspectRatio: aspectRatio,
              stands: stands,
              onTapPlan: (p) => Navigator.pop(context, p),
            ),
          ),
        ],
      ),
    );
  }
}
