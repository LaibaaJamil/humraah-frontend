import 'ngo.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String avatar;
  final NGO? ngo;
  final bool isActive;
  final int trustScore;
  final bool isLargeOrg;
  final bool isPhoneVerified;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatar = '',
    this.ngo,
    this.isActive = true,
    this.trustScore = 50,
    this.isLargeOrg = false,
    this.isPhoneVerified = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      role: (json['role'] ?? 'ngo_staff').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      ngo: json['ngo'] is Map<String, dynamic>
          ? NGO.fromJson(json['ngo'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] ?? true,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 50,
      isLargeOrg: json['isLargeOrg'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar': avatar,
        'ngo': ngo?.toJson(),
        'isActive': isActive,
        'trustScore': trustScore,
        'isLargeOrg': isLargeOrg,
        'isPhoneVerified': isPhoneVerified,
      };

  bool get isSuperAdmin => role == 'super_admin';
  bool get isNgoAdmin => role == 'ngo_admin';
  bool get isNgoStaff => role == 'ngo_staff';
  bool get isDonor => role == 'donor';
  bool get isPublicUser => role == 'public_user';
  bool get hasNgo => ngo != null;

  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'ngo_admin':
        return 'NGO Admin';
      case 'ngo_staff':
        return 'NGO Staff';
      case 'donor':
        return 'Donor';
      case 'public_user':
        return 'Citizen';
      default:
        return role;
    }
  }
}
