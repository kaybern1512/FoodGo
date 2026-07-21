import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef =>
      _firestore.collection(FirestoreCollections.users);

  /// Tạo tài liệu người dùng mới trong Firestore
  Future<void> createUser(AppUser user) async {
    try {
      await _usersRef.doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Không thể tạo tài khoản người dùng: $e');
    }
  }

  /// Lấy người dùng theo ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Không thể lấy thông tin người dùng: $e');
    }
  }

  /// Cập nhật thông tin người dùng
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersRef.doc(userId).update(data);
    } catch (e) {
      throw Exception('Không thể cập nhật thông tin: $e');
    }
  }

  /// Lấy tất cả người dùng (dành cho Admin)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _usersRef.get();
      final list = snapshot.docs
          .map((doc) =>
              AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw Exception('Không thể lấy danh sách người dùng: $e');
    }
  }

  /// Khóa / mở khóa tài khoản (dành cho Admin)
  Future<void> setUserActiveStatus(String userId, bool isActive) async {
    try {
      await _usersRef.doc(userId).update({'isActive': isActive});
    } catch (e) {
      throw Exception('Không thể thay đổi trạng thái tài khoản: $e');
    }
  }

  /// Cập nhật trạng thái Online/Offline (dành cho Shipper)
  Future<void> setOnlineStatus(String userId, bool isOnline) async {
    try {
      await _usersRef.doc(userId).update({'isOnline': isOnline});
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái: $e');
    }
  }

  /// Cập nhật biển số xe (dành cho Shipper)
  Future<void> updateVehiclePlate(String userId, String plate) async {
    try {
      await _usersRef.doc(userId).update({'vehiclePlate': plate});
    } catch (e) {
      throw Exception('Không thể cập nhật biển số xe: $e');
    }
  }

  /// Stream để lắng nghe thay đổi thông tin người dùng
  Stream<AppUser?> userStream(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }
}
