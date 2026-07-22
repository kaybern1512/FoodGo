class SystemConfig {
  final double shippingFee;
  final double commissionRate;
  final bool systemMaintenance;

  const SystemConfig({
    required this.shippingFee,
    required this.commissionRate,
    required this.systemMaintenance,
  });

  factory SystemConfig.fromMap(Map<String, dynamic>? map) {
    return SystemConfig(
      shippingFee: (map?['shippingFee'] as num?)?.toDouble() ?? 20000.0,
      commissionRate: (map?['commissionRate'] as num?)?.toDouble() ?? 10.0,
      systemMaintenance: map?['systemMaintenance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shippingFee': shippingFee,
      'commissionRate': commissionRate,
      'systemMaintenance': systemMaintenance,
    };
  }
}
