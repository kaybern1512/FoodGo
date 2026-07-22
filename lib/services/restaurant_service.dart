import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/restaurant.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _restaurantsRef =>
      _firestore.collection(FirestoreCollections.restaurants);

  /// Tạo nhà hàng mới
  Future<String> createRestaurant(Restaurant restaurant) async {
    try {
      final docRef = await _restaurantsRef.add(restaurant.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo nhà hàng: $e');
    }
  }

  /// Lấy nhà hàng theo ID chủ sở hữu
  Future<Restaurant?> getRestaurantByOwnerId(String ownerId) async {
    try {
      final snapshot = await _restaurantsRef
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Restaurant.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Không thể lấy thông tin nhà hàng: $e');
    }
  }

  /// Lấy nhà hàng theo ID
  Future<Restaurant?> getRestaurantById(String restaurantId) async {
    try {
      final doc = await _restaurantsRef.doc(restaurantId).get();
      if (!doc.exists) return null;
      return Restaurant.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Không thể lấy thông tin nhà hàng: $e');
    }
  }

  /// Lấy tất cả nhà hàng đã được phê duyệt và đang mở (dành cho khách hàng)
  Future<List<Restaurant>> getApprovedOpenRestaurants() async {
    try {
      // Dùng single query để tránh lỗi thiếu Composite Index của Firestore
      final snapshot = await _restaurantsRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              Restaurant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((r) => r.isApproved && r.isOpen)
          .toList();
    } catch (e) {
      // Fallback không orderBy nếu trường createdAt bị thiếu
      final snapshot = await _restaurantsRef.get();
      return snapshot.docs
          .map((doc) =>
              Restaurant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((r) => r.isApproved && r.isOpen)
          .toList();
    }
  }

  /// Lấy tất cả nhà hàng (dành cho Admin)
  Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final snapshot =
          await _restaurantsRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              Restaurant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách nhà hàng: $e');
    }
  }

  /// Cập nhật thông tin nhà hàng
  Future<void> updateRestaurant(
      String restaurantId, Map<String, dynamic> data) async {
    try {
      await _restaurantsRef.doc(restaurantId).update(data);
    } catch (e) {
      throw Exception('Không thể cập nhật nhà hàng: $e');
    }
  }

  /// Phê duyệt hoặc từ chối nhà hàng (dành cho Admin)
  Future<void> setApprovalStatus(String restaurantId, bool isApproved) async {
    try {
      await _restaurantsRef
          .doc(restaurantId)
          .update({'isApproved': isApproved});
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái phê duyệt: $e');
    }
  }

  /// Bật/tắt trạng thái mở cửa
  Future<void> setOpenStatus(String restaurantId, bool isOpen) async {
    try {
      await _restaurantsRef.doc(restaurantId).update({'isOpen': isOpen});
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái mở cửa: $e');
    }
  }
}
