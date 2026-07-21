import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
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

    return Product(
      id: id,
      restaurantId: map['restaurantId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      price: parseDouble(map['price']),
      imageUrl: map['imageUrl']?.toString() ?? '',
      isAvailable: parseBool(map['isAvailable'], defaultValue: true),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Product copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
