import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../logic/stand_list.dart';
import '../services/image_input.dart';
import '../services/market_builder_service.dart';

/// Fills in names, descriptions, offers and specials of many stands at once
/// from a stand list (pasted text, photo/PDF or web page). Entries are matched
/// to [stands] by number, then by name; the rest can be assigned by hand.
/// Used by the market builder and the market editor.
Future<void> importStandList<T>({
  required BuildContext context,
  required MarketBuilderService service,
  required List<T> stands,
  required MatchTarget Function(T stand) target,
  required void Function(T stand, StandListEntry entry) apply,
  required VoidCallback onChanged,
}) async {
  final source = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Standliste importieren', style: Theme.of(context).textTheme.titleLarge),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Namen, Beschreibungen und Angebote aus einer Aussteller- oder Standliste '
                'übernehmen. Die KI ordnet sie über Standnummer oder Namen zu.'),
          ),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Text einfügen'),
            subtitle: const Text('z. B. aus einer E-Mail oder Tabelle kopiert'),
            onTap: () => Navigator.pop(context, 'text'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_back_outlined),
            title: const Text('Foto oder PDF'),
            subtitle: const Text('Ausstellerliste, Flyer, Legende des Plans'),
            onTap: () => Navigator.pop(context, 'file'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Webseite'),
            subtitle: const Text('Seite mit der Ausstellerliste'),
            onTap: () => Navigator.pop(context, 'url'),
          ),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  String? text, url, storagePath;
  if (source == 'text' || source == 'url') {
    final value = await _askInput(context, isUrl: source == 'url');
    if (value == null || value.isEmpty) return;
    source == 'text' ? text = value : url = value;
  } else {
    final picked = await pickImageOrPdf(context, photosSubtitle: 'Foto der Standliste');
    if (picked == null || !context.mounted) return;
    try {
      storagePath = (await service.uploadPlan(picked.bytes, picked.contentType)).$1;
    } catch (e) {
      if (context.mounted) _snack(context, 'Hochladen fehlgeschlagen: $e');
      return;
    }
  }
  if (!context.mounted) return;

  // Blocking progress while the AI reads the list.
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 20),
          Expanded(child: Text('Die KI liest die Standliste …')),
        ]),
      ),
    ),
  );
  List<StandListEntry> entries;
  List<String> warnings;
  try {
    (entries, warnings) = await service.parseStandList(text: text, url: url, storagePath: storagePath);
  } on FirebaseFunctionsException catch (e) {
    navigator.pop();
    if (context.mounted) _snack(context, e.message ?? 'Die Standliste konnte nicht gelesen werden.');
    return;
  } catch (e) {
    navigator.pop();
    if (context.mounted) _snack(context, 'Die Standliste konnte nicht gelesen werden: $e');
    return;
  }
  navigator.pop();
  if (!context.mounted) return;

  final targets = stands.map(target).toList();
  final matches = matchStandList(entries, targets);
  final byId = {for (var i = 0; i < stands.length; i++) targets[i].id: stands[i]};
  final unmatched = <StandListEntry>[];
  for (var i = 0; i < entries.length; i++) {
    final id = matches[i];
    if (id == null) {
      unmatched.add(entries[i]);
    } else {
      apply(byId[id] as T, entries[i]);
    }
  }
  onChanged();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ResultSheet<T>(
      applied: entries.length - unmatched.length,
      total: entries.length,
      warnings: warnings,
      unmatched: unmatched,
      stands: stands,
      target: target,
      assign: (stand, entry) {
        apply(stand, entry);
        onChanged();
      },
    ),
  );
}

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<String?> _askInput(BuildContext context, {required bool isUrl}) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isUrl ? 'Webseite mit der Standliste' : 'Standliste einfügen',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: isUrl ? TextInputType.url : TextInputType.multiline,
            minLines: isUrl ? 1 : 6,
            maxLines: isUrl ? 1 : 14,
            decoration: InputDecoration(
              hintText: isUrl
                  ? 'https://…'
                  : 'z. B.\n12 Crêpes-Hütte – Crêpes, Waffeln\n14 Glühweinstand Maier – Glühwein, Punsch\n…',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Mit KI auslesen'),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
          ),
        ],
      ),
    ),
  );
}

class _ResultSheet<T> extends StatefulWidget {
  final int applied;
  final int total;
  final List<String> warnings;
  final List<StandListEntry> unmatched;
  final List<T> stands;
  final MatchTarget Function(T) target;
  final void Function(T, StandListEntry) assign;

  const _ResultSheet({
    required this.applied,
    required this.total,
    required this.warnings,
    required this.unmatched,
    required this.stands,
    required this.target,
    required this.assign,
  });

  @override
  State<_ResultSheet<T>> createState() => _ResultSheetState<T>();
}

class _ResultSheetState<T> extends State<_ResultSheet<T>> {
  late final List<StandListEntry> _open = [...widget.unmatched];
  late int _applied = widget.applied;

  Future<void> _choose(StandListEntry entry) async {
    final stand = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Welcher Stand ist „${entry.name}“?', style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final s in widget.stands)
              ListTile(
                leading: CircleAvatar(child: Text(widget.target(s).number ?? '–')),
                title: Text(widget.target(s).label),
                onTap: () => Navigator.pop(context, s),
              ),
          ],
        ),
      ),
    );
    if (stand == null) return;
    widget.assign(stand, entry);
    setState(() {
      _open.remove(entry);
      _applied++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _open.isEmpty && widget.warnings.isEmpty ? 0.3 : 0.7,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            widget.total == 0 ? 'Keine Stände gefunden' : '$_applied von ${widget.total} Ständen übernommen',
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final w in widget.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(w)),
              ]),
            ),
          if (_open.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Nicht zugeordnet – antippen und Stand wählen:', style: text.titleSmall),
            for (final e in _open)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(e.number ?? '?')),
                title: Text(e.name),
                subtitle: e.description == null ? null : Text(e.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.link),
                onTap: () => _choose(e),
              ),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fertig')),
        ],
      ),
    );
  }
}
