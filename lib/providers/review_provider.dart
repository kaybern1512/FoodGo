import 'package:flutter/material.dart';
import 'package:foodgo/models/review.dart';
import 'package:foodgo/services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<Review> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Tạo đánh giá mới
  Future<bool> createReview(Review review) async {
    _setLoading(true);
    _setError(null);
    try {
      final id = await _reviewService.createReview(review);
      _reviews.insert(0, review.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy đánh giá theo nhà hàng
  Future<void> loadReviewsByRestaurant(String restaurantId) async {
    _setLoading(true);
    _setError(null);
    try {
      _reviews = await _reviewService.getReviewsByRestaurant(restaurantId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Kiểm tra xem đơn hàng đã được đánh giá chưa
  Future<bool> hasReviewForOrder(String orderId) async {
    try {
      return await _reviewService.hasReviewForOrder(orderId);
    } catch (e) {
      return false;
    }
  }

  void clearReviews() {
    _reviews = [];
    notifyListeners();
  }
}
