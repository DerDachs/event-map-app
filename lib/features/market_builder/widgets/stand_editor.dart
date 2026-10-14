import 'package:flutter/material.dart';

import '../models/stand_categories.dart';

/// What the organiser chose in [StandEditorSheet].
class StandEdit {
  final String label;
  final String category;

  /// Null when the sheet was opened without a description field.
  final String? description;
  final bool delete;

  const StandEdit(this.label, this.category, {this.description, this.delete = false});

  static const deleted = StandEdit('', '', delete: true);
}

/// Bottom sheet to name a stand and pick its category. Used by the market
/// builder and the market editor.
class StandEditorSheet extends StatefulWidget {
  final String label;
  final String category;

  /// Shows a description field when not null.
  final String? description;
  final bool isNew;

  const StandEditorSheet({
    super.key,
    required this.label,
    required this.category,
    this.description,
    this.isNew = false,
  });

  @override
  State<StandEditorSheet> createState() => _StandEditorSheetState();
}

class _StandEditorSheetState extends State<StandEditorSheet> {
  late final _label = TextEditingController(text: widget.label);
  late final _description = TextEditingController(text: widget.description);
  late String _category = widget.category;

  @override
  void dispose() {
    _label.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
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
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  hintText: 'z. B. Stand 14 · Crêpes, Waffeln, Kinderpunsch',
                ),
              ),
            ],
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
                    onPressed: () => Navigator.pop(context, StandEdit.deleted),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final label = _label.text.trim();
                    if (label.isEmpty) return;
                    Navigator.pop(
                      context,
                      StandEdit(
                        label,
                        _category,
                        description: widget.description == null ? null : _description.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
