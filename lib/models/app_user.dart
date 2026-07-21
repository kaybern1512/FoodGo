import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/enums/user_role.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String avatarUrl;
  final UserRole role;
  final bool isActive;
  final String vehiclePlate;
  final bool isOnline;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.avatarUrl,
    required this.role,
    required this.isActive,
    this.vehiclePlate = '',
    this.isOnline = false,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    bool parseBool(dynamic val, {bool defaultValue = true}) {
      if (val is bool) return val;
      if (val != null) {
        final str = val.toString().toLowerCase().trim();
        if (str == 'true' || str == '1') return true;
        if (str == 'false' || str == '0') return false;
      }
      return defaultValue;
    }

    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return AppUser(
      id: id,
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString() ?? '',
      role: userRoleFromString(map['role']?.toString() ?? 'customer'),
      isActive: parseBool(map['isActive'], defaultValue: true),
      vehiclePlate: map['vehiclePlate']?.toString() ?? '',
      isOnline: parseBool(map['isOnline'], defaultValue: false),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'role': role.toFirestoreString(),
      'isActive': isActive,
      'vehiclePlate': vehiclePlate,
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    UserRole? role,
    bool? isActive,
    String? vehiclePlate,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
