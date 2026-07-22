import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/services/product_service.dart';

/// ProductProvider với notifyListeners() an toàn:
/// Luôn defer notify ra khỏi build frame bằng SchedulerBinding.
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
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

  /// Lấy sản phẩm theo nhà hàng
  Future<void> loadProductsByRestaurant(String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      _products = await _productService.getProductsByRestaurant(restaurantId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Lấy tất cả sản phẩm (Admin)
  Future<void> loadAllProducts() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      _products = await _productService.getAllProducts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Tìm kiếm sản phẩm (Nêu query rỗng, tự động tải tất cả sản phẩm khả dụng)
  Future<void> searchProducts(String query) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      if (query.trim().isEmpty) {
        final all = await _productService.getAllProducts();
        _searchResults = all.where((p) => p.isAvailable).toList();
      } else {
        _searchResults = await _productService.searchProducts(query);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Tạo sản phẩm mới
  Future<bool> createProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final id = await _productService.createProduct(product);
      _products.add(product.copyWith(id: id));
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

  /// Cập nhật sản phẩm
  Future<bool> updateProduct(
      String productId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await _productService.updateProduct(productId, data);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updated = _products[index];
        _products[index] = Product(
          id: updated.id,
          restaurantId: data['restaurantId'] as String? ?? updated.restaurantId,
          name: data['name'] as String? ?? updated.name,
          description: data['description'] as String? ?? updated.description,
          category: data['category'] as String? ?? updated.category,
          price: (data['price'] as num?)?.toDouble() ?? updated.price,
          imageUrl: data['imageUrl'] as String? ?? updated.imageUrl,
          isAvailable: data['isAvailable'] as bool? ?? updated.isAvailable,
          createdAt: updated.createdAt,
        );
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

  /// Xóa sản phẩm
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      await _productService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
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

  /// Bật / tắt trạng thái sẵn có
  Future<bool> toggleAvailability(String productId, bool isAvailable) async {
    _errorMessage = null;
    try {
      await _productService.setAvailability(productId, isAvailable);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isAvailable: isAvailable);
        _safeNotify();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    _safeNotify();
  }
}
