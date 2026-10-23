/// Announcement as seen by staff/admin (includes the visible/hidden flag).
class ManagedAnnouncement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool isActive;
  final String createdAt;

  const ManagedAnnouncement({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory ManagedAnnouncement.fromJson(Map<String, dynamic> json) {
    final active = json['is_active'];
    return ManagedAnnouncement(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      isActive: active == true || active == 1 || active == '1',
      createdAt: (json['created_at'] ?? '') as String,
    );
  }

  /// "2026-10-10 09:30:00" -> "2026-10-10"
  String get dateText =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;
}
