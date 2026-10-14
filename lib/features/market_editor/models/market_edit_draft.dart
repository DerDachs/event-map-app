import '../../../data/models/event.dart';
import '../../../data/models/eventImage.dart';
import '../../market_builder/models/stand_categories.dart';
import '../../market_builder/services/georeference.dart';

/// A stand of the market being edited.
class EditableStand {
  /// Document id in `stands`; null for stands added in the editor.
  final String? id;

  /// Stable key for markers and lists, also for new stands.
  final String key;

  String label;
  String description;
  String category;
  GeoPoint position;

  /// Extra keys of the event's `stands` entry (e.g. `plan`), kept on save.
  final Map<String, dynamic> extra;

  final String _originalLabel;
  final String _originalDescription;
  final String _originalCategory;

  EditableStand({
    required this.id,
    required this.key,
    required this.label,
    required this.description,
    required this.category,
    required this.position,
    this.extra = const {},
  })  : _originalLabel = label,
        _originalDescription = description,
        _originalCategory = category;

  bool get isNew => id == null;

  /// Whether the stand document needs writing.
  bool get documentChanged =>
      isNew ||
      label != _originalLabel ||
      description != _originalDescription ||
      category != _originalCategory;

  StandCategory get standCategory => standCategoryFor(category);
}

/// Everything the market editor can change, loaded from the event document.
class MarketEditDraft {
  final String eventId;

  String name;
  String description;
  DateTime start;
  DateTime end;
  List<OpeningHour> openingHours;
  String ticketPrice;
  String organizerName;
  String organizerInfo;
  String eventTip;
  String websiteUrl;
  List<EventImage> images;

  final List<EditableStand> stands;

  /// Stands removed in the editor that already existed.
  final List<EditableStand> removedStands = [];

  /// Set for markets created from a site plan: maps between plan and map.
  final Georeference? georeference;
  final String? planImageUrl;
  final PlanOverlay? planOverlay;

  /// Markets from the market builder own their stand documents, so removed
  /// stands are deleted. Older, hand-made markets may share stands.
  bool get ownsStandDocuments => planImageUrl != null;

  MarketEditDraft({
    required this.eventId,
    required this.name,
    required this.description,
    required this.start,
    required this.end,
    required this.openingHours,
    required this.ticketPrice,
    required this.organizerName,
    required this.organizerInfo,
    required this.eventTip,
    required this.websiteUrl,
    required this.images,
    required this.stands,
    this.georeference,
    this.planImageUrl,
    this.planOverlay,
  });

  int _nextKey = 0;
  String newKey() => 'new_${_nextKey++}';

  void removeStand(EditableStand stand) {
    stands.remove(stand);
    if (!stand.isNew) removedStands.add(stand);
  }
}

/// "Stand 14 · Herzhaftes" → "Stand 14 · Süßes & Gebäck" when the category
/// changes. Descriptions the organiser wrote themselves stay as they are.
String updateCategoryInDescription(String description, StandCategory from, StandCategory to) {
  if (description == from.name) return to.name;
  final suffix = ' · ${from.name}';
  if (description.endsWith(suffix)) {
    return '${description.substring(0, description.length - suffix.length)} · ${to.name}';
  }
  return description;
}
