import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foodgo/models/restaurant.dart';
import 'package:foodgo/services/restaurant_service.dart';

/// RestaurantProvider với notifyListeners() an toàn.
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

  /// Gọi notifyListeners() an toàn — không bao giờ gọi trong build frame.
  void _safeNotify() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
        SchedulerBinding.instance.schedulerPhase ==
            SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  /// Lấy danh sách nhà hàng đã duyệt và đang mở (Customer)
  Future<void> loadOpenRestaurants() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      _restaurants = await _restaurantService.getApprovedOpenRestaurants();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Lấy tất cả nhà hàng (Admin)
  Future<void> loadAllRestaurants() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      _restaurants = await _restaurantService.getAllRestaurants();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Lấy nhà hàng của chủ sở hữu hiện tại (Restaurant role)
  Future<void> loadMyRestaurant(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      _myRestaurant = await _restaurantService.getRestaurantByOwnerId(ownerId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Tạo nhà hàng mới
  Future<bool> createRestaurant(Restaurant restaurant) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final id = await _restaurantService.createRestaurant(restaurant);
      _myRestaurant = restaurant.copyWith(id: id);
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Cập nhật nhà hàng
  Future<bool> updateRestaurant(
      String restaurantId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await _restaurantService.updateRestaurant(restaurantId, data);
      await loadMyRestaurant(_myRestaurant!.ownerId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Phê duyệt / từ chối nhà hàng (Admin)
  Future<bool> setApprovalStatus(String restaurantId, bool isApproved) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await _restaurantService.setApprovalStatus(restaurantId, isApproved);
      final index = _restaurants.indexWhere((r) => r.id == restaurantId);
      if (index != -1) {
        _restaurants[index] =
            _restaurants[index].copyWith(isApproved: isApproved);
      }
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  /// Bật / tắt trạng thái mở cửa
  Future<bool> toggleOpenStatus(String restaurantId, bool isOpen) async {
    _errorMessage = null;
    try {
      await _restaurantService.setOpenStatus(restaurantId, isOpen);
      if (_myRestaurant?.id == restaurantId) {
        _myRestaurant = _myRestaurant!.copyWith(isOpen: isOpen);
        _safeNotify();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }
}
