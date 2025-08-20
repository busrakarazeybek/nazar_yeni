enum UserRole { candidate, selector, admin }

enum GenderType { male, female, other, preferNotToSay }

extension GenderTypeExtension on GenderType {
  String get displayName {
    switch (this) {
      case GenderType.male:
        return 'Erkek';
      case GenderType.female:
        return 'Kadın';
      case GenderType.other:
        return 'Diğer';
      case GenderType.preferNotToSay:
        return 'Belirtmek İstemiyorum';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final int? age;
  final GenderType? gender;
  final String? bio;
  final List<String>? interests;
  final String? location;
  final String? profession;
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? phone;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? preferredAgeMin;
  final int? preferredAgeMax;
  final List<String>? preferredCities;
  final List<String>? preferredInterests;
  final List<String>? preferredGenders;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.age,
    this.gender,
    this.bio,
    this.interests,
    this.location,
    this.profession,
    this.imageUrl,
    this.imageUrls,
    this.phone,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.preferredAgeMin,
    this.preferredAgeMax,
    this.preferredCities,
    this.preferredInterests,
    this.preferredGenders,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: _parseUserRole(json['role'] as String?),
      age: json['age'] as int?,
      gender: _parseGenderType(json['gender'] as String?),
      bio: json['bio'] as String?,
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : null,
      location: json['location'] as String?,
      profession: json['profession'] as String?,
      imageUrl: json['image_url'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      preferredAgeMin: json['preferred_age_min'] as int?,
      preferredAgeMax: json['preferred_age_max'] as int?,
      preferredCities: json['preferred_cities'] != null
          ? List<String>.from(json['preferred_cities'] as List)
          : null,
      preferredInterests: json['preferred_interests'] != null
          ? List<String>.from(json['preferred_interests'] as List)
          : null,
      preferredGenders: json['preferred_genders'] != null
          ? List<String>.from(json['preferred_genders'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.toString().split('.').last,
      'age': age,
      'gender': gender?.toString().split('.').last,
      'bio': bio,
      'interests': interests,
      'location': location,
      'profession': profession,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'phone': phone,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'preferred_age_min': preferredAgeMin,
      'preferred_age_max': preferredAgeMax,
      'preferred_cities': preferredCities,
      'preferred_interests': preferredInterests,
      'preferred_genders': preferredGenders,
    };
  }

  UserProfile copyWith({
    String? email,
    String? fullName,
    UserRole? role,
    int? age,
    GenderType? gender,
    String? bio,
    List<String>? interests,
    String? location,
    String? profession,
    String? imageUrl,
    String? phone,
    bool? isActive,
    bool? isVerified,
    DateTime? updatedAt,
    int? preferredAgeMin,
    int? preferredAgeMax,
    List<String>? preferredCities,
    List<String>? preferredInterests,
    List<String>? preferredGenders,
  }) {
    return UserProfile(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      profession: profession ?? this.profession,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferredAgeMin: preferredAgeMin ?? this.preferredAgeMin,
      preferredAgeMax: preferredAgeMax ?? this.preferredAgeMax,
      preferredCities: preferredCities ?? this.preferredCities,
      preferredInterests: preferredInterests ?? this.preferredInterests,
      preferredGenders: preferredGenders ?? this.preferredGenders,
    );
  }

  static UserRole _parseUserRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'candidate':
        return UserRole.candidate;
      case 'selector':
        return UserRole.selector;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.candidate;
    }
  }

  static GenderType? _parseGenderType(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
        return GenderType.male;
      case 'female':
        return GenderType.female;
      case 'other':
        return GenderType.other;
      case 'prefer_not_to_say':
        return GenderType.preferNotToSay;
      default:
        return null;
    }
  }

  // Convenience getters
  String get displayGender {
    switch (gender) {
      case GenderType.male:
        return 'Erkek';
      case GenderType.female:
        return 'Kadın';
      case GenderType.other:
        return 'Diğer';
      case GenderType.preferNotToSay:
        return 'Belirtmek istemiyorum';
      default:
        return 'Belirtilmemiş';
    }
  }

  String get displayRole {
    switch (role) {
      case UserRole.candidate:
        return 'Aday';
      case UserRole.selector:
        return 'Seçici';
      case UserRole.admin:
        return 'Yönetici';
    }
  }

  // Check if profile is complete
  bool get isProfileComplete {
    return age != null &&
        gender != null &&
        bio != null &&
        bio!.isNotEmpty &&
        location != null &&
        location!.isNotEmpty &&
        profession != null &&
        profession!.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
