import '../../../common/mess_bills/mess_bill.dart';

/// When the hostel office takes mess fee payments for one group of students.
class OfficeHours {
  const OfficeHours({required this.label, required this.opensAt, required this.closesAt});

  /// "Shift 1 students".
  final String label;

  /// "HH:mm", India time.
  final String opensAt;
  final String closesAt;
}

/// How students pay. Online payment isn't available yet, so they pay at the
/// hostel office during their shift's office hours.
class MessFeePaymentInfo {
  const MessFeePaymentInfo({
    required this.onlinePaymentAvailable,
    required this.message,
    required this.officeHours,
  });

  final bool onlinePaymentAvailable;
  final String message;
  final List<OfficeHours> officeHours;

  /// Used if the server doesn't send payment info. Keep in step with the
  /// backend's `MESS_FEE_PAYMENT_INFO`.
  static const fallback = MessFeePaymentInfo(
    onlinePaymentAvailable: false,
    message: 'Online mess fee payment will be available soon. For now, please visit the hostel office and pay there.',
    officeHours: [
      OfficeHours(label: 'Shift 1 students', opensAt: '14:00', closesAt: '16:00'),
      OfficeHours(label: 'Shift 2 students', opensAt: '09:00', closesAt: '11:00'),
    ],
  );
}

class MyMessBills {
  const MyMessBills({required this.bills, required this.paymentInfo});

  /// Published bills, newest first.
  final List<MessBill> bills;
  final MessFeePaymentInfo paymentInfo;
}

abstract interface class StudentFeesRepository {
  /// The hostel's published mess bills (newest first) and how to pay them.
  Future<MyMessBills> myBills();
}
