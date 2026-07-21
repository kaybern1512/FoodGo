import 'package:flutter/material.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/services/product_service.dart';

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

  /// Lấy sản phẩm theo nhà hàng
  Future<void> loadProductsByRestaurant(String restaurantId) async {
    _setLoading(true);
    _setError(null);
    try {
      _products = await _productService.getProductsByRestaurant(restaurantId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Lấy tất cả sản phẩm (Admin)
  Future<void> loadAllProducts() async {
    _setLoading(true);
    _setError(null);
    try {
      _products = await _productService.getAllProducts();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Tìm kiếm sản phẩm
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    _setError(null);
    try {
      _searchResults = await _productService.searchProducts(query);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Tạo sản phẩm mới
  Future<bool> createProduct(Product product) async {
    _setLoading(true);
    _setError(null);
    try {
      final id = await _productService.createProduct(product);
      _products.add(product.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật sản phẩm
  Future<bool> updateProduct(
      String productId, Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
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

  /// Xóa sản phẩm
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _productService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bật / tắt trạng thái sẵn có
  Future<bool> toggleAvailability(String productId, bool isAvailable) async {
    _setError(null);
    try {
      await _productService.setAvailability(productId, isAvailable);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isAvailable: isAvailable);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
