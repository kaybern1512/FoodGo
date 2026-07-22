import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String code;
  final String description;
  final double discountAmount;
  final double minOrderAmount;
  final int usageLimit; // Tổng số lượt phát ra
  final int usedCount;  // Số lượt đã được sử dụng
  final bool isActive;
  final DateTime createdAt;

  const Voucher({
    required this.id,
    required this.code,
    required this.description,
    required this.discountAmount,
    required this.minOrderAmount,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    required this.createdAt,
  });

  /// Số lượt còn lại
  int get remainingCount {
    final rem = usageLimit - usedCount;
    return rem < 0 ? 0 : rem;
  }

  factory Voucher.fromMap(Map<String, dynamic> map, String id) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val != null) return double.tryParse(val.toString()) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val, {int defaultValue = 100}) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString()) ?? defaultValue;
      return defaultValue;
    }

    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val != null) {
        final str = val.toString().toLowerCase().trim();
        if (str == 'true' || str == '1') return true;
        if (str == 'false' || str == '0') return false;
      }
      return true;
    }

    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return Voucher(
      id: id,
      code: map['code']?.toString().toUpperCase() ?? '',
      description: map['description']?.toString() ?? '',
      discountAmount: parseDouble(map['discountAmount']),
      minOrderAmount: parseDouble(map['minOrderAmount']),
      usageLimit: parseInt(map['usageLimit'], defaultValue: 100),
      usedCount: parseInt(map['usedCount'], defaultValue: 0),
      isActive: parseBool(map['isActive']),
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase(),
      'description': description,
      'discountAmount': discountAmount,
      'minOrderAmount': minOrderAmount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Voucher copyWith({
    String? id,
    String? code,
    String? description,
    double? discountAmount,
    double? minOrderAmount,
    int? usageLimit,
    int? usedCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountAmount: discountAmount ?? this.discountAmount,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
