import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../feed/logic/home_feed.dart';
import '../../feed/widgets/feed_cards.dart';
import '../models/market_types.dart';
import '../models/season.dart';
import '../providers/season_provider.dart';

/// Create or change a season: dates, markets, look and countdown.
class SeasonEditScreen extends ConsumerStatefulWidget {
  /// Null for a new season.
  final Season? season;

  const SeasonEditScreen({super.key, this.season});

  @override
  ConsumerState<SeasonEditScreen> createState() => _SeasonEditScreenState();
}

class _SeasonEditScreenState extends ConsumerState<SeasonEditScreen> {
  late final _name = TextEditingController(text: widget.season?.name);
  late final _tagline = TextEditingController(text: widget.season?.tagline);
  late final _countdownLabel = TextEditingController(text: widget.season?.countdownLabel);
  late final _nameEn = TextEditingController(text: widget.season?.nameEn);
  late final _taglineEn = TextEditingController(text: widget.season?.taglineEn);
  late final _countdownLabelEn = TextEditingController(text: widget.season?.countdownLabelEn);
  late DateTimeRange? _window = widget.season == null
      ? null
      : DateTimeRange(
          start: widget.season!.startsAt,
          end: widget.season!.endsAt.subtract(const Duration(days: 1)),
        );
  late final Set<String> _types = {...?widget.season?.marketTypes};
  late SeasonAccent _accent = widget.season?.accent ?? SeasonAccent.christmas;
  late DateTime? _countdownTo = widget.season?.countdownTo;
  late final List<SeasonMilestone> _milestones = [...?widget.season?.milestones];
  late bool _active = widget.season?.active ?? true;
  bool _busy = false;

