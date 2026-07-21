import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload ảnh sản phẩm
  Future<String> uploadProductImage(File imageFile, String restaurantId) async {
    try {
      final extension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$extension';
      final ref = _storage.ref().child('products/$restaurantId/$fileName');
      final TaskSnapshot snapshot = await ref.putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Không thể upload ảnh sản phẩm: $e');
    }
  }

  /// Upload ảnh nhà hàng
  Future<String> uploadRestaurantImage(File imageFile, String restaurantId) async {
    try {
      final extension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$extension';
      final ref = _storage.ref().child('restaurants/$restaurantId/$fileName');
      final TaskSnapshot snapshot = await ref.putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Không thể upload ảnh nhà hàng: $e');
    }
  }

  /// Upload ảnh avatar người dùng
  Future<String> uploadUserAvatar(File imageFile, String userId) async {
    try {
      final extension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$extension';
      final ref = _storage.ref().child('avatars/$userId/$fileName');
      final TaskSnapshot snapshot = await ref.putFile(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Không thể upload ảnh đại diện: $e');
    }
  }

  /// Xóa file theo URL
  Future<void> deleteFileByUrl(String downloadUrl) async {
    try {
      if (downloadUrl.isEmpty) return;
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // Ignored if file doesn't exist
    }
  }
}
