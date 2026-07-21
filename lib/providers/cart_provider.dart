import 'package:flutter/material.dart';
import 'package:foodgo/models/cart_item.dart';
import 'package:foodgo/models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Thêm sản phẩm vào giỏ hàng
  /// Trả về false nếu sản phẩm thuộc nhà hàng khác
  bool addItem(Product product, String restaurantName) {
    // Kiểm tra nếu giỏ hàng đã có sản phẩm từ nhà hàng khác
    if (_restaurantId != null && _restaurantId != product.restaurantId) {
      return false;
    }

    _restaurantId = product.restaurantId;
    _restaurantName = restaurantName;

    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
    return true;
  }

  /// Cập nhật số lượng sản phẩm
  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    _items[index] = _items[index].copyWith(quantity: quantity);
    notifyListeners();
  }

  /// Xóa sản phẩm khỏi giỏ hàng
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  /// Xóa toàn bộ giỏ hàng
  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }
}
