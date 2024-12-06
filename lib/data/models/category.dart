import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData? icon;
  final String type;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
  });

  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'],
      icon: data['icon'] != null ? IconData(data['icon'], fontFamily: 'MaterialIcons') : null,
      type: data['type'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon?.codePoint,
      'type': type,
    };
  }
}