/// One stand from an imported stand list (see the Cloud Function parseStandList).
class StandListEntry {
  final String? number;
  final String name;
  final String? description;
  final String category;
  final List<String> offer;
  final String? promotion;

  const StandListEntry({
    required this.name,
    this.number,
    this.description,
    this.category = 'other',
    this.offer = const [],
    this.promotion,
  });

  factory StandListEntry.fromMap(Map<String, dynamic> m) => StandListEntry(
        number: (m['number'] as String?)?.trim().isEmpty ?? true ? null : (m['number'] as String).trim(),
        name: (m['name'] as String? ?? '').trim(),
        description: (m['description'] as String?)?.trim(),
        category: m['category'] as String? ?? 'other',
        offer: [
          for (final o in (m['offer'] as List? ?? const []))
            if (o is String && o.trim().isNotEmpty) o.trim(),
        ],
        promotion: (m['promotion'] as String?)?.trim(),
      );
}

/// What a stand on the plan offers for matching.
class MatchTarget {
  final String id;
  final String? number;
  final String label;

  const MatchTarget({required this.id, required this.label, this.number});
}

/// Stand numbers compare without "Stand"/"Nr." and leading zeros: "Nr. 07" = "7".
String normalizeStandNumber(String raw) {
  var s = raw.toLowerCase().replaceAll(RegExp(r'stand|nr\.?|no\.?|#'), '');
  s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  return s.replaceFirst(RegExp(r'^0+(?=\d)'), '');
}

String _normalizeName(String raw) => raw
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[àâá]'), 'a')
    .replaceAll(RegExp('[ôó]'), 'o')
    .replaceAll(RegExp('[îí]'), 'i')
    .replaceAll(RegExp('[ûú]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Pairs list entries with stands: first by stand number, then by name
/// (equal or one containing the other). Each stand is used at most once.
/// Returns, per entry in order, the id of its stand or null.
List<String?> matchStandList(List<StandListEntry> entries, List<MatchTarget> stands) {
  final result = List<String?>.filled(entries.length, null);
  final used = <String>{};

  final byNumber = <String, List<MatchTarget>>{};
  for (final s in stands) {
    if (s.number == null) continue;
    byNumber.putIfAbsent(normalizeStandNumber(s.number!), () => []).add(s);
  }
  for (var i = 0; i < entries.length; i++) {
    final n = entries[i].number;
    if (n == null) continue;
    final candidates = byNumber[normalizeStandNumber(n)] ?? const [];
    final free = candidates.where((s) => !used.contains(s.id)).toList();
    if (free.length == 1) {
      result[i] = free.single.id;
      used.add(free.single.id);
    }
  }

  // Exact names before partial ones, so "Crêpes" doesn't take "Crêpes & Waffeln"'s stand.
  for (final exact in const [true, false]) {
    for (var i = 0; i < entries.length; i++) {
      if (result[i] != null) continue;
      final name = _normalizeName(entries[i].name);
      if (name.length < 3) continue;
      final hits = stands.where((s) {
        if (used.contains(s.id)) return false;
        final label = _normalizeName(s.label);
        if (label.length < 3) return false;
        return exact ? label == name : (label.length >= 4 && name.length >= 4) && (label.contains(name) || name.contains(label));
      }).toList();
      if (hits.length == 1) {
        result[i] = hits.single.id;
        used.add(hits.single.id);
      }
    }
  }
  return result;
}
