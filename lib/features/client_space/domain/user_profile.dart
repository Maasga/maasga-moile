class UserProfile {
  UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.quartier,
    required this.memberSince,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String quartier;
  final String memberSince;
  final String? photoUrl;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    String? quartier,
    String? memberSince,
    String? photoUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      quartier: quartier ?? this.quartier,
      memberSince: memberSince ?? this.memberSince,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle memberSince from created_at
    String year = '2024';
    final createdAt = json['created_at']?.toString() ?? '';
    if (createdAt.length >= 4) {
      year = createdAt.substring(0, 4);
    }

    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['name'] ?? json['full_name'] ?? 'Client MAASGA',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      quartier: json['quartier'] ?? 'Ouagadougou',
      memberSince: json['member_since'] ?? year,
      photoUrl: json['photo_url'],
    );
  }
}
