import '../../../data/models/event.dart';
import '../providers/event_provider.dart';

/// Where a market stands today, for the status line on the market page.
sealed class TodayHours {
  const TodayHours();
}

/// Open right now, until [close] ("21:00").
class OpenNow extends TodayHours {
  final String close;
  const OpenNow(this.close);
}

/// Opens later today at [open] ("11:00").
class OpensLater extends TodayHours {
  final String open;
  const OpensLater(this.open);
}

/// No more opening today (or no hours for today).
class ClosedToday extends TodayHours {
  const ClosedToday();
}

/// The market is not running on [now]'s date: before its first or after its
/// last day.
class NotRunning extends TodayHours {
  const NotRunning();
}

/// No opening hours stored, so nothing can be said.
class HoursUnknown extends TodayHours {
  const HoursUnknown();
}

/// Today's opening state of [event] at [now]. Times are compared as "HH:mm"
/// strings, like [isOpenAt] does.
TodayHours todayHours(Event event, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final first = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
  final last = DateTime(event.endTime.year, event.endTime.month, event.endTime.day);
  if (today.isBefore(first) || today.isAfter(last)) return const NotRunning();

  final hours = event.openingHours ?? const <OpeningHour>[];
  if (hours.isEmpty) return const HoursUnknown();

  final time = _hhmm(now);
  String? nextOpen;
  for (final h in hours) {
    if (!h.days.map(weekdayOf).contains(now.weekday)) continue;
    if (time.compareTo(h.open) >= 0 && time.compareTo(h.close) <= 0) return OpenNow(h.close);
    if (time.compareTo(h.open) < 0 && (nextOpen == null || h.open.compareTo(nextOpen) < 0)) {
      nextOpen = h.open;
    }
  }
  return nextOpen == null ? const ClosedToday() : OpensLater(nextOpen);
}

String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
