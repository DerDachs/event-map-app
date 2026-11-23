import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/market_builder/logic/stand_list.dart';

void main() {
  const stands = [
    MatchTarget(id: 'a', label: 'Stand 7', number: '07'),
    MatchTarget(id: 'b', label: 'Crêpes & Waffeln'),
    MatchTarget(id: 'c', label: 'Glühwein Hütte', number: 'B3'),
    MatchTarget(id: 'd', label: 'Crêpes'),
  ];

  test('numbers match without prefixes and leading zeros', () {
    expect(normalizeStandNumber('Nr. 07'), '7');
    expect(normalizeStandNumber('Stand B-3'), 'b3');
    final r = matchStandList(const [
      StandListEntry(name: 'Holzspielzeug Maier', number: '7'),
      StandListEntry(name: 'Feuerzangenbowle', number: 'b3'),
    ], stands);
    expect(r, ['a', 'c']);
  });

  test('names match exactly before partly, each stand once', () {
    final r = matchStandList(const [
      StandListEntry(name: 'Crêpes'),
      StandListEntry(name: 'Crepes und Waffeln'),
      StandListEntry(name: 'Unbekannt'),
    ], stands);
    expect(r[0], 'd');
    expect(r[2], isNull);
  });

  test('ambiguous numbers are left for the organiser', () {
    final r = matchStandList(const [StandListEntry(name: 'X', number: '1')], const [
      MatchTarget(id: 'x', label: 'Stand', number: '1'),
      MatchTarget(id: 'y', label: 'Stand', number: '01'),
    ]);
    expect(r, [null]);
  });

  test('reads the function result', () {
    final e = StandListEntry.fromMap({
      'number': ' 12 ',
      'name': 'Waffelhaus',
      'description': 'Frische Waffeln.',
      'category': 'food_sweet',
      'offer': ['Waffeln', ' ', 'Kakao'],
      'promotion': null,
    });
    expect(e.number, '12');
    expect(e.offer, ['Waffeln', 'Kakao']);
  });
}
