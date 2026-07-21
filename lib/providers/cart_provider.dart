import 'package:flutter/foundation.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/cart_item.dart'; // Lưu ý: Chỉnh lại package: nếu có lỗi import
import 'package:foodgo/models/cart_item.dart';
import 'package:foodgo/models/order_item.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/models/product.dart';

/// Provider quản lý giỏ hàng của người dùng.
///
/// Ràng buộc nghiệp vụ: Một giỏ hàng chỉ thuộc về 1 nhà hàng tại một thời điểm.
/// Nếu người dùng thêm sản phẩm từ nhà hàng khác, hệ thống sẽ từ chối
/// hoặc yêu cầu xóa giỏ hàng cũ.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;

  // Thông tin Voucher / Mã giảm giá
  String? _voucherCode;
  double _discountAmount = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  String? get voucherCode => _voucherCode;
  double get discountAmount => _discountAmount;

  /// Tổng số lượng món trong giỏ
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Tạm tính tiền hàng (chưa bao gồm phí ship và giảm giá)
  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Tổng tiền thanh toán cuối cùng (chống âm tiền nếu voucher vượt quá giá trị đơn)
  double get finalTotal {
    final total = subtotal + AppConstants.shippingFee - _discountAmount;
    return total < 0 ? 0 : total;
  }

  /// Kiểm tra giỏ hàng có rỗng không
  bool get isEmpty => _items.isEmpty;

  /// Thêm sản phẩm vào giỏ.
  /// Trả về `false` nếu sản phẩm thuộc nhà hàng khác với nhà hàng hiện tại trong giỏ.
  bool addItem(Product product, String restaurantName) {
    // Ràng buộc 1 nhà hàng
    if (_restaurantId != null && _restaurantId != product.restaurantId) {
      return false;
    }

    _restaurantId = product.restaurantId;
    _restaurantName = restaurantName;

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final currentItem = _items[index];
      _items[index] = currentItem.copyWith(quantity: currentItem.quantity + 1);
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }

    notifyListeners();
    return true;
  }

  /// Cập nhật số lượng sản phẩm (Tự động xóa nếu quantity <= 0)
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  /// Xóa sản phẩm khỏi giỏ
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
      _voucherCode = null;
      _discountAmount = 0;
    }
    notifyListeners();
  }

  /// Xóa sạch giỏ hàng
  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    _voucherCode = null;
    _discountAmount = 0;
    notifyListeners();
  }

  /// Áp dụng mã giảm giá (Voucher)
  bool applyVoucher(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'FOODGO10') {
      _voucherCode = cleanCode;
      _discountAmount = 10000;
      notifyListeners();
      return true;
    } else if (cleanCode == 'FREESHIP') {
      _voucherCode = cleanCode;
      _discountAmount = AppConstants.shippingFee;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Hủy mã giảm giá
  void removeVoucher() {
    _voucherCode = null;
    _discountAmount = 0;
    notifyListeners();
  }

  /// Đặt lại đơn hàng cũ (Re-order)
  void reorderItems(
      List<OrderItem> orderItems, String restaurantId, String restaurantName) {
    clearCart();
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;

    for (var item in orderItems) {
      final product = Product(
        id: item.productId,
        restaurantId: restaurantId,
        name: item.productName,
        description: '',
        price: item.price,
        imageUrl: item.imageUrl,
        category: '',
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      _items.add(CartItem(
        product: product,
        quantity: item.quantity,
      ));
    }
    notifyListeners();
  }
}