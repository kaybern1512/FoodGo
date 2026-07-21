import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String orderId;
  final String customerId;
  final String restaurantId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
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

    return Review(
      id: id,
      orderId: map['orderId']?.toString() ?? '',
      customerId: map['customerId']?.toString() ?? '',
      restaurantId: map['restaurantId']?.toString() ?? '',
      rating: parseDouble(map['rating']),
      comment: map['comment']?.toString() ?? '',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Review copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? restaurantId,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
