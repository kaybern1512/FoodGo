import 'package:flutter/foundation.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/cart_item.dart';
import 'package:foodgo/models/order_item.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/services/system_config_service.dart';
import 'package:foodgo/services/voucher_service.dart';

/// Provider quản lý giỏ hàng của người dùng.
///
/// Ràng buộc nghiệp vụ: Một giỏ hàng chỉ thuộc về 1 nhà hàng tại một thời điểm.
/// Nếu người dùng thêm sản phẩm từ nhà hàng khác, hệ thống sẽ từ chối
/// hoặc yêu cầu xóa giỏ hàng cũ.
class CartProvider extends ChangeNotifier {
  final VoucherService _voucherService = VoucherService();
  final SystemConfigService _systemConfigService = SystemConfigService();
  final List<CartItem> _items = [];
  String? _restaurantId;
  String? _restaurantName;

  // Phí giao hàng động hệ thống (Mặc định 20.000đ)
  double _shippingFee = AppConstants.shippingFee;

  // Thông tin Voucher / Mã giảm giá
  String? _voucherCode;
  double _discountAmount = 0;
  String? _voucherError;

  CartProvider() {
    loadShippingFee();
  }

  /// Nạp phí giao hàng động từ Firestore SystemConfig
  Future<void> loadShippingFee() async {
    try {
      final config = await _systemConfigService.getConfig();
      if (_shippingFee != config.shippingFee) {
        _shippingFee = config.shippingFee;
        notifyListeners();
      }
    } catch (_) {}
  }

  List<CartItem> get items => List.unmodifiable(_items);
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  double get shippingFee => _shippingFee;
  String? get voucherCode => _voucherCode;
  double get discountAmount => _discountAmount;
  String? get voucherError => _voucherError;

  /// Tổng số lượng món trong giỏ
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Tạm tính tiền hàng (chưa bao gồm phí ship và giảm giá)
  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  /// Tổng tiền thanh toán cuối cùng (dùng phí giao hàng động từ Admin Config)
  double get finalTotal {
    final total = subtotal + _shippingFee - _discountAmount;
    return total < 0 ? 0 : total;
  }

  /// Kiểm tra giỏ hàng có rỗng không
  bool get isEmpty => _items.isEmpty;

  /// Thêm sản phẩm vào giỏ.
  /// Trả về `false` nếu sản phẩm thuộc nhà hàng khác với nhà hàng hiện tại trong giỏ.
  bool addItem(Product product, String restaurantName, {bool forceReplace = false}) {
    // Ràng buộc 1 nhà hàng
    if (_restaurantId != null &&
        _restaurantId!.isNotEmpty &&
        _restaurantId != product.restaurantId &&
        _items.isNotEmpty) {
      if (!forceReplace) {
        return false;
      }
      // Xóa giỏ cũ nếu người dùng đồng ý đổi nhà hàng
      clearCart();
    }

    _restaurantId = product.restaurantId;
    _restaurantName = restaurantName;

    final index = _items.indexWhere((item) {
      if (item.product.id.isNotEmpty && product.id.isNotEmpty) {
        return item.product.id == product.id;
      }
      return item.product.name == product.name;
    });

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
      _voucherError = null;
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
    _voucherError = null;
    notifyListeners();
  }

  /// Áp dụng mã giảm giá (Voucher) - Firestore lookup
  Future<bool> applyVoucher(String code) async {
    _voucherError = null;
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    try {
      final voucher = await _voucherService.getVoucherByCode(cleanCode);
      if (voucher != null) {
        if (voucher.remainingCount <= 0) {
          _voucherError = 'Mã "$cleanCode" đã hết số lượt sử dụng!';
          notifyListeners();
          return false;
        }
        if (subtotal < voucher.minOrderAmount) {
          _voucherError = 'Đơn hàng chưa đạt giá trị tối thiểu (${AppUtils.formatCurrency(voucher.minOrderAmount)})';
          notifyListeners();
          return false;
        }
        _voucherCode = voucher.code;
        _discountAmount = voucher.discountAmount;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _voucherError = 'Mã "$cleanCode" không tồn tại hoặc đã hết hạn!';
    notifyListeners();
    return false;
  }

  /// Hủy mã giảm giá
  void removeVoucher() {
    _voucherCode = null;
    _discountAmount = 0;
    _voucherError = null;
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