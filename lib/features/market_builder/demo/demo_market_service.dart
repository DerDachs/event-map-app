import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

import '../models/stand_categories.dart';
import 'demo_market.dart';

/// Writes the example market (see demo_market.dart) to Firestore.
///
/// All documents have fixed IDs, so running it again refreshes the dates and
/// texts instead of creating a second copy. Admin only (security rules).
class DemoMarketService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  DemoMarketService({FirebaseFirestore? firestore, FirebaseStorage? storage, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Creates or refreshes the example market and returns its event ID.
  Future<String> createOrRefresh({DateTime? now}) async {
    final market = buildDemoMarket(now ?? DateTime.now());
    final coverUrl = await _uploadCover();

    final batch = _firestore.batch();
    for (final stand in market.stands) {
      final category = standCategoryFor(stand.category);
      batch.set(_firestore.collection('stands').doc(stand.id), {
        'name': stand.name,
        'description': stand.description,
        'category': category.key,
        'images': <Map<String, dynamic>>[],
        'menu': stand.menu,
        'promotions': stand.promotion,
        'isDemo': true,
      });
    }
    for (final key in market.categories) {
      final category = standCategoryFor(key);
      batch.set(
        _firestore.collection('category').doc(key),
        {'name': category.name, 'icon': category.icon.codePoint, 'type': 'stand'},
        SetOptions(merge: true),
      );
    }

    batch.set(_firestore.collection('events').doc(market.id), {
      'name': market.name,
      'description': market.description,
      'startTime': Timestamp.fromDate(market.start),
      'endTime': Timestamp.fromDate(market.end),
      'latitude': market.latitude,
      'longitude': market.longitude,
      'category': 'christmas_market',
      'teamIds': <String>[],
      'participants': <String>[],
      'images': [
        {'url': coverUrl, 'isStandard': true},
      ],
      'stands': [
        for (final s in market.stands)
          {
            'standId': s.id,
            'category': s.category,
            'location': {'latitude': s.latitude, 'longitude': s.longitude},
          },
      ],
      'categories': market.categories.toList(),
      'openingHours': [
        for (final h in market.openingHours) {'days': h.days, 'open': h.open, 'close': h.close},
      ],
      'organizerName': market.organizerName,
      'organizerInfo': market.organizerInfo,
      'ticketPrice': market.ticketPrice,
      'eventTip': market.eventTip,
      // No site plan on purpose: nothing to ask anybody about.
      'isDemo': true,
      'createdBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return market.id;
  }

  /// Removes the example market and its stands again.
  Future<void> remove() async {
    final market = buildDemoMarket(DateTime.now());
    final batch = _firestore.batch();
    for (final stand in market.stands) {
      batch.delete(_firestore.collection('stands').doc(stand.id));
    }
    batch.delete(_firestore.collection('events').doc(market.id));
    await batch.commit();
  }

  Future<String> _uploadCover() async {
    final bytes = await rootBundle.load('assets/demo/lichterdorf.jpg');
    final ref = _storage.ref('demo/lichterdorf.jpg');
    await ref.putData(bytes.buffer.asUint8List(), SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
