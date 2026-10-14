import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/market_builder/models/stand_categories.dart';
import 'package:market_mates/features/market_builder/services/georeference.dart';
import 'package:market_mates/features/market_editor/models/market_edit_draft.dart';

void main() {
  final savory = standCategoryFor('food_savory');
  final sweet = standCategoryFor('food_sweet');

  test('category change updates generated descriptions only', () {
    expect(updateCategoryInDescription('Stand 14 · Herzhaftes', savory, sweet), 'Stand 14 · Süßes & Gebäck');
    expect(updateCategoryInDescription('Herzhaftes', savory, sweet), 'Süßes & Gebäck');
    expect(updateCategoryInDescription('Die besten Bratwürste', savory, sweet), 'Die besten Bratwürste');
  });

  EditableStand stand(String? id) => EditableStand(
        id: id,
        key: id ?? 'new',
        label: 'Crêpes',
        description: 'Süßes & Gebäck',
        category: 'food_sweet',
        position: const GeoPoint(48.1, 11.5),
      );

  test('only real changes mark a stand document as changed', () {
    final s = stand('a');
    expect(s.documentChanged, isFalse);
    s.position = const GeoPoint(48.2, 11.5);
    expect(s.documentChanged, isFalse, reason: 'positions live on the event, not the stand');
    s.label = 'Crêpes & Waffeln';
    expect(s.documentChanged, isTrue);
    expect(stand(null).documentChanged, isTrue);
  });

  test('removing a stand remembers existing ones for deletion', () {
    final existing = stand('a');
    final added = stand(null);
    final draft = MarketEditDraft(
      eventId: 'e',
      name: 'Markt',
      description: '',
      start: DateTime(2026, 11, 26),
      end: DateTime(2026, 12, 23),
      openingHours: [],
      ticketPrice: '',
      organizerName: '',
      organizerInfo: '',
      eventTip: '',
      websiteUrl: '',
      images: [],
      stands: [existing, added],
    );
    draft
      ..removeStand(existing)
      ..removeStand(added);
    expect(draft.stands, isEmpty);
    expect(draft.removedStands, [existing]);
  });
}
