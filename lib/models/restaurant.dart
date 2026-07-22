import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String address;
  final String phone;
  final String imageUrl;
  final double rating;
  final bool isApproved;
  final bool isOpen;
  final DateTime createdAt;

  const Restaurant({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.address,
    required this.phone,
    required this.imageUrl,
    required this.rating,
    required this.isApproved,
    required this.isOpen,
    required this.createdAt,
  });

  factory Restaurant.fromMap(Map<String, dynamic> map, String id) {
    bool parseBool(dynamic val, {bool defaultValue = true}) {
      if (val is bool) return val;
      if (val != null) {
        final str = val.toString().toLowerCase().trim();
        if (str == 'true' || str == '1') return true;
        if (str == 'false' || str == '0') return false;
      }
      return defaultValue;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val != null) {
        return double.tryParse(val.toString()) ?? 0.0;
      }
      return 0.0;
    }

    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return Restaurant(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      rating: parseDouble(map['rating']),
      isApproved: parseBool(map['isApproved'], defaultValue: true),
      isOpen: parseBool(map['isOpen'], defaultValue: true),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,
      'rating': rating,
      'isApproved': isApproved,
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Restaurant copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? imageUrl,
    double? rating,
    bool? isApproved,
    bool? isOpen,
    DateTime? createdAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      isApproved: isApproved ?? this.isApproved,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
