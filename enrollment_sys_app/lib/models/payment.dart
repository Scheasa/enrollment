double _num(dynamic v) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);

/// 12.5 -> "$12.50"
String money(double v) => '\$${v.toStringAsFixed(2)}';

class Payment {
  final int id;
  final int enrollmentId;
  final double amount;
  final String method; // aba | acleda | wing | cash
  final String status; // pending | verified | rejected
  final String? receiptUrl;
  final String? verifierName;
  final String? paidAt;
  final String? createdAt;

  /// Only sent on the staff endpoints (the enrollment's student and course).
  final String? studentName;
  final String? studentEmail;
  final String? courseTitle;

  const Payment({
    required this.id,
    required this.enrollmentId,
    required this.amount,
    required this.method,
    required this.status,
    this.receiptUrl,
    this.verifierName,
    this.paidAt,
    this.createdAt,
    this.studentName,
    this.studentEmail,
    this.courseTitle,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    String? studentName;
    String? studentEmail;
    String? courseTitle;

    final enrollment = json['enrollment'];
    if (enrollment is Map<String, dynamic>) {
      final student = enrollment['student'];
      if (student is Map<String, dynamic>) {
        studentName = student['name'] as String?;
        studentEmail = student['email'] as String?;
      }
      final course = enrollment['course'];
      if (course is Map<String, dynamic>) {
        courseTitle = course['title'] as String?;
      }
    }

    return Payment(
      id: json['id'] as int,
      enrollmentId: (json['enrollment_id'] ?? 0) as int,
      amount: _num(json['amount']),
      method: (json['payment_method'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      receiptUrl: json['receipt_url'] as String?,
      verifierName: json['verifier_name'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
      studentName: studentName,
      studentEmail: studentEmail,
      courseTitle: courseTitle,
    );
  }

  /// "2026-10-22 19:30:00" -> "2026-10-22"
  String get dateText {
    final s = paidAt ?? createdAt ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class PaymentSummary {
  final double fee;
  final double verified;
  final double pending;
  final double remaining;
  final bool isFullyPaid;

  const PaymentSummary({
    required this.fee,
    required this.verified,
    required this.pending,
    required this.remaining,
    required this.isFullyPaid,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
    fee: _num(json['fee']),
    verified: _num(json['verified']),
    pending: _num(json['pending']),
    remaining: _num(json['remaining']),
    isFullyPaid: json['is_fully_paid'] == true,
  );

  /// 0.0 to 1.0, the verified part of the fee (for the progress bar).
  double get paidRatio =>
      fee > 0 ? (verified / fee).clamp(0.0, 1.0).toDouble() : 0.0;
}
