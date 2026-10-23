class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role; // student | staff | admin
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
  });

  bool get isAdmin => role == 'admin';

  /// Staff and admin both use the review screens.
  bool get isStaff => role == 'staff' || role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: json['role'] as String,
    profileImageUrl: json['profile_image_url'] as String?,
  );

  /// Same keys as the API, so fromJson(toJson()) round-trips for local storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'profile_image_url': profileImageUrl,
  };
}
