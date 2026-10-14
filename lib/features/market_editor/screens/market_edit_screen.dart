import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/models/eventImage.dart';
import '../../events/providers/event_provider.dart';
import '../models/market_edit_draft.dart';
import '../services/market_edit_service.dart';
import '../widgets/image_list_editor.dart';
import '../widgets/opening_hours_editor.dart';
import '../widgets/stand_map_editor.dart';

final marketEditServiceProvider = Provider((ref) => MarketEditService());

/// Admin editor for an existing market: details, pictures and stands.
class MarketEditScreen extends ConsumerStatefulWidget {
  final String eventId;

  const MarketEditScreen({super.key, required this.eventId});

  @override
  ConsumerState<MarketEditScreen> createState() => _MarketEditScreenState();
}

class _MarketEditScreenState extends ConsumerState<MarketEditScreen> {
  MarketEditDraft? _draft;
  Object? _loadError;
  Uint8List? _planImage;
  bool _dirty = false;
  bool _saving = false;
  bool _uploading = false;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _ticketPrice = TextEditingController();
  final _organizerName = TextEditingController();
  final _organizerInfo = TextEditingController();
  final _eventTip = TextEditingController();
  final _websiteUrl = TextEditingController();

  List<TextEditingController> get _controllers =>
      [_name, _description, _ticketPrice, _organizerName, _organizerInfo, _eventTip, _websiteUrl];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    final service = ref.read(marketEditServiceProvider);
    try {
      final draft = await service.load(widget.eventId);
      _name.text = draft.name;
      _description.text = draft.description;
      _ticketPrice.text = draft.ticketPrice;
      _organizerName.text = draft.organizerName;
      _organizerInfo.text = draft.organizerInfo;
      _eventTip.text = draft.eventTip;
      _websiteUrl.text = draft.websiteUrl;
      if (!mounted) return;
      setState(() => _draft = draft);
      final planUrl = draft.planImageUrl;
      if (planUrl != null) {
        // The plan is only a backdrop; the editor works without it.
        service.loadPlanImage(planUrl).then((bytes) {
          if (mounted) setState(() => _planImage = bytes);
        }).catchError((_) {});
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _applyText() {
    final d = _draft!;
    d
      ..name = _name.text.trim()
      ..description = _description.text.trim()
      ..ticketPrice = _ticketPrice.text.trim()
      ..organizerName = _organizerName.text.trim()
      ..organizerInfo = _organizerInfo.text.trim()
      ..eventTip = _eventTip.text.trim()
      ..websiteUrl = _websiteUrl.text.trim();
  }

  Future<void> _save() async {
    _applyText();
    final draft = _draft!;
    if (draft.name.isEmpty) {
      _showMessage('Bitte einen Namen eingeben.');
      return;
    }
    if (draft.openingHours.any((h) => h.days.isEmpty)) {
      _showMessage('Bei jeder Zeile der Öffnungszeiten mindestens einen Tag wählen.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await ref.read(marketEditServiceProvider).save(draft);
      ref.invalidate(eventsProvider);
      if (!mounted) return;
      _dirty = false;
      _showMessage('Gespeichert.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _showMessage('Speichern fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final draft = _draft!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Markt löschen?'),
        content: Text(
          '„${draft.name}“ wird mit allen ${draft.stands.length} Ständen gelöscht. '
          'Besucher sehen den Markt danach nicht mehr. Das lässt sich nicht rückgängig machen.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(marketEditServiceProvider).delete(draft);
      ref.invalidate(eventsProvider);
      if (!mounted) return;
      _dirty = false;
      _showMessage('Markt gelöscht.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showMessage('Löschen fehlgeschlagen: $e');
      }
    }
  }

  Future<void> _addImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(marketEditServiceProvider).uploadImage(widget.eventId, await file.readAsBytes());
      final draft = _draft!;
      setState(() => draft.images = [...draft.images, EventImage(url: url, isStandard: draft.images.isEmpty)]);
      _markDirty();
    } catch (e) {
      _showMessage('Hochladen fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text('Du hast Änderungen, die noch nicht gespeichert sind.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Weiter bearbeiten')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwerfen')),
        ],
      ),
    );
    return discard == true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _saving) return;
        if (await _confirmDiscard() && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Markt bearbeiten'),
            actions: [
              if (draft != null)
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'delete' ? _delete() : null,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Markt löschen')),
                  ],
                ),
            ],
            bottom: draft == null
                ? null
                : TabBar(tabs: [
                    const Tab(text: 'Details'),
                    Tab(text: 'Stände (${draft.stands.length})'),
                  ]),
          ),
          body: _loadError != null
              ? _LoadError(error: _loadError!, onRetry: _load)
              : draft == null || _saving
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      // The map needs horizontal drags for itself.
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildDetails(draft),
                        StandMapEditor(
                          draft: draft,
                          planImage: _planImage,
                          onChanged: () {
                            _markDirty();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
          bottomNavigationBar: draft == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_dirty ? 'Änderungen speichern' : 'Keine Änderungen'),
                      onPressed: _dirty && !_saving ? _save : null,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetails(MarketEditDraft draft) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'de');
    Widget field(TextEditingController c, String label, {int maxLines = 1, String? hint, TextInputType? type}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            minLines: 1,
            maxLines: maxLines,
            keyboardType: type,
            textCapitalization: type == null ? TextCapitalization.sentences : TextCapitalization.none,
            decoration: InputDecoration(labelText: label, hintText: hint),
            onChanged: (_) => _markDirty(),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ImageListEditor(
          images: draft.images,
          uploading: _uploading,
          onAdd: _addImage,
          onChanged: (images) {
            setState(() => draft.images = images);
            _markDirty();
          },
        ),
        const SizedBox(height: 16),
        field(_name, 'Name des Marktes *'),
        field(_description, 'Beschreibung', maxLines: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text('${dateFormat.format(draft.start)} – ${dateFormat.format(draft.end)}'),
          onPressed: () async {
            final now = DateTime.now();
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 3),
              initialDateRange: DateTimeRange(
                start: DateUtils.dateOnly(draft.start),
                end: DateUtils.dateOnly(draft.end),
              ),
            );
            if (range == null) return;
            setState(() {
              draft.start = range.start;
              // Include the whole last day.
              draft.end = range.end.add(const Duration(hours: 23, minutes: 59));
            });
            _markDirty();
          },
        ),
        const SizedBox(height: 20),
        Text('Öffnungszeiten', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        OpeningHoursEditor(
          hours: draft.openingHours,
          onChanged: (hours) {
            setState(() => draft.openingHours = hours);
            _markDirty();
          },
        ),
        const SizedBox(height: 12),
        field(_ticketPrice, 'Eintritt', hint: 'z. B. frei'),
        field(_eventTip, 'Unser Tipp', maxLines: 4),
        field(_organizerName, 'Veranstalter'),
        field(_organizerInfo, 'Über den Veranstalter', maxLines: 4),
        field(_websiteUrl, 'Webseite', hint: 'https://…', type: TextInputType.url),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _LoadError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Der Markt konnte nicht geladen werden.\n$error', textAlign: TextAlign.center),
              TextButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
            ],
          ),
        ),
      );
}
