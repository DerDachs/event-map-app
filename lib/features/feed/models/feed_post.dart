import 'package:cloud_firestore/cloud_firestore.dart';

/// Kinds of editorial posts. The key is stored in Firestore.
enum FeedPostType {
  news('news', 'Neuigkeit'),
  opening('opening', 'Eröffnung'),
  tip('tip', 'Tipp'),
  event('event', 'Programm');

  final String key;
  final String label;

  const FeedPostType(this.key, this.label);

  static FeedPostType fromKey(String? key) =>
      values.firstWhere((t) => t.key == key, orElse: () => FeedPostType.news);
}

/// An editorial post on the start page, written by admins (`feed` collection).
class FeedPost {
  final String id;
  final FeedPostType type;
  final String title;
  final String body;
  final String? imageUrl;

  /// Market the post is about; opens its page when tapped.
  final String? eventId;
  final String? linkUrl;
  final String? linkLabel;

  /// Shown from this time on, so posts can be prepared in advance.
  final DateTime publishAt;

  /// Hidden after this time, e.g. once the market has opened.
  final DateTime? expiresAt;

  /// Pinned posts stay on top.
  final bool pinned;

  /// Only shown while this season runs; null = all year.
  final String? seasonId;

  /// English version (stored under `en`); empty fields fall back to German.
  final String titleEn;
  final String bodyEn;
  final String? linkLabelEn;

  const FeedPost({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.publishAt,
    this.imageUrl,
    this.eventId,
    this.linkUrl,
    this.linkLabel,
    this.expiresAt,
    this.pinned = false,
    this.seasonId,
    this.titleEn = '',
    this.bodyEn = '',
    this.linkLabelEn,
  });

  /// The post in [languageCode]; German is the original.
  FeedPost localized(String languageCode) {
    if (languageCode != 'en' || titleEn.isEmpty) return this;
    return FeedPost(
      id: id,
      type: type,
      title: titleEn,
      body: bodyEn.isEmpty ? body : bodyEn,
      imageUrl: imageUrl,
      eventId: eventId,
      linkUrl: linkUrl,
      linkLabel: linkLabelEn ?? linkLabel,
      publishAt: publishAt,
      expiresAt: expiresAt,
      pinned: pinned,
      seasonId: seasonId,
    );
  }

  bool isVisibleAt(DateTime now) =>
      !publishAt.isAfter(now) && (expiresAt == null || expiresAt!.isAfter(now));

  factory FeedPost.fromMap(String id, Map<String, dynamic> data) {
    DateTime? time(Object? v) => v is Timestamp ? v.toDate() : (v is String ? DateTime.tryParse(v) : null);
    String? text(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
    final en = data['en'] is Map ? Map<String, dynamic>.from(data['en'] as Map) : const <String, dynamic>{};
    return FeedPost(
      id: id,
      type: FeedPostType.fromKey(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      imageUrl: text(data['imageUrl']),
      eventId: text(data['eventId']),
      linkUrl: text(data['linkUrl']),
      linkLabel: text(data['linkLabel']),
      publishAt: time(data['publishAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: time(data['expiresAt']),
      pinned: data['pinned'] == true,
      seasonId: text(data['seasonId']),
      titleEn: en['title'] as String? ?? '',
      bodyEn: en['body'] as String? ?? '',
      linkLabelEn: text(en['linkLabel']),
    );
  }

  factory FeedPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      FeedPost.fromMap(doc.id, doc.data() ?? const {});

  Map<String, dynamic> toFirestore() => {
        'type': type.key,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'eventId': eventId,
        'linkUrl': linkUrl,
        'linkLabel': linkLabel,
        'publishAt': Timestamp.fromDate(publishAt),
        'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'pinned': pinned,
        'seasonId': seasonId,
        'en': {'title': titleEn, 'body': bodyEn, 'linkLabel': linkLabelEn},
      };
}
