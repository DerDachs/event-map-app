import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../data/models/event.dart';
import '../models/plan_draft.dart';
import '../models/event_import.dart';
import '../models/stand_categories.dart';
import 'georeference.dart';

class MarketBuilderService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  MarketBuilderService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west3'),
        _auth = auth ?? FirebaseAuth.instance;

  /// Uploads the plan image and returns its storage path and download URL.
  Future<(String, String)> uploadPlan(Uint8List bytes, String contentType) async {
    final uid = _auth.currentUser!.uid;
    final extension = contentType.split('/').last.replaceAll('jpeg', 'jpg'); // png, jpg, webp, pdf
    final path = 'market-plans/$uid/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return (path, await ref.getDownloadURL());
  }

  /// Lets the Cloud Function read the plan with Claude and geocode its
  /// landmarks. Takes up to a few minutes for large plans.
  Future<PlanDraft> analyzePlan({
    required String storagePath,
    required String imageUrl,
    required double aspectRatio,
    String? locationHint,
    String? pdfStoragePath,
    int? pdfPage,
  }) async {
    final callable = _functions.httpsCallable(
      'analyzeMarketPlan',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
    );
    final result = await callable.call<Map<String, dynamic>>({
      'storagePath': storagePath,
      'locationHint': locationHint,
      if (pdfStoragePath != null) 'pdfStoragePath': pdfStoragePath,
      if (pdfPage != null) 'pdfPage': pdfPage,
    });
    final data = Map<String, dynamic>.from(result.data);
    final analysis = Map<String, dynamic>.from(data['analysis'] as Map);
    final stands = (analysis['stands'] as List)
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();
    final center = data['center'] == null ? null : Map<String, dynamic>.from(data['center'] as Map);

    return PlanDraft(
      storagePath: storagePath,
      imageUrl: imageUrl,
      aspectRatio: aspectRatio,
      marketName: analysis['marketName'] as String?,
      locationHint: locationHint ?? analysis['locationHint'] as String?,
      warnings: List<String>.from(analysis['warnings'] as List? ?? const []),
      stands: [for (var i = 0; i < stands.length; i++) DraftStand.fromAnalysis(stands[i], i)],
      controlPoints: (data['controlPoints'] as List? ?? const [])
          .map((p) => ControlPoint.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
      center: center == null
          ? null
          : GeoPoint(
              (center['latitude'] as num).toDouble(),
              (center['longitude'] as num).toDouble(),
            ),
    );
  }

  /// Reads listing details and images from the event's web page.
  Future<EventImport> importFromUrl(String url) async {
    final callable = _functions.httpsCallable(
      'importEventFromUrl',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
    );
    final result = await callable.call<Map<String, dynamic>>({'url': url});
    return EventImport.fromMap(Map<String, dynamic>.from(result.data));
  }

  /// Writes the market as an event with its stands, in the format the
  /// visitor screens read (see StandService.fetchStandsForEvent).
  Future<String> saveMarket({
    required PlanDraft draft,
    required Georeference georeference,
    required String name,
    required String description,
    required DateTime start,
    required DateTime end,
    List<String> imageUrls = const [],
    List<OpeningHour> openingHours = const [],
    String? ticketPrice,
    String? organizerName,
    String? organizerInfo,
    String? eventTip,
    String? websiteUrl,
  }) async {
    final batch = _firestore.batch();
    final eventRef = _firestore.collection('events').doc();
    final usedCategories = <String>{};
    final eventStands = <Map<String, dynamic>>[];

    for (final stand in draft.stands) {
      final standRef = _firestore.collection('stands').doc();
      final category = standCategoryFor(stand.category);
      usedCategories.add(category.key);
      batch.set(standRef, {
        'name': stand.label,
        'description': stand.number == null ? category.name : 'Stand ${stand.number} · ${category.name}',
        'category': category.key,
        'images': <Map<String, dynamic>>[],
        'menu': <String>[],
        'promotions': null,
      });
      final geo = georeference.toGeo(stand.position);
      eventStands.add({
        'standId': standRef.id,
        'category': category.key,
        'location': {'latitude': geo.latitude, 'longitude': geo.longitude},
        'plan': {'x': stand.position.x, 'y': stand.position.y},
      });
    }

    // The visitor map reads categories from the `category` collection.
    for (final key in usedCategories) {
      final category = standCategoryFor(key);
      batch.set(
        _firestore.collection('category').doc(key),
        {'name': category.name, 'icon': category.icon.codePoint, 'type': 'stand'},
        SetOptions(merge: true),
      );
    }

    final overlay = georeference.overlay();
    batch.set(eventRef, {
      'name': name,
      'description': description,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(end),
      'latitude': overlay.center.latitude,
      'longitude': overlay.center.longitude,
      'category': 'christmas_market',
      'teamIds': <String>[],
      'participants': <String>[],
      // Pictures from the web page come first; the plan is the fallback cover.
      'images': [
        for (var i = 0; i < imageUrls.length; i++) {'url': imageUrls[i], 'isStandard': i == 0},
        {'url': draft.imageUrl, 'isStandard': imageUrls.isEmpty},
      ],
      'stands': eventStands,
      'categories': usedCategories.toList(),
      'openingHours': openingHours.map((h) => h.toFirestore()).toList(),
      'organizerName': organizerName ?? '',
      'ticketPrice': ticketPrice ?? '',
      'eventTip': eventTip ?? '',
      'organizerInfo': organizerInfo ?? '',
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'plan': {
        'storagePath': draft.storagePath,
        'imageUrl': draft.imageUrl,
        'aspectRatio': draft.aspectRatio,
        'controlPoints': georeference.usedPoints.map((p) => p.toMap()).toList(),
        'overlay': {
          'latitude': overlay.center.latitude,
          'longitude': overlay.center.longitude,
          'widthMeters': overlay.widthMeters,
          'heightMeters': overlay.heightMeters,
          'bearing': overlay.bearing,
        },
      },
      'createdBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return eventRef.id;
  }
}
