import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  StreamSubscription<List<FoodOrder>>? _restaurantSubscription;

  List<FoodOrder> _orders = [];
  FoodOrder? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<FoodOrder> get orders => _orders;
  FoodOrder? get selectedOrder => _selectedOrder;
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

  /// Lấy đơn hàng của khách hàng
  Future<void> loadCustomerOrders(String customerId) async {
    _setLoading(true);
    _setError(null);
    try {
      _orders = await _orderService.getOrdersByCustomer(customerId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy đơn hàng của nhà hàng
  Future<void> loadRestaurantOrders(String restaurantId) async {
    _setLoading(true);
    _setError(null);
    try {
      _orders = await _orderService.getOrdersByRestaurant(restaurantId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lắng nghe đơn hàng nhà hàng theo thời gian thực
  void listenRestaurantOrders(String restaurantId) {
    _restaurantSubscription?.cancel();

    _restaurantSubscription =
        _orderService.streamRestaurantOrders(restaurantId).listen(
      (orders) {
        _orders = orders;
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
      },
    );
  }

  /// Lấy đơn hàng đang chờ shipper
  Future<void> loadWaitingOrders() async {
    _setLoading(true);
    _setError(null);
    try {
      _orders = await _orderService.getWaitingOrders();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy đơn hàng của shipper
  Future<void> loadShipperOrders(String shipperId) async {
    _setLoading(true);
    _setError(null);
    try {
      _orders = await _orderService.getOrdersByShipper(shipperId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy tất cả đơn hàng (Admin)
  Future<void> loadAllOrders() async {
    _setLoading(true);
    _setError(null);
    try {
      _orders = await _orderService.getAllOrders();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo đơn hàng mới
  Future<String?> createOrder(FoodOrder order) async {
    _setLoading(true);
    _setError(null);
    try {
      final id = await _orderService.createOrder(order);
      notifyListeners();
      return id;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật trạng thái đơn hàng
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _setLoading(true);
    _setError(null);
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(orderStatus: newStatus);
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

  /// Shipper nhận đơn hàng
  Future<bool> acceptOrder(String orderId, String shipperId,
      {String? shipperName, String? shipperPhone}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _orderService.acceptOrderByShipper(orderId, shipperId,
          shipperName: shipperName, shipperPhone: shipperPhone);
      _orders.removeWhere((o) => o.id == orderId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedOrder(FoodOrder order) {
    _selectedOrder = order;
    notifyListeners();
  }

  @override
  void dispose() {
    _restaurantSubscription?.cancel();
    super.dispose();
  }
}
