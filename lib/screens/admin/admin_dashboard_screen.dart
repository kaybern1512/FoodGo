import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/system_config.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/services/seed_service.dart';
import 'package:foodgo/services/system_config_service.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserService _userService = UserService();
  final SeedService _seedService = SeedService();
  final SystemConfigService _configService = SystemConfigService();
  int _totalUsers = 0;
  bool _isLoading = true;
  bool _isSeeding = false;
  SystemConfig _currentConfig = const SystemConfig(
    shippingFee: 20000.0,
    commissionRate: 10.0,
    systemMaintenance: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      final config = await _configService.getConfig();
      setState(() {
        _totalUsers = users.length;
        _currentConfig = config;
        _isLoading = false;
      });
      if (!mounted) return;
      await Future.wait([
        context.read<RestaurantProvider>().loadAllRestaurants(),
        context.read<ProductProvider>().loadAllProducts(),
        context.read<OrderProvider>().loadAllOrders(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seedSystemDemoData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSeeding = true);
    try {
      await _seedService.seedFullSystemDemoData(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Khởi tạo toàn bộ dữ liệu ảo (Nhà hàng, Món ăn, Đơn hàng) thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khởi tạo dữ liệu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  /// Xuất báo cáo danh sách đơn hàng sang định dạng CSV & sao chép vào Clipboard
  void _exportCSVReport() {
    final orderProvider = context.read<OrderProvider>();
    final orders = orderProvider.orders;

    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chưa có dữ liệu đơn hàng để xuất báo cáo!'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
        'Mã Đơn,Khách Hàng,Số Điện Thoại,Tổng Tiền,Trạng Thái,Ngày Tạo');

    for (var o in orders) {
      final code = '#${o.id.substring(0, 8).toUpperCase()}';
      final name = o.customerName.replaceAll(',', ' ');
      final phone = o.customerPhone;
      final amount = o.totalAmount;
      final status = o.orderStatus.toVietnamese();
      final date = AppUtils.formatDateTime(o.createdAt);
      buffer.writeln('$code,$name,$phone,$amount,$status,$date');
    }

    final csvString = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvString));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Báo cáo doanh thu CSV'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Đã tạo báo cáo thành công và sao chép vào bộ nhớ đệm (Clipboard)!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvString,
                  style: const TextStyle(
                      fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            icon: const Icon(Icons.copy, size: 16, color: Colors.white),
            label: const Text('Sao chép lại',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvString));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Đã sao chép báo cáo CSV!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Mở modal chỉnh sửa Phí giao hàng & Tỷ lệ hoa hồng
  void _showSystemConfigModal() {
    final feeCtrl = TextEditingController(
        text: _currentConfig.shippingFee.toStringAsFixed(0));
    final rateCtrl = TextEditingController(
        text: _currentConfig.commissionRate.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Cấu hình Hệ thống'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Phí giao hàng (VNĐ)',
                prefixIcon: Icon(Icons.delivery_dining),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tỷ lệ hoa hồng hệ thống (%)',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () async {
              final newFee = double.tryParse(feeCtrl.text.trim()) ?? 20000.0;
              final newRate = double.tryParse(rateCtrl.text.trim()) ?? 10.0;

              final updatedConfig = SystemConfig(
                shippingFee: newFee,
                commissionRate: newRate,
                systemMaintenance: false,
              );

              await _configService.updateConfig(updatedConfig);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() => _currentConfig = updatedConfig);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Cập nhật cấu hình Phí ship & Hoa hồng thành công!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Lưu cấu hình',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (_isLoading || _isSeeding) {
      return const Scaffold(
          body: LoadingWidget(message: 'Đang xử lý dữ liệu...'));
    }

    final completedRevenue = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị FoodGo'),
        actions: [
          IconButton(
            tooltip: 'Xuất Báo Cáo CSV',
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportCSVReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng quan hệ thống',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tạo dữ liệu ảo',
                    icon: const Icon(Icons.auto_awesome,
                        color: AppColors.primary),
                    onPressed: _seedSystemDemoData,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.dataset, size: 18),
                      label: const Text('Tạo dữ liệu ảo',
                          style: TextStyle(fontSize: 13)),
                      onPressed: _seedSystemDemoData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.download,
                          size: 18, color: Colors.white),
                      label: const Text('Xuất CSV',
                          style: TextStyle(
                              color: Colors.white, fontSize: 13)),
                      onPressed: _exportCSVReport,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Cấu hình Phí Ship & Hoa hồng Banner ──
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                ),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.settings,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cấu hình hệ thống',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            Text(
                              'Phí ship: ${AppUtils.formatCurrency(_currentConfig.shippingFee)}  •  Hoa hồng: ${_currentConfig.commissionRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showSystemConfigModal,
                        child: const Text('Đổi',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Grid Thống Kê
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _StatCard(
                    label: 'Người dùng',
                    value: '$_totalUsers',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    label: 'Nhà hàng',
                    value: '${restaurantProvider.restaurants.length}',
                    icon: Icons.store,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    label: 'Sản phẩm',
                    value: '${productProvider.products.length}',
                    icon: Icons.fastfood,
                    color: Colors.purple,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.manageProducts),
                  ),
                  _StatCard(
                    label: 'Mã Giảm Giá',
                    value: 'Voucher',
                    icon: Icons.confirmation_number,
                    color: Colors.pink,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.manageVouchers),
                  ),
                  _StatCard(
                    label: 'Tất cả đơn hàng',
                    value: '${orderProvider.orders.length}',
                    icon: Icons.receipt_long,
                    color: Colors.teal,
                  ),
                  _StatCard(
                    label: 'Đơn chờ shipper',
                    value:
                        '${orderProvider.orders.where((o) => o.orderStatus == OrderStatus.waitingForShipper).length}',
                    icon: Icons.access_time_filled,
                    color: Colors.amber.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Card Tổng Doanh Thu
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.monetization_on,
                            color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng doanh thu đã hoàn thành',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          Text(
                            AppUtils.formatCurrency(completedRevenue),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color),
              ),
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
