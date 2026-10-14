import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../models/season.dart';

/// Seasons for the start page (`seasons` collection, written by admins).
class SeasonService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SeasonService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _seasons => _firestore.collection('seasons');

  /// All seasons, earliest first. There are only a few per year.
  Stream<List<Season>> watchAll() => _seasons
      .orderBy('startsAt')
      .snapshots()
      .map((s) => s.docs.map(Season.fromFirestore).toList());

  Future<void> save(Season season) {
    final data = {
      ...season.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    };
    return season.id.isEmpty ? _seasons.add(data) : _seasons.doc(season.id).set(data);
  }

  Future<void> delete(String id) => _seasons.doc(id).delete();

  /// Adds the example seasons from assets/seasons/ that aren't in Firestore
  /// yet. Returns how many were added.
  Future<int> importExamples({String asset = 'assets/seasons/seasons.json'}) async {
    final list = jsonDecode(await rootBundle.loadString(asset)) as List;
    var added = 0;
    for (final raw in list.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      final id = map.remove('id') as String;
      final ref = _seasons.doc(id);
      if ((await ref.get()).exists) continue;
      await ref.set({
        ...Season.fromMap(id, map).toFirestore(),
        'source': 'example',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      added++;
    }
    return added;
  }
}
