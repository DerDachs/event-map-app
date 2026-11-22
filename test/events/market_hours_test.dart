import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/data/models/event.dart';
import 'package:market_mates/features/events/logic/market_hours.dart';

Event _market({List<OpeningHour>? hours}) => Event(
      id: 'm',
      name: 'Markt',
      description: '',
      startTime: DateTime(2026, 11, 23, 12),
      endTime: DateTime(2026, 12, 23, 12),
      latitude: 0,
      longitude: 0,
      category: 'christmas',
      teamIds: const [],
      images: const [],
      stands: const [],
      openingHours: hours,
    );

void main() {
  final hours = [
    OpeningHour(days: ['Mo', 'Di', 'Mi', 'Do'], open: '11:00', close: '21:00'),
    OpeningHour(days: ['Fr', 'Sa'], open: '11:00', close: '22:00'),
  ];

  test('open now shows the closing time', () {
    final s = todayHours(_market(hours: hours), DateTime(2026, 11, 24, 18, 30)); // Tuesday
    expect(s, isA<OpenNow>());
    expect((s as OpenNow).close, '21:00');
  });

  test('before opening shows the opening time', () {
    final s = todayHours(_market(hours: hours), DateTime(2026, 11, 28, 9, 5)); // Saturday
    expect(s, isA<OpensLater>());
    expect((s as OpensLater).open, '11:00');
  });

  test('after closing or on a day without hours is closed', () {
    expect(todayHours(_market(hours: hours), DateTime(2026, 11, 24, 21, 30)), isA<ClosedToday>());
    expect(todayHours(_market(hours: hours), DateTime(2026, 11, 29, 12)), isA<ClosedToday>()); // Sunday
  });

  test('outside the market dates it is not running', () {
    expect(todayHours(_market(hours: hours), DateTime(2026, 11, 22, 12)), isA<NotRunning>());
    expect(todayHours(_market(hours: hours), DateTime(2026, 12, 24, 12)), isA<NotRunning>());
  });

  test('without hours nothing is claimed', () {
    expect(todayHours(_market(), DateTime(2026, 11, 24, 12)), isA<HoursUnknown>());
  });
}
