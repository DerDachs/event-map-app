import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/feed_post.dart';
import '../providers/feed_provider.dart';
import 'feed_post_edit_screen.dart';

final _allPostsProvider = StreamProvider.autoDispose<List<FeedPost>>(
  (ref) => ref.watch(feedServiceProvider).watchAll(),
);

/// Admin list of all start page posts, including scheduled and expired ones.
class FeedAdminScreen extends ConsumerStatefulWidget {
  const FeedAdminScreen({super.key});

  @override
  ConsumerState<FeedAdminScreen> createState() => _FeedAdminScreenState();
}

class _FeedAdminScreenState extends ConsumerState<FeedAdminScreen> {
  bool _importing = false;

  Future<void> _importExamples() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Beispiele für die Saison 2026 einfügen?'),
        content: const Text(
          'Fügt Beiträge zu den Märkten in Köln, Frankfurt, Nürnberg und Dresden sowie ein paar Tipps ein. '
          'Bitte die Termine vor dem Veröffentlichen prüfen. Bereits vorhandene Beispiele werden übersprungen.',
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
      final added = await ref.read(feedServiceProvider).importExamples();
      ref.invalidate(feedPostsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(added == 0 ? 'Alle Beispiele sind schon vorhanden.' : '$added Beiträge eingefügt.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Einfügen fehlgeschlagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _edit(FeedPost? post) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FeedPostEditScreen(post: post)),
      );

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(_allPostsProvider);
    final now = DateTime.now();
    final format = DateFormat('dd.MM.yyyy HH:mm', 'de');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Startseite: Beiträge'),
        actions: [
          IconButton(
            tooltip: 'Beispiele Saison 2026 einfügen',
            onPressed: _importing ? null : _importExamples,
            icon: _importing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Beitrag'),
        onPressed: () => _edit(null),
      ),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Beiträge konnten nicht geladen werden: $e')),
        data: (posts) => posts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Noch keine Beiträge.', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('Beispiele Saison 2026 einfügen'),
                        onPressed: _importing ? null : _importExamples,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final post = posts[i];
                  final state = post.publishAt.isAfter(now)
                      ? 'geplant ab ${format.format(post.publishAt)}'
                      : (post.isVisibleAt(now) ? 'sichtbar' : 'abgelaufen');
                  return ListTile(
                    leading: Icon(post.pinned ? Icons.push_pin : Icons.article_outlined),
                    title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text([post.type.label, state, if (post.seasonId != null) 'Saison'].join(' · ')),
                    onTap: () => _edit(post),
                  );
                },
              ),
      ),
    );
  }
}
