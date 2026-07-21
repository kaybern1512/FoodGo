import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/models/order_item.dart';

class FoodOrder {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? shipperId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodOrder({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.shipperId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodOrder.fromMap(Map<String, dynamic> map, String id) {
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

    final rawItems = map['items'];
    final List<OrderItem> itemsList = [];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map<String, dynamic>) {
          itemsList.add(OrderItem.fromMap(e));
        } else if (e is Map) {
          itemsList.add(OrderItem.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    return FoodOrder(
      id: id,
      customerId: map['customerId']?.toString() ?? '',
      restaurantId: map['restaurantId']?.toString() ?? '',
      shipperId: map['shipperId']?.toString(),
      customerName: map['customerName']?.toString() ?? '',
      customerPhone: map['customerPhone']?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      items: itemsList,
      subtotal: parseDouble(map['subtotal']),
      shippingFee: parseDouble(map['shippingFee']),
      totalAmount: parseDouble(map['totalAmount']),
      paymentMethod: paymentMethodFromString(
          map['paymentMethod']?.toString() ?? 'cash'),
      paymentStatus: paymentStatusFromString(
          map['paymentStatus']?.toString() ?? 'unpaid'),
      orderStatus:
          orderStatusFromString(map['orderStatus']?.toString() ?? 'pending'),
      note: map['note']?.toString() ?? '',
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'restaurantId': restaurantId,
      'shipperId': shipperId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.toFirestoreString(),
      'paymentStatus': paymentStatus.toFirestoreString(),
      'orderStatus': orderStatus.toFirestoreString(),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FoodOrder copyWith({
    String? id,
    String? customerId,
    String? restaurantId,
    String? shipperId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? shippingFee,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    OrderStatus? orderStatus,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      shipperId: shipperId ?? this.shipperId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