  final _dateFormat = DateFormat('dd.MM.yyyy', 'de');

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _countdownLabel.dispose();
    _nameEn.dispose();
    _taglineEn.dispose();
    _countdownLabelEn.dispose();
    super.dispose();
  }

  Season? _current() {
    final window = _window;
    if (window == null) return null;
    return Season(
      id: widget.season?.id ?? '',
      name: _name.text.trim(),
      tagline: _tagline.text.trim(),
      // The season covers the whole last day.
      startsAt: DateUtils.dateOnly(window.start),
      endsAt: DateUtils.dateOnly(window.end).add(const Duration(days: 1)),
      marketTypes: marketTypes.map((t) => t.key).where(_types.contains).toList(),
      accent: _accent,
      countdownTo: _countdownTo,
      countdownLabel: _countdownLabel.text.trim(),
      milestones: [..._milestones]..sort((a, b) => a.date.compareTo(b.date)),
      active: _active,
      nameEn: _nameEn.text.trim(),
      taglineEn: _taglineEn.text.trim(),
      countdownLabelEn: _countdownLabelEn.text.trim(),
    );
  }

  Future<void> _save() async {
    final season = _current();
    String? problem;
    if (_name.text.trim().isEmpty) {
      problem = 'Bitte einen Namen eingeben.';
    } else if (season == null) {
      problem = 'Bitte den Zeitraum wählen.';
    } else if (season.marketTypes.isEmpty) {
      problem = 'Bitte mindestens eine Marktart wählen.';
    } else if (season.countdownTo != null && season.countdownLabel.isEmpty) {
      problem = 'Bitte angeben, worauf der Countdown zählt (z. B. Heiligabend).';
    }
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(seasonServiceProvider).save(season!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speichern fehlgeschlagen: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saison löschen?'),
        content: const Text('Beiträge, die nur in dieser Saison erscheinen, werden dann nicht mehr angezeigt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(seasonServiceProvider).delete(widget.season!.id);
    if (mounted) Navigator.pop(context);
  }

  /// Picks a day. Stored at noon, so it stays the same calendar day in any
  /// time zone the app runs in.
  Future<DateTime?> _pickDate(DateTime? initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial ?? _window?.start ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    return d == null ? null : DateTime(d.year, d.month, d.day, 12);
  }

  Future<void> _addMilestone() async {
    final label = TextEditingController();
    final labelEn = TextEditingController();
    DateTime? date;
    final result = await showDialog<SeasonMilestone>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Termin hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Bezeichnung', hintText: 'z. B. 1. Advent'),
              ),
              TextField(
                controller: labelEn,
                decoration: const InputDecoration(labelText: 'Englisch (optional)', hintText: '1st Sunday of Advent'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(date == null ? 'Datum wählen' : _dateFormat.format(date!)),
                onPressed: () async {
                  final d = await _pickDate(date);
                  if (d != null) setDialogState(() => date = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                if (label.text.trim().isEmpty || date == null) return;
                Navigator.pop(context, SeasonMilestone(label.text.trim(), date!, labelEn: labelEn.text.trim()));
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    labelEn.dispose();
    if (result != null) setState(() => _milestones.add(result));
  }

  @override
  Widget build(BuildContext context) {
    final preview = _current();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.season == null ? 'Neue Saison' : 'Saison bearbeiten'),
        actions: [
          if (widget.season != null)
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
          if (preview != null && preview.name.isNotEmpty) ...[
            SeasonBannerCard(banner: SeasonBanner.of(preview, DateTime.now(), context.l10n)),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name *', hintText: 'z. B. Weihnachtsmärkte 2026'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagline,
            decoration: const InputDecoration(labelText: 'Unterzeile', hintText: 'Kurz und warm, ohne Punkt'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(_window == null
                ? 'Zeitraum wählen *'
                : 'Sichtbar ${_dateFormat.format(_window!.start)} – ${_dateFormat.format(_window!.end)}'),
            onPressed: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 3),
                initialDateRange: _window,
              );
              if (range != null) setState(() => _window = range);
            },
          ),
          const SizedBox(height: 20),
          Text('Märkte dieser Saison *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in marketTypes)
                FilterChip(
                  label: Text(t.name),
                  selected: _types.contains(t.key),
                  onSelected: (on) => setState(() => on ? _types.add(t.key) : _types.remove(t.key)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Farbe & Symbol', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              for (final a in SeasonAccent.values)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: a.color, child: Icon(a.icon, size: 14, color: a.sparkle)),
                  label: Text(a.label),
                  selected: _accent == a,
                  onSelected: (_) => setState(() => _accent = a),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Countdown', style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _countdownLabel,
                  decoration: const InputDecoration(labelText: 'bis …', hintText: 'Heiligabend'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () async {
                  final d = await _pickDate(_countdownTo);
                  if (d != null) setState(() => _countdownTo = d);
                },
                child: Text(_countdownTo == null ? 'Datum' : _dateFormat.format(_countdownTo!)),
              ),
              if (_countdownTo != null)
                IconButton(
                  tooltip: 'Kein Countdown',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _countdownTo = null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Weitere Termine', style: Theme.of(context).textTheme.titleSmall),
          for (final m in [..._milestones]..sort((a, b) => a.date.compareTo(b.date)))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.event_outlined),
              title: Text(m.labelEn.isEmpty ? m.label : '${m.label} / ${m.labelEn}'),
              subtitle: Text(_dateFormat.format(m.date)),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _milestones.remove(m)),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Termin hinzufügen'),
              onPressed: _addMilestone,
            ),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: _nameEn.text.isNotEmpty,
            title: const Text('Englische Fassung (optional)'),
            children: [
              TextField(controller: _nameEn, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: _taglineEn, decoration: const InputDecoration(labelText: 'Tagline')),
              const SizedBox(height: 12),
              TextField(
                controller: _countdownLabelEn,
                decoration: const InputDecoration(labelText: 'Countdown to …', hintText: 'Christmas Eve'),
              ),
              const SizedBox(height: 12),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aktiv'),
            subtitle: const Text('Ausgeschaltete Saisons erscheinen nie auf der Startseite.'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    );
  }
}
