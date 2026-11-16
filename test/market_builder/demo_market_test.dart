import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/market_builder/demo/demo_market.dart';
import 'package:market_mates/features/market_builder/models/plan_consent.dart';
import 'package:market_mates/features/market_builder/models/stand_categories.dart';

void main() {
  final now = DateTime(2026, 11, 15, 14);
  final market = buildDemoMarket(now);

  group('demo market', () {
    test('is running around the given day', () {
      expect(market.start.isBefore(now), isTrue);
      expect(market.end.isAfter(now.add(const Duration(days: 20))), isTrue);
    });

    test('has unique stand ids and names', () {
      expect({for (final s in market.stands) s.id}.length, market.stands.length);
      expect({for (final s in market.stands) s.name}.length, market.stands.length);
    });

    test('uses only known stand categories and shows every one but none is empty', () {
      final known = {for (final c in standCategories) c.key};
      expect(market.categories.difference(known), isEmpty);
      // The principle needs variety: at least six of the nine categories.
      expect(market.categories.length, greaterThanOrEqualTo(6));
    });

    test('keeps all stands on one square, within 100 m of the centre', () {
      for (final s in market.stands) {
        expect((s.latitude - market.latitude).abs() * 111320, lessThan(100), reason: s.name);
        expect((s.longitude - market.longitude).abs() * 111320 * 0.62, lessThan(100), reason: s.name);
      }
    });

    test('does not place two stands on top of each other', () {
      for (var i = 0; i < market.stands.length; i++) {
        for (var j = i + 1; j < market.stands.length; j++) {
          final a = market.stands[i];
          final b = market.stands[j];
          final distance = (a.eastMeters - b.eastMeters).abs() + (a.northMeters - b.northMeters).abs();
          expect(distance, greaterThanOrEqualTo(10), reason: '${a.name} / ${b.name}');
        }
      }
    });

    test('is searchable for crêpes, the example in the store texts', () {
      final hit = market.stands.where(
        (s) => s.menu.any((m) => m.contains('Crêpes')) || s.name.contains('Crêpes'),
      );
      expect(hit, isNotEmpty);
    });
  });

  group('plan consent', () {
    test('record carries version, user and time', () {
      final record = planConsentRecord(uid: 'u1', at: 'now');
      expect(record, {'granted': true, 'version': planConsentVersion, 'at': 'now', 'by': 'u1'});
    });

    test('request says granted for the current version', () {
      expect(planConsentRequest(), {'granted': true, 'version': planConsentVersion});
    });

    test('hasPlanConsent only accepts a granted record with a version', () {
      expect(hasPlanConsent({'planConsent': planConsentRequest()}), isTrue);
      expect(hasPlanConsent(<String, Object?>{}), isFalse);
      expect(hasPlanConsent(null), isFalse);
      expect(hasPlanConsent({'planConsent': {'granted': false, 'version': 1}}), isFalse);
      expect(hasPlanConsent({'planConsent': {'granted': true}}), isFalse);
    });
  });
}
