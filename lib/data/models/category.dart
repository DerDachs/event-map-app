import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc, SnapshotOptions? options) {
    final data = doc.data()!;
    return Category(
      id: doc.id,
      name: data['name'],
      icon: data['icon'] != null
          ? IconData(data['icon'], fontFamily: 'MaterialIcons')
          : null,
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

  factory Category.generic() {
    return Category(id: 'default', name: 'Default Category', type: 'stand');
  }
}
