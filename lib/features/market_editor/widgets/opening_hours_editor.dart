import 'package:flutter/material.dart';

import '../../../data/models/event.dart';

const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// Rows of "days + from–to", in the format the web import produces
/// (days Mo…So, times HH:mm).
class OpeningHoursEditor extends StatelessWidget {
  final List<OpeningHour> hours;
  final ValueChanged<List<OpeningHour>> onChanged;

  const OpeningHoursEditor({super.key, required this.hours, required this.onChanged});

  void _replace(int index, OpeningHour hour) {
    onChanged([...hours]..[index] = hour);
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 11, minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 11, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(picked.hour)}:${two(picked.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < hours.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final day in weekdays)
                        FilterChip(
                          label: Text(day),
                          visualDensity: VisualDensity.compact,
                          selected: hours[i].days.contains(day),
                          onSelected: (on) {
                            final days = {...hours[i].days};
                            on ? days.add(day) : days.remove(day);
                            _replace(
                              i,
                              OpeningHour(
                                days: weekdays.where(days.contains).toList(),
                                open: hours[i].open,
                                close: hours[i].close,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final t = await _pickTime(context, hours[i].open);
                          if (t != null) {
                            _replace(i, OpeningHour(days: hours[i].days, open: t, close: hours[i].close));
                          }
                        },
                        child: Text(hours[i].open.isEmpty ? 'von' : hours[i].open),
                      ),
                      const Text('–'),
                      TextButton(
                        onPressed: () async {
                          final t = await _pickTime(context, hours[i].close);
                          if (t != null) {
                            _replace(i, OpeningHour(days: hours[i].days, open: hours[i].open, close: t));
                          }
                        },
                        child: Text(hours[i].close.isEmpty ? 'bis' : hours[i].close),
                      ),
                      const Text('Uhr'),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Zeile entfernen',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onChanged([...hours]..removeAt(i)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Öffnungszeiten hinzufügen'),
            onPressed: () => onChanged([
              ...hours,
              OpeningHour(days: const [], open: '11:00', close: '21:00'),
            ]),
          ),
        ),
      ],
    );
  }
}
