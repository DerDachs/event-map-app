import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../models/feed_post.dart';

/// Editorial posts for the start page (`feed` collection, written by admins).
class FeedService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FeedService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _feed => _firestore.collection('feed');

  /// Published posts, newest first. Expired ones are filtered by the caller.
  Stream<List<FeedPost>> watchPublished({int limit = 40}) => _feed
      .where('publishAt', isLessThanOrEqualTo: Timestamp.now())
      .orderBy('publishAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(FeedPost.fromFirestore).toList());

  /// Every post including scheduled and expired ones, for the admin list.
  Stream<List<FeedPost>> watchAll() => _feed
      .orderBy('publishAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FeedPost.fromFirestore).toList());

  Future<void> save(FeedPost post) {
    final data = {
      ...post.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    };
    return post.id.isEmpty ? _feed.add(data) : _feed.doc(post.id).set(data);
  }

  Future<void> delete(String id) => _feed.doc(id).delete();

  /// Adds the example posts from assets/feed/ that aren't in Firestore yet.
  /// Returns how many were added.
  Future<int> importExamples({String asset = 'assets/feed/season_2026.json'}) async {
    final list = jsonDecode(await rootBundle.loadString(asset)) as List;
    var added = 0;
    for (final raw in list.whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      final id = map.remove('id') as String;
      final ref = _feed.doc(id);
      if ((await ref.get()).exists) continue;
      await ref.set({
        ...FeedPost.fromMap(id, map).toFirestore(),
        'source': 'example',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
      });
      added++;
    }
    return added;
  }
}
