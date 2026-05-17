// lib/features/auth/domain/entities/user.dart

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final int reputationScore;
  final List<String> badges;
  final DateTime createdAt;
  final bool isVerified;
  final String? bio;
  final String? location;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.reputationScore = 0,
    this.badges = const [],
    required this.createdAt,
    this.isVerified = false,
    this.bio,
    this.location,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      reputationScore: json['reputationScore'] as int? ?? 0,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? false,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'reputationScore': reputationScore,
      'badges': badges,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'bio': bio,
      'location': location,
      'phone': phone,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? reputationScore,
    List<String>? badges,
    DateTime? createdAt,
    bool? isVerified,
    String? bio,
    String? location,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      reputationScore: reputationScore ?? this.reputationScore,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      phone: phone ?? this.phone,
    );
  }

}
