class Schedule {
  final int id;
  final int courseId;
  final String teacherName;
  final String roomNumber;
  final String shift; // morning | afternoon | evening
  final List<String> days;
  final String startTime; // "07:30"
  final String endTime;
  final int maxCapacity;
  final int seatsTaken;
  final int seatsAvailable;
  final bool isFull;

  const Schedule({
    required this.id,
    required this.courseId,
    required this.teacherName,
    required this.roomNumber,
    required this.shift,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    required this.seatsTaken,
    required this.seatsAvailable,
    required this.isFull,
  });

  String get shiftLabel =>
      shift.isEmpty ? '' : shift[0].toUpperCase() + shift.substring(1);

  String get daysText => days.join(' · ');

  String get timeText => '$startTime – $endTime';

  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: json['id'] as int,
    courseId: json['course_id'] as int,
    teacherName: (json['teacher_name'] ?? '') as String,
    roomNumber: (json['room_number'] ?? '') as String,
    shift: (json['shift'] ?? '') as String,
    days: ((json['days'] as List?) ?? const []).cast<String>(),
    startTime: (json['start_time'] ?? '') as String,
    endTime: (json['end_time'] ?? '') as String,
    maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 0,
    seatsTaken: (json['seats_taken'] as num?)?.toInt() ?? 0,
    seatsAvailable: (json['seats_available'] as num?)?.toInt() ?? 0,
    isFull: (json['is_full'] as bool?) ?? false,
  );
}
