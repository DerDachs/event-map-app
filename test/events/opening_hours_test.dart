import 'package:flutter_test/flutter_test.dart';
import 'package:market_mates/features/events/providers/event_provider.dart';

void main() {
  test('weekdayOf reads German and English abbreviations', () {
    expect(weekdayOf('Mo'), DateTime.monday);
    expect(weekdayOf('Mo.'), DateTime.monday);
    expect(weekdayOf('Tue'), DateTime.tuesday);
    expect(weekdayOf('Mi.'), DateTime.wednesday);
    expect(weekdayOf('Do'), DateTime.thursday);
    expect(weekdayOf('Fr'), DateTime.friday);
    expect(weekdayOf('Sat'), DateTime.saturday);
    expect(weekdayOf('So'), DateTime.sunday);
    expect(weekdayOf('Sun'), DateTime.sunday);
    expect(weekdayOf('x'), isNull);
  });

  test('isOpenAt compares weekdays, not the device language', () {
    final hours = [
      {'days': ['Mo', 'Di'], 'open': '11:00', 'close': '21:00'},
      {'days': ['Sat'], 'open': '10:00', 'close': '22:00'},
    ];
    expect(isOpenAt(hours, DateTime(2026, 11, 17, 12)), isTrue); // Tuesday
    expect(isOpenAt(hours, DateTime(2026, 11, 17, 22)), isFalse);
    expect(isOpenAt(hours, DateTime(2026, 11, 18, 12)), isFalse); // Wednesday
    expect(isOpenAt(hours, DateTime(2026, 11, 21, 10, 30)), isTrue); // Saturday
  });
}
