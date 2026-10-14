import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../data/models/event.dart';
import '../../../data/models/eventImage.dart';
import '../../market_builder/models/stand_categories.dart';
import '../../market_builder/services/georeference.dart';
import '../../seasons/models/market_types.dart';
import '../models/market_edit_draft.dart';

/// Loads a market for the admin editor and writes the changes back in the
/// format the visitor screens and the market builder use.
class MarketEditService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  MarketEditService({FirebaseFirestore? firestore, FirebaseStorage? storage, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<MarketEditDraft> load(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    final data = doc.data();
    if (data == null) throw Exception('Markt nicht gefunden');
    final event = Event.fromFirestore(doc, null);

    final entries = (data['stands'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .where((m) => m['standId'] is String && m['location'] is Map)
        .toList();
    final standDocs = await Future.wait(
        entries.map((e) => _firestore.collection('stands').doc(e['standId'] as String).get()));

    final stands = <EditableStand>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final standData = standDocs[i].data() ?? const <String, dynamic>{};
      final location = Map<String, dynamic>.from(entry['location'] as Map);
      final id = entry['standId'] as String;
      stands.add(EditableStand(
        id: id,
        key: id,
        label: standData['name'] as String? ?? '',
        description: standData['description'] as String? ?? '',
        category: standCategoryFor(entry['category'] as String? ?? standData['category'] as String?).key,
        position: GeoPoint(
          (location['latitude'] as num).toDouble(),
          (location['longitude'] as num).toDouble(),
        ),
        extra: {
          for (final e in entry.entries)
            if (!const {'standId', 'category', 'location'}.contains(e.key)) e.key: e.value,
        },
      ));
    }

    final plan = data['plan'] is Map ? Map<String, dynamic>.from(data['plan'] as Map) : null;
    Georeference? georeference;
    PlanOverlay? overlay;
    if (plan != null) {
      final points = (plan['controlPoints'] as List? ?? const [])
          .whereType<Map>()
          .map((p) => ControlPoint.fromMap(Map<String, dynamic>.from(p)))
          .toList();
      final aspect = plan['aspectRatio'];
      if (aspect is num) georeference = Georeference.fit(points, aspectRatio: aspect.toDouble());
      final o = event.plan;
      if (o != null) {
        overlay = PlanOverlay(
          center: GeoPoint(o.latitude, o.longitude),
          widthMeters: o.widthMeters,
          heightMeters: o.heightMeters,
          bearing: o.bearing,
        );
      }
    }

    return MarketEditDraft(
      eventId: eventId,
      name: event.name,
      description: event.description,
      marketType: marketTypeFor(event.category).key,
      start: event.startTime,
      end: event.endTime,
      openingHours: [...?event.openingHours],
      ticketPrice: event.ticketPrice ?? '',
      organizerName: event.organizerName ?? '',
      organizerInfo: event.organizerInfo ?? '',
      eventTip: event.eventTip ?? '',
      websiteUrl: data['websiteUrl'] as String? ?? '',
      images: [...event.images],
      stands: stands,
      georeference: georeference,
      planImageUrl: plan?['imageUrl'] as String?,
      planOverlay: overlay,
    );
  }

  /// The plan image, for drawing it under the stands on the map.
  Future<Uint8List?> loadPlanImage(String url) =>
      _storage.refFromURL(url).getData(15 * 1024 * 1024);

  Future<String> uploadImage(String eventId, Uint8List bytes) async {
    final ref = _storage.ref('event-images/$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> save(MarketEditDraft draft) async {
    final writes = <void Function(WriteBatch)>[];
    final eventStands = <Map<String, dynamic>>[];
    final usedCategories = <String>{};

    for (final stand in draft.stands) {
      final category = standCategoryFor(stand.category);
      usedCategories.add(category.key);
      final ref = stand.id == null
          ? _firestore.collection('stands').doc()
          : _firestore.collection('stands').doc(stand.id);
      if (stand.isNew) {
        writes.add((b) => b.set(ref, {
              'name': stand.label,
              'description': stand.description,
              'category': category.key,
              'images': <Map<String, dynamic>>[],
              'menu': <String>[],
              'promotions': null,
            }));
      } else if (stand.documentChanged) {
        writes.add((b) => b.update(ref, {
              'name': stand.label,
              'description': stand.description,
              'category': category.key,
            }));
      }
      final planPoint = draft.georeference?.toPlan(stand.position);
      eventStands.add({
        ...stand.extra,
        'standId': ref.id,
        'category': category.key,
        'location': {'latitude': stand.position.latitude, 'longitude': stand.position.longitude},
        if (planPoint != null) 'plan': {'x': planPoint.x, 'y': planPoint.y},
      });
    }

    if (draft.ownsStandDocuments) {
      for (final stand in draft.removedStands) {
        writes.add((b) => b.delete(_firestore.collection('stands').doc(stand.id)));
      }
    }

    for (final key in usedCategories) {
      final category = standCategoryFor(key);
      writes.add((b) => b.set(
            _firestore.collection('category').doc(key),
            {'name': category.name, 'icon': category.icon.codePoint, 'type': 'stand'},
            SetOptions(merge: true),
          ));
    }

    // Only the fields the editor owns, so visitors joining at the same time
    // (participants, teamIds) are not overwritten.
    final eventUpdate = {
      'name': draft.name,
      'description': draft.description,
      'category': draft.marketType,
      'startTime': Timestamp.fromDate(draft.start),
      'endTime': Timestamp.fromDate(draft.end),
      'openingHours': draft.openingHours.map((h) => h.toFirestore()).toList(),
      'ticketPrice': draft.ticketPrice,
      'organizerName': draft.organizerName,
      'organizerInfo': draft.organizerInfo,
      'eventTip': draft.eventTip,
      'websiteUrl': draft.websiteUrl.isEmpty ? FieldValue.delete() : draft.websiteUrl,
      'images': _withCover(draft.images).map((i) => i.toFirestore()).toList(),
      'stands': eventStands,
      'categories': usedCategories.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    };

    // A batch takes at most 500 writes. Stand documents go first so the event
    // never points at stands that don't exist yet.
    const chunk = 450;
    for (var i = 0; i < writes.length; i += chunk) {
      final batch = _firestore.batch();
      for (final write in writes.skip(i).take(chunk)) {
        write(batch);
      }
      await batch.commit();
    }
    await _firestore.collection('events').doc(draft.eventId).update(eventUpdate);
  }

  /// Deletes the market and, for markets from the market builder, its stands.
  Future<void> delete(MarketEditDraft draft) async {
    final standIds = draft.ownsStandDocuments
        ? [...draft.stands, ...draft.removedStands].map((s) => s.id).whereType<String>().toList()
        : const <String>[];
    await _firestore.collection('events').doc(draft.eventId).delete();
    for (var i = 0; i < standIds.length; i += 450) {
      final batch = _firestore.batch();
      for (final id in standIds.skip(i).take(450)) {
        batch.delete(_firestore.collection('stands').doc(id));
      }
      await batch.commit();
    }
  }

  /// Exactly one cover image (the first marked one, else the first image).
  static List<EventImage> _withCover(List<EventImage> images) {
    if (images.isEmpty) return images;
    final cover = images.indexWhere((i) => i.isStandard);
    final coverIndex = cover < 0 ? 0 : cover;
    return [
      for (var i = 0; i < images.length; i++) EventImage(url: images[i].url, isStandard: i == coverIndex),
    ];
  }
}
