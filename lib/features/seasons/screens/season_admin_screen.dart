import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/formatters.dart';
import '../models/season.dart';
import '../providers/season_provider.dart';
import 'season_edit_screen.dart';

/// Admin list of seasons: which one runs now, which come next.
class SeasonAdminScreen extends ConsumerStatefulWidget {
  const SeasonAdminScreen({super.key});

  @override
  ConsumerState<SeasonAdminScreen> createState() => _SeasonAdminScreenState();
}

class _SeasonAdminScreenState extends ConsumerState<SeasonAdminScreen> {
  bool _importing = false;

  Future<void> _importExamples() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beispiel-Saisons einfügen?'),
        content: const Text(
          'Weihnachten 2026, Ostern, Pfingsten, Sommer und Herbst 2027. Bereits vorhandene werden übersprungen, '
          'alles lässt sich danach anpassen.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Einfügen')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _importing = true);
    try {
      final added = await ref.read(seasonServiceProvider).importExamples();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(added == 0 ? 'Alle Beispiel-Saisons sind schon vorhanden.' : '$added Saisons eingefügt.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Einfügen fehlgeschlagen: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _edit(Season? season) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => SeasonEditScreen(season: season)));

  @override
  Widget build(BuildContext context) {
    final seasons = ref.watch(seasonsProvider);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisons'),
        actions: [
          IconButton(
            tooltip: 'Beispiel-Saisons einfügen',
            onPressed: _importing ? null : _importExamples,
            icon: _importing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Saison'),
        onPressed: () => _edit(null),
      ),
      body: seasons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Saisons konnten nicht geladen werden: $e')),
        data: (seasons) {
          if (seasons.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Noch keine Saisons. Ohne Saison zeigt die Startseite alle Märkte ohne Banner.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Beispiel-Saisons einfügen'),
                      onPressed: _importing ? null : _importExamples,
                    ),
                  ],
                ),
              ),
            );
          }
          final current = currentSeason(seasons, now);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final s in seasons)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: s.active ? s.accent.color : Colors.grey,
                    child: Icon(s.accent.icon, color: s.accent.sparkle),
                  ),
                  title: Text(s.name),
                  subtitle: Text([
                    formatDateRange(s.startsAt, s.endsAt.subtract(const Duration(minutes: 1))),
                    if (!s.active) 'ausgeschaltet' else if (s.id == current?.id) 'läuft gerade',
                  ].join(' · ')),
                  trailing: s.id == current?.id ? const Icon(Icons.play_circle_outline) : null,
                  onTap: () => _edit(s),
                ),
            ],
          );
        },
      ),
    );
  }
}
