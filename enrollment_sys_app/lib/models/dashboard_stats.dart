import 'payment.dart';

class DashboardStats {
  final int totalStudents;
  final int activeCourses;
  final Map<String, int> enrollments; // pending, approved, rejected, dropped

  final Map<String, int> payments; // pending, verified, rejected
  final double revenueTotal; // verified payments only
  final double revenueThisMonth;
  final List<Payment> recentPendingPayments; // newest 5 waiting for review

  const DashboardStats({
    required this.totalStudents,
    required this.activeCourses,
    required this.enrollments,
    this.payments = const {},
    this.revenueTotal = 0,
    this.revenueThisMonth = 0,
    this.recentPendingPayments = const [],
  });

  int count(String status) => enrollments[status] ?? 0;

  int paymentCount(String status) => payments[status] ?? 0;

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
    activeCourses: (json['active_courses'] as num?)?.toInt() ?? 0,
    enrollments: ((json['enrollments'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
    payments: ((json['payments'] as Map?) ?? const {}).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
    revenueTotal: (json['revenue_total'] as num?)?.toDouble() ?? 0,
    revenueThisMonth: (json['revenue_this_month'] as num?)?.toDouble() ?? 0,
    recentPendingPayments: json['recent_pending_payments'] is List
        ? (json['recent_pending_payments'] as List)
              .map((e) => Payment.fromJson(e as Map<String, dynamic>))
              .toList()
        : const [],
  );
}
