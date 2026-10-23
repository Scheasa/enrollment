import 'schedule.dart';

class Course {
  final int id;
  final String title;
  final String description;
  final String category; // computer | english
  final String level;
  final double fee;
  final int durationMonths;
  final String? thumbnailUrl;
  final bool isActive;
  final int? schedulesCount;
  final List<Schedule> schedules; // only filled by GET /courses/{id}

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.fee,
    required this.durationMonths,
    this.thumbnailUrl,
    this.isActive = true,
    this.schedulesCount,
    this.schedules = const [],
  });

  bool get isEnglish => category == 'english';

  String get feeText => fee % 1 == 0
      ? '\$${fee.toStringAsFixed(0)}'
      : '\$${fee.toStringAsFixed(2)}';

  String get durationText =>
      durationMonths == 1 ? '1 month' : '$durationMonths months';

  static bool _asBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return fallback;
  }

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'] as int,
    title: json['title'] as String,
    description: (json['description'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    level: (json['level'] ?? '') as String,
    fee: (json['fee'] as num?)?.toDouble() ?? 0,
    durationMonths: (json['duration_months'] as num?)?.toInt() ?? 0,
    thumbnailUrl: json['thumbnail_url'] as String?,
    isActive: _asBool(json['is_active'], true),
    schedulesCount: (json['schedules_count'] as num?)?.toInt(),
    schedules: ((json['schedules'] as List?) ?? const [])
        .map((e) => Schedule.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
