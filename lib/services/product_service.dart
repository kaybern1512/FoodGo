import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _productsRef =>
      _firestore.collection(FirestoreCollections.products);

  /// Tạo sản phẩm mới
  Future<String> createProduct(Product product) async {
    try {
      final docRef = await _productsRef.add(product.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo sản phẩm: $e');
    }
  }

  /// Lấy danh sách sản phẩm theo nhà hàng
  Future<List<Product>> getProductsByRestaurant(String restaurantId) async {
    try {
      final snapshot = await _productsRef
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách sản phẩm: $e');
    }
  }

  /// Lấy tất cả sản phẩm (dành cho Admin)
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot =
          await _productsRef.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách sản phẩm: $e');
    }
  }

  /// Cập nhật sản phẩm
  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      await _productsRef.doc(productId).update(data);
    } catch (e) {
      throw Exception('Không thể cập nhật sản phẩm: $e');
    }
  }

  /// Xóa sản phẩm
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsRef.doc(productId).delete();
    } catch (e) {
      throw Exception('Không thể xóa sản phẩm: $e');
    }
  }

  /// Bật/tắt trạng thái sẵn có của sản phẩm
  Future<void> setAvailability(String productId, bool isAvailable) async {
    try {
      await _productsRef.doc(productId).update({'isAvailable': isAvailable});
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái sản phẩm: $e');
    }
  }

  /// Tìm kiếm sản phẩm theo tên
  Future<List<Product>> searchProducts(String query) async {
    try {
      // Simple client-side search - for production use Algolia/Typesense
      final snapshot =
          await _productsRef.where('isAvailable', isEqualTo: true).get();
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) =>
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((p) => p.name.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('Không thể tìm kiếm sản phẩm: $e');
    }
  }
}
