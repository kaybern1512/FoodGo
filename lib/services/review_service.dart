import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reviewsRef =>
      _firestore.collection(FirestoreCollections.reviews);

  /// Tạo đánh giá mới
  Future<String> createReview(Review review) async {
    try {
      final docRef = await _reviewsRef.add(review.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo đánh giá: $e');
    }
  }

  /// Kiểm tra xem đơn hàng đã được đánh giá chưa
  Future<bool> hasReviewForOrder(String orderId) async {
    try {
      final snapshot = await _reviewsRef
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Không thể kiểm tra đánh giá: $e');
    }
  }

  /// Lấy đánh giá theo nhà hàng
  Future<List<Review>> getReviewsByRestaurant(String restaurantId) async {
    try {
      final snapshot = await _reviewsRef
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy đánh giá: $e');
    }
  }

  /// Lấy đánh giá của khách hàng
  Future<List<Review>> getReviewsByCustomer(String customerId) async {
    try {
      final snapshot = await _reviewsRef
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              Review.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy đánh giá: $e');
    }
  }
}
