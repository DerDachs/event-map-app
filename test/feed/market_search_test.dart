import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/data/models/event.dart';
import 'package:market_mates/features/feed/logic/home_feed.dart';

Event _market(String name, DateTime start, DateTime end, {String? organizer}) => Event(
      id: name,
      name: name,
      description: '',
      startTime: start,
      endTime: end,
      latitude: 0,
      longitude: 0,
      category: 'christmas_market',
      teamIds: const [],
      images: const [],
      stands: const [],
      organizerName: organizer,
    );

void main() {
  final now = DateTime(2026, 11, 23, 12);
  final events = [
    _market('Altstadt-Weihnachtsmarkt', DateTime(2025, 11, 20), DateTime(2025, 12, 23)),
    _market('Lichterdorf Musterstadt', DateTime(2026, 11, 26), DateTime(2026, 12, 23)),
    _market('Weinfest am Fluss', DateTime(2026, 9, 1), DateTime(2026, 9, 5)),
    _market('Winterzauber', DateTime(2026, 11, 20), DateTime(2026, 12, 30), organizer: 'Stadt Altstadt'),
  ];

  test('empty query finds nothing', () {
    expect(matchingMarkets(events, '  ', now), isEmpty);
  });

  test('matches name and organiser, ignores case', () {
    expect(matchingMarkets(events, 'ALTSTADT', now).map((e) => e.name),
        ['Winterzauber', 'Altstadt-Weihnachtsmarkt']);
  });

  test('running and upcoming before past markets', () {
    expect(matchingMarkets(events, 'e', now).map((e) => e.name).toList(), [
      'Winterzauber',
      'Lichterdorf Musterstadt',
      'Altstadt-Weihnachtsmarkt',
      'Weinfest am Fluss',
    ]);
  });
}
