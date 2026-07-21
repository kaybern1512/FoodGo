import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/models/food_order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef =>
      _firestore.collection(FirestoreCollections.orders);

  /// Tạo đơn hàng mới
  Future<String> createOrder(FoodOrder order) async {
    try {
      final docRef = await _ordersRef.add(order.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo đơn hàng: $e');
    }
  }

  /// Lấy đơn hàng theo ID
  Future<FoodOrder?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersRef.doc(orderId).get();
      if (!doc.exists) return null;
      return FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Không thể lấy thông tin đơn hàng: $e');
    }
  }

  /// Lấy đơn hàng của khách hàng
  Future<List<FoodOrder>> getOrdersByCustomer(String customerId) async {
    try {
      final snapshot = await _ordersRef
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách đơn hàng: $e');
    }
  }

  /// Lấy đơn hàng của nhà hàng
  Future<List<FoodOrder>> getOrdersByRestaurant(String restaurantId) async {
    try {
      final snapshot = await _ordersRef
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách đơn hàng nhà hàng: $e');
    }
  }

  /// Lấy đơn hàng chờ shipper nhận
  Future<List<FoodOrder>> getWaitingOrders() async {
    try {
      final snapshot = await _ordersRef
          .where('orderStatus',
              isEqualTo: OrderStatus.waitingForShipper.toFirestoreString())
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách đơn hàng: $e');
    }
  }

  /// Lấy đơn hàng của shipper
  Future<List<FoodOrder>> getOrdersByShipper(String shipperId) async {
    try {
      final snapshot = await _ordersRef
          .where('shipperId', isEqualTo: shipperId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy đơn hàng của shipper: $e');
    }
  }

  /// Lấy tất cả đơn hàng (dành cho Admin)
  Future<List<FoodOrder>> getAllOrders() async {
    try {
      final snapshot =
          await _ordersRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              FoodOrder.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách đơn hàng: $e');
    }
  }

  /// Cập nhật trạng thái đơn hàng
  Future<void> updateOrderStatus(
      String orderId, OrderStatus newStatus) async {
    try {
      final updates = <String, dynamic>{
        'orderStatus': newStatus.toFirestoreString(),
        'updatedAt': Timestamp.now(),
      };
      // Khi hoàn thành đơn hàng tiền mặt, đánh dấu đã thanh toán
      if (newStatus == OrderStatus.completed) {
        final doc = await _ordersRef.doc(orderId).get();
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['paymentMethod'] == 'cash') {
          updates['paymentStatus'] = PaymentStatus.paid.toFirestoreString();
        }
      }
      await _ordersRef.doc(orderId).update(updates);
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái đơn hàng: $e');
    }
  }

  /// Shipper nhận đơn hàng (dùng transaction để tránh xung đột)
  Future<void> acceptOrderByShipper(
      String orderId, String shipperId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderDoc = await transaction.get(_ordersRef.doc(orderId));
        if (!orderDoc.exists) {
          throw Exception('Đơn hàng không tồn tại');
        }
        final data = orderDoc.data() as Map<String, dynamic>;
        final currentStatus = data['orderStatus'] as String?;
        if (currentStatus != OrderStatus.waitingForShipper.toFirestoreString()) {
          throw Exception('Đơn hàng đã được nhận bởi shipper khác');
        }
        transaction.update(_ordersRef.doc(orderId), {
          'shipperId': shipperId,
          'orderStatus': OrderStatus.delivering.toFirestoreString(),
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Không thể nhận đơn hàng: $e');
    }
  }
}
