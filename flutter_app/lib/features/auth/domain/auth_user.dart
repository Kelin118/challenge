class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'] as String),
    );
  }
}

