import 'package:flutter/material.dart';

import '../../../data/models/category.dart';
import '../../../l10n/l10n.dart';
import '../../market_builder/models/stand_categories.dart';

/// How a stand category looks on the map, in the list and in the detail sheet.
class StandStyle {
  final String key;
  final String name;
  final IconData icon;
  final Color color;

  const StandStyle(this.key, this.name, this.icon, this.color);
}

/// Style for category [key]: the built-in categories first, then categories
/// stored for the market, else "other".
StandStyle standStyleFor(BuildContext context, String? key, Map<String, Category> fromFirestore) {
  final builtIn = standCategories.where((c) => c.key == key);
  if (builtIn.isNotEmpty) {
    final c = builtIn.first;
    return StandStyle(c.key, context.l10n.standCategoryName(c), c.icon, c.color);
  }
  final doc = fromFirestore[key];
  if (doc != null) {
    return StandStyle(doc.id, doc.name, doc.icon ?? Icons.storefront, const Color(0xFF6D4C41));
  }
  final other = standCategories.last;
  return StandStyle(key ?? other.key, context.l10n.standCategoryName(other), other.icon, other.color);
}
