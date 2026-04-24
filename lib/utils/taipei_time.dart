import 'package:timezone/timezone.dart' as tz;

/// Asia/Taipei helpers (requires [initializeTimeZones] in main).
class TaipeiTime {
  TaipeiTime._();

  static final tz.Location location = tz.getLocation('Asia/Taipei');

  static tz.TZDateTime now() {
    return tz.TZDateTime.now(location);
  }

  static tz.TZDateTime toTaipei(DateTime dt) {
    return tz.TZDateTime.from(dt.toUtc(), location);
  }

  static tz.TZDateTime businessDayStart(DateTime date, {int startHour = 9}) {
    return tz.TZDateTime(location, date.year, date.month, date.day, startHour);
  }

  static tz.TZDateTime currentBusinessDayStart({int startHour = 9}) {
    final current = now();
    final baseDate = current.hour < startHour
        ? current.subtract(const Duration(days: 1))
        : current;
    return businessDayStart(baseDate, startHour: startHour);
  }
}
