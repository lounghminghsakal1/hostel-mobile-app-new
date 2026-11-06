import 'package:flutter_test/flutter_test.dart';
import 'package:our_hostel/core/utils/app_dates.dart';
import 'package:our_hostel/core/utils/json.dart';
import 'package:our_hostel/core/utils/text_utils.dart';

void main() {
  test('instants are sent with exactly three fractional digits', () {
    final moment = DateTime.utc(2026, 11, 14, 10, 30, 0, 0, 123);
    expect(AppDates.apiInstant(moment), '2026-11-14T10:30:00.000Z');
  });

  test('calendar dates never shift with time zones', () {
    expect(JsonRead.calendarDate('2026-11-12T00:00:00.000Z'), DateTime(2026, 11, 12));
    expect(AppDates.apiDate(DateTime(2026, 11, 2)), '2026-11-02');
  });

  test('UTC moments are shown in India time', () {
    expect(AppDates.time(DateTime.utc(2026, 11, 4, 15, 12)), '8:42 PM');
  });

  test('date ranges read naturally', () {
    expect(AppDates.range(DateTime(2026, 11, 12), DateTime(2026, 11, 14)), '12–14 Nov');
    expect(AppDates.range(DateTime(2026, 10, 30), DateTime(2026, 11, 2)), '30 Oct – 2 Nov');
    expect(AppDates.daysInclusive(DateTime(2026, 11, 12), DateTime(2026, 11, 14)), 3);
  });

  test('decimals from Prisma arrive as strings', () {
    expect(JsonRead.decimal('3450.00'), 3450);
    expect(3450.0.asRupees, '₹3,450');
    expect(125000.asRupees, '₹1,25,000');
  });
}
