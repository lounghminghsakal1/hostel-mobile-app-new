import '../../../core/utils/app_dates.dart';
import '../../../core/utils/json.dart';
import '../../../core/widgets/tone.dart';

/// Monthly mess bill entity and its JSON model, shared by the student fees
/// screen and the admin mess bills screen.
enum MessBillStatus {
  draft('DRAFT', 'Draft', Tone.neutral),
  published('PUBLISHED', 'Published', Tone.success),
  expired('EXPIRED', 'Expired', Tone.neutral);

  const MessBillStatus(this.apiValue, this.label, this.tone);
  final String apiValue;
  final String label;
  final Tone tone;

  static MessBillStatus fromApi(Object? v) =>
      MessBillStatus.values.firstWhere((s) => s.apiValue == v, orElse: () => MessBillStatus.draft);
}

const monthApiNames = [
  'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
  'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
];

/// A bill's month (1–12) and year.
typedef BillMonth = ({int month, int year});

/// The months a hostel admin may create, edit or publish bills for: this
/// month and next month in India time. The backend enforces the same rule.
List<BillMonth> allowedBillMonths([DateTime? today]) {
  final d = today ?? AppDates.todayIst();
  final next = DateTime(d.year, d.month + 1);
  return [(month: d.month, year: d.year), (month: next.month, year: next.year)];
}

bool isAllowedBillMonth(int month, int year, [DateTime? today]) =>
    allowedBillMonths(today).any((m) => m.month == month && m.year == year);

String billMonthLabel(BillMonth m) => AppDates.monthYear(DateTime(m.year, m.month));

class MessBill {
  const MessBill({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.lastDate,
    required this.status,
    this.paidAt,
    this.canEdit = false,
    this.canPublish = false,
    this.canDelete = false,
  });

  final int id;

  /// 1–12.
  final int month;
  final int year;
  final double amount;
  final DateTime lastDate;
  final MessBillStatus status;

  /// Student view only: when this student's payment was recorded. Always
  /// null until office/online payments are recorded in the app.
  final DateTime? paidAt;

  /// Admin view only: drafts of this month or next can be edited/published;
  /// any draft can be deleted.
  final bool canEdit;
  final bool canPublish;
  final bool canDelete;

  BillMonth get billMonth => (month: month, year: year);
  DateTime get monthDate => DateTime(year, month);
  String get title => AppDates.monthYear(monthDate);
  bool get isPaid => paidAt != null;
}

class MessBillModel extends MessBill {
  const MessBillModel({
    required super.id,
    required super.month,
    required super.year,
    required super.amount,
    required super.lastDate,
    required super.status,
    super.paidAt,
    super.canEdit,
    super.canPublish,
    super.canDelete,
  });

  factory MessBillModel.fromJson(Map<String, dynamic> json) {
    final monthIndex = monthApiNames.indexOf(JsonRead.string(json['month']));
    final month = monthIndex < 0 ? 1 : monthIndex + 1;
    final year = JsonRead.integer(json['year'], DateTime.now().year);
    final status = MessBillStatus.fromApi(json['status']);
    // Older servers don't send the action flags: work them out the same way.
    final editable = status == MessBillStatus.draft && isAllowedBillMonth(month, year);
    return MessBillModel(
      id: JsonRead.integer(json['id']),
      month: month,
      year: year,
      // Prisma Decimal arrives as a string.
      amount: JsonRead.decimal(json['amount']),
      lastDate: JsonRead.calendarDate(json['lastDate']) ?? AppDates.todayIst(),
      status: status,
      paidAt: JsonRead.instant(json['paidAt']),
      canEdit: JsonRead.boolean(json['canEdit'], editable),
      canPublish: JsonRead.boolean(json['canPublish'], editable),
      canDelete: JsonRead.boolean(json['canDelete'], status == MessBillStatus.draft),
    );
  }
}
