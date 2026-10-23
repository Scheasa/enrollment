class Announcement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as int,
    title: json['title'] as String,
    content: (json['content'] ?? '') as String,
    imageUrl: json['image_url'] as String?,
    createdAt: json['created_at'] as String?,
  );
}
