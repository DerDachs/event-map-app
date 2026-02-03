class EventImage {
  final String url;
  final bool isStandard;

  EventImage({
    required this.url,
    required this.isStandard,
  });

  // Factory to create EventImage from Firestore data
  factory EventImage.fromMap(Map<String, dynamic> data) {
    return EventImage(
      url: data['url'],
      isStandard: data['isStandard'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'isStandard': isStandard,
    };
  }
  // Convert EventImage to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'isStandard': isStandard,
    };
  }
}