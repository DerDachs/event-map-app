import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../events/providers/event_provider.dart';
import '../../seasons/models/season.dart';
import '../../seasons/providers/season_provider.dart';
import '../models/feed_post.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_cards.dart';

/// Write or change a start page post.
class FeedPostEditScreen extends ConsumerStatefulWidget {
  /// Null for a new post.
  final FeedPost? post;

  const FeedPostEditScreen({super.key, this.post});

  @override
  ConsumerState<FeedPostEditScreen> createState() => _FeedPostEditScreenState();
}

class _FeedPostEditScreenState extends ConsumerState<FeedPostEditScreen> {
  late final _title = TextEditingController(text: widget.post?.title);
  late final _body = TextEditingController(text: widget.post?.body);
  late final _linkUrl = TextEditingController(text: widget.post?.linkUrl);
  late final _linkLabel = TextEditingController(text: widget.post?.linkLabel);
  late final _titleEn = TextEditingController(text: widget.post?.titleEn);
  late final _bodyEn = TextEditingController(text: widget.post?.bodyEn);
  late final _linkLabelEn = TextEditingController(text: widget.post?.linkLabelEn);
  late FeedPostType _type = widget.post?.type ?? FeedPostType.news;
  late String? _imageUrl = widget.post?.imageUrl;
  late String? _eventId = widget.post?.eventId;
  late DateTime _publishAt = widget.post?.publishAt ?? DateTime.now();
  late DateTime? _expiresAt = widget.post?.expiresAt;
  late bool _pinned = widget.post?.pinned ?? false;
  late String? _seasonId = widget.post?.seasonId;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _body, _linkUrl, _linkLabel, _titleEn, _bodyEn, _linkLabelEn]) {
      c.dispose();
    }
    super.dispose();
  }

  FeedPost _current() {
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return FeedPost(
      id: widget.post?.id ?? '',
      type: _type,
      title: _title.text.trim(),
      body: _body.text.trim(),
      imageUrl: _imageUrl,
      eventId: _eventId,
      linkUrl: text(_linkUrl),
      linkLabel: text(_linkLabel),
      publishAt: _publishAt,
      expiresAt: _expiresAt,
      pinned: _pinned,
      seasonId: _seasonId,
      titleEn: _titleEn.text.trim(),
      bodyEn: _bodyEn.text.trim(),
      linkLabelEn: text(_linkLabelEn),
    );
  }

  Future<void> _save() async {
    final post = _current();
    if (post.title.isEmpty) {
      _message('Bitte einen Titel eingeben.');
      return;
    }
    if (post.linkUrl != null && Uri.tryParse(post.linkUrl!)?.hasScheme != true) {
      _message('Der Link muss mit https:// beginnen.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(feedServiceProvider).save(post);
      ref.invalidate(feedPostsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _message('Speichern fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beitrag löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(feedServiceProvider).delete(widget.post!.id);
    ref.invalidate(feedPostsProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final ref = FirebaseStorage.instance.ref('feed-images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await file.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      setState(() => _imageUrl = url);
    } catch (e) {
      _message('Hochladen fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 1),
      lastDate: DateTime(initial.year + 2),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    return DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider).valueOrNull ?? const [];
    final format = DateFormat('dd.MM.yyyy, HH:mm', 'de');
    final linkedEvent = events.where((e) => e.id == _eventId).firstOrNull;
    final seasons = ref.watch(seasonsProvider).valueOrNull ?? const <Season>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.post == null ? 'Neuer Beitrag' : 'Beitrag bearbeiten'),
        actions: [
          if (widget.post != null)
            IconButton(tooltip: 'Löschen', icon: const Icon(Icons.delete_outline), onPressed: _busy ? null : _delete),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(onPressed: _busy ? null : _save, child: const Text('Speichern')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SegmentedButton<FeedPostType>(
            segments: [
              for (final t in FeedPostType.values) ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Titel *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'Text', alignLabelWithHint: true),
            onChanged: (_) => setState(() {}),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: _titleEn.text.isNotEmpty,
            title: const Text('Englische Fassung (optional)'),
            subtitle: const Text('Ohne englischen Titel sehen englische Nutzer den deutschen Text.'),
            children: [
              TextField(controller: _titleEn, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyEn,
                minLines: 3,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Text', alignLabelWithHint: true),
              ),
              const SizedBox(height: 12),
              TextField(controller: _linkLabelEn, decoration: const InputDecoration(labelText: 'Link text')),
              const SizedBox(height: 12),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_imageUrl!, width: 96, height: 64, fit: BoxFit.cover),
                ),
              if (_imageUrl != null) const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_imageUrl == null ? 'Bild hinzufügen' : 'Anderes Bild'),
                onPressed: _busy ? null : _pickImage,
              ),
              if (_imageUrl != null)
                IconButton(
                  tooltip: 'Bild entfernen',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _imageUrl = null),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: linkedEvent?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Verknüpfter Markt'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Keiner')),
              for (final e in events) DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _eventId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkUrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Link', hintText: 'https://…'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _linkLabel,
            decoration: const InputDecoration(labelText: 'Link-Text', hintText: 'Mehr erfahren'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Sichtbar ab'),
            subtitle: Text(format.format(_publishAt)),
            onTap: () async {
              final t = await _pickDateTime(_publishAt);
              if (t != null) setState(() => _publishAt = t);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_busy_outlined),
            title: const Text('Ausblenden ab'),
            subtitle: Text(_expiresAt == null ? 'Nie' : format.format(_expiresAt!)),
            trailing: _expiresAt == null
                ? null
                : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _expiresAt = null)),
            onTap: () async {
              final t = await _pickDateTime(_expiresAt ?? linkedEvent?.endTime ?? DateTime.now());
              if (t != null) setState(() => _expiresAt = t);
            },
          ),
          DropdownButtonFormField<String?>(
            initialValue: seasons.any((s) => s.id == _seasonId) ? _seasonId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Nur in Saison zeigen',
              helperText: 'Ohne Saison erscheint der Beitrag das ganze Jahr.',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Ganzjährig')),
              for (final s in seasons) DropdownMenuItem(value: s.id, child: Text(s.name)),
            ],
            onChanged: (v) => setState(() => _seasonId = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Oben anheften'),
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v),
          ),
          const SizedBox(height: 16),
          Text('Vorschau', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_title.text.trim().isNotEmpty)
            FeedPostCard(post: _current(), event: linkedEvent, now: DateTime.now()),
        ],
      ),
    );
  }
}
