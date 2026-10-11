import 'package:flutter/material.dart';

/// Fixed stand categories the plan analysis assigns. The keys are shared with
/// the Cloud Function (functions/src/schema.ts) and are used as document IDs
/// in the `category` collection.
class StandCategory {
  final String key;
  final String name;
  final IconData icon;
  final Color color;

  const StandCategory(this.key, this.name, this.icon, this.color);
}

const standCategories = <StandCategory>[
  StandCategory('gluehwein', 'Glühwein & Heißgetränke', Icons.local_bar, Color(0xFFC62828)),
  StandCategory('food_savory', 'Herzhaftes', Icons.lunch_dining, Color(0xFFEF6C00)),
  StandCategory('food_sweet', 'Süßes & Gebäck', Icons.cake, Color(0xFFAD1457)),
  StandCategory('crafts', 'Handwerk & Geschenke', Icons.redeem, Color(0xFF2E7D32)),
  StandCategory('decoration', 'Weihnachtsdeko', Icons.star, Color(0xFFF9A825)),
  StandCategory('kids', 'Für Kinder', Icons.attractions, Color(0xFF6A1B9A)),
  StandCategory('stage', 'Bühne & Programm', Icons.theater_comedy, Color(0xFF1565C0)),
  StandCategory('service', 'Service', Icons.info, Color(0xFF455A64)),
  StandCategory('other', 'Sonstiges', Icons.storefront, Color(0xFF6D4C41)),
];

StandCategory standCategoryFor(String? key) => standCategories.firstWhere(
      (c) => c.key == key,
      orElse: () => standCategories.last,
    );
