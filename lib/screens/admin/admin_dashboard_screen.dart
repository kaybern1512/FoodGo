import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/services/seed_service.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserService _userService = UserService();
  final SeedService _seedService = SeedService();
  int _totalUsers = 0;
  bool _isLoading = true;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _totalUsers = users.length;
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
            content: Text('Khởi tạo toàn bộ dữ liệu ảo (Nhà hàng, Món ăn, Đơn hàng) thành công!'),
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

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (_isLoading || _isSeeding) return const Scaffold(body: LoadingWidget(message: 'Đang xử lý dữ liệu...'));

    final completedRevenue = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .fold<double>(0, (sum, o) => sum + o.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị FoodGo'),
        actions: [
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tạo dữ liệu ảo',
                    icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
                    onPressed: _seedSystemDemoData,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Tạo dữ liệu ảo toàn hệ thống',
                icon: Icons.dataset,
                isOutlined: true,
                onPressed: _seedSystemDemoData,
                isLoading: _isSeeding,
              ),
              const SizedBox(height: 16),
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
                  _StatCard(
                    label: 'Đơn đang giao',
                    value:
                        '${orderProvider.orders.where((o) => o.orderStatus == OrderStatus.delivering).length}',
                    icon: Icons.directions_bike,
                    color: Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
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
                    fontSize: 26,
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
