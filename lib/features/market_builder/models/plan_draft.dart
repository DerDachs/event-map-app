import '../services/georeference.dart';

/// A stand found on the plan (or added by the organiser) before it is saved.
class DraftStand {
  final String id;
  String label;
  String? number;
  String category;
  PlanPoint position;

  /// 'low', 'medium' or 'high'. Stands the organiser touched count as high.
  String confidence;

  DraftStand({
    required this.id,
    required this.label,
    required this.category,
    required this.position,
    this.number,
    this.confidence = 'high',
  });

  factory DraftStand.fromAnalysis(Map<String, dynamic> map, int index) => DraftStand(
        id: 'stand_$index',
        label: map['label'] as String? ?? 'Stand ${index + 1}',
        number: map['number'] as String?,
        category: map['category'] as String? ?? 'other',
        position: PlanPoint((map['x'] as num).toDouble(), (map['y'] as num).toDouble()),
        confidence: map['confidence'] as String? ?? 'medium',
      );
}

/// Everything the market builder collects before saving.
class PlanDraft {
  final String storagePath;
  final String imageUrl;
  final double aspectRatio;
  final String? marketName;
  final String? locationHint;
  final List<String> warnings;
  final List<DraftStand> stands;
  final List<ControlPoint> controlPoints;
  final GeoPoint? center;

  PlanDraft({
    required this.storagePath,
    required this.imageUrl,
    required this.aspectRatio,
    required this.marketName,
    required this.locationHint,
    required this.warnings,
    required this.stands,
    required this.controlPoints,
    required this.center,
  });
}
