import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/models/system_config.dart';

class SystemConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentReference get _configDoc =>
      _firestore.collection('system_config').doc('settings');

  /// Lấy cấu hình hệ thống hiện tại
  Future<SystemConfig> getConfig() async {
    try {
      final doc = await _configDoc.get();
      if (!doc.exists) {
        return const SystemConfig(
          shippingFee: 20000.0,
          commissionRate: 10.0,
          systemMaintenance: false,
        );
      }
      return SystemConfig.fromMap(doc.data() as Map<String, dynamic>?);
    } catch (_) {
      return const SystemConfig(
        shippingFee: 20000.0,
        commissionRate: 10.0,
        systemMaintenance: false,
      );
    }
  }

  /// Cập nhật cấu hình hệ thống
  Future<void> updateConfig(SystemConfig config) async {
    await _configDoc.set(config.toMap(), SetOptions(merge: true));
  }
}
