import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/voucher.dart';

class VoucherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _vouchersRef =>
      _firestore.collection(FirestoreCollections.vouchers);

  /// Lấy tất cả voucher (dành cho Admin)
  Future<List<Voucher>> getAllVouchers() async {
    try {
      final snapshot = await _vouchersRef.get();
      final vouchers = snapshot.docs
          .map((doc) =>
              Voucher.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vouchers;
    } catch (e) {
      throw Exception('Không thể lấy danh sách voucher: $e');
    }
  }

  /// Lấy danh sách voucher đang hoạt động và còn lượt sử dụng (Khách hàng)
  Future<List<Voucher>> getActiveVouchers() async {
    try {
      final snapshot = await _vouchersRef.get();
      final vouchers = snapshot.docs
          .map((doc) =>
              Voucher.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((v) => v.isActive && v.remainingCount > 0)
          .toList();
      vouchers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return vouchers;
    } catch (e) {
      return [];
    }
  }

  /// Kiểm tra mã voucher theo Code trực tiếp từ Firestore
  Future<Voucher?> getVoucherByCode(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final snapshot = await _vouchersRef
          .where('code', isEqualTo: cleanCode)
          .get();
      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final voucher = Voucher.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      return (voucher.isActive && voucher.remainingCount > 0) ? voucher : null;
    } catch (e) {
      return null;
    }
  }

  /// Tăng lượt sử dụng voucher khi đặt hàng thành công
  Future<void> incrementVoucherUsedCount(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final snapshot = await _vouchersRef
          .where('code', isEqualTo: cleanCode)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final docRef = snapshot.docs.first.reference;
        await docRef.update({'usedCount': FieldValue.increment(1)});
      }
    } catch (_) {}
  }

  /// Admin tạo voucher mới trên Firestore
  Future<String> createVoucher(Voucher voucher) async {
    try {
      final docRef = await _vouchersRef.add(voucher.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo voucher: $e');
    }
  }

  /// Admin cập nhật voucher
  Future<void> updateVoucher(
      String voucherId, Map<String, dynamic> data) async {
    try {
      await _vouchersRef.doc(voucherId).update(data);
    } catch (e) {
      throw Exception('Không thể cập nhật voucher: $e');
    }
  }

  /// Admin bật/tắt hoặc xóa voucher
  Future<void> toggleVoucherStatus(String voucherId, bool isActive) async {
    try {
      await _vouchersRef.doc(voucherId).update({'isActive': isActive});
    } catch (e) {
      throw Exception('Không thể cập nhật trạng thái voucher: $e');
    }
  }

  /// Admin xóa voucher
  Future<void> deleteVoucher(String voucherId) async {
    try {
      await _vouchersRef.doc(voucherId).delete();
    } catch (e) {
      throw Exception('Không thể xóa voucher: $e');
    }
  }
}
