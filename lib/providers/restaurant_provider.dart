import 'package:flutter/material.dart';
import 'package:foodgo/models/restaurant.dart';
import 'package:foodgo/services/restaurant_service.dart';

class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  List<Restaurant> _restaurants = [];
  Restaurant? _myRestaurant;
  bool _isLoading = false;
  String? _errorMessage;

  List<Restaurant> get restaurants => _restaurants;
  Restaurant? get myRestaurant => _myRestaurant;
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

  /// Lấy danh sách nhà hàng đã duyệt và đang mở (Customer)
  Future<void> loadOpenRestaurants() async {
    _setLoading(true);
    _setError(null);
    try {
      _restaurants = await _restaurantService.getApprovedOpenRestaurants();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy tất cả nhà hàng (Admin)
  Future<void> loadAllRestaurants() async {
    _setLoading(true);
    _setError(null);
    try {
      _restaurants = await _restaurantService.getAllRestaurants();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy nhà hàng của chủ sở hữu hiện tại (Restaurant role)
  Future<void> loadMyRestaurant(String ownerId) async {
    _setLoading(true);
    _setError(null);
    try {
      _myRestaurant = await _restaurantService.getRestaurantByOwnerId(ownerId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo nhà hàng mới
  Future<bool> createRestaurant(Restaurant restaurant) async {
    _setLoading(true);
    _setError(null);
    try {
      final id = await _restaurantService.createRestaurant(restaurant);
      _myRestaurant = restaurant.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật nhà hàng
  Future<bool> updateRestaurant(
      String restaurantId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      await _restaurantService.updateRestaurant(restaurantId, data);
      await loadMyRestaurant(_myRestaurant!.ownerId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Phê duyệt / từ chối nhà hàng (Admin)
  Future<bool> setApprovalStatus(String restaurantId, bool isApproved) async {
    _setLoading(true);
    _setError(null);
    try {
      await _restaurantService.setApprovalStatus(restaurantId, isApproved);
      final index = _restaurants.indexWhere((r) => r.id == restaurantId);
      if (index != -1) {
        _restaurants[index] = _restaurants[index].copyWith(isApproved: isApproved);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bật / tắt trạng thái mở cửa
  Future<bool> toggleOpenStatus(String restaurantId, bool isOpen) async {
    _setError(null);
    try {
      await _restaurantService.setOpenStatus(restaurantId, isOpen);
      if (_myRestaurant?.id == restaurantId) {
        _myRestaurant = _myRestaurant!.copyWith(isOpen: isOpen);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
}
