import 'course.dart';
import 'payment.dart';
import 'schedule.dart';
import 'user.dart';

class Enrollment {
  final int id;
  final String status; // pending | approved | rejected | dropped
  final String? enrolledDate;
  final String? remarks;
  final Course? course;
  final Schedule? schedule;
  final User? student; // only sent on the staff endpoints
  final List<Payment> payments;
  final PaymentSummary? paymentSummary;

  const Enrollment({
    required this.id,
    required this.status,
    this.enrolledDate,
    this.remarks,
    this.course,
    this.schedule,
    this.student,
    this.payments = const [],
    this.paymentSummary,
  });

  bool get canDrop => status == 'pending' || status == 'approved';

  bool get hasPendingPayment => payments.any((p) => p.status == 'pending');

  /// Same rules as the server: active enrollment, money still owed, and no
  /// payment already waiting for review.
  bool get canPay =>
      canDrop && (paymentSummary?.remaining ?? 0) > 0 && !hasPendingPayment;

  String get statusLabel =>
      status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1);

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
    id: json['id'] as int,
    status: (json['status'] ?? '') as String,
    enrolledDate: json['enrolled_date'] as String?,
    remarks: json['remarks'] as String?,
    course: json['course'] is Map<String, dynamic>
        ? Course.fromJson(json['course'] as Map<String, dynamic>)
        : null,
    schedule: json['schedule'] is Map<String, dynamic>
        ? Schedule.fromJson(json['schedule'] as Map<String, dynamic>)
        : null,
    student: json['student'] is Map<String, dynamic>
        ? User.fromJson(json['student'] as Map<String, dynamic>)
        : null,
    payments: json['payments'] is List
        ? (json['payments'] as List)
              .map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList()
        : const [],
    paymentSummary: json['payment_summary'] is Map<String, dynamic>
        ? PaymentSummary.fromJson(
            json['payment_summary'] as Map<String, dynamic>,
          )
        : null,
  );
}
