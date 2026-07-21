import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class RestaurantRevenueScreen extends StatefulWidget {
  const RestaurantRevenueScreen({super.key});

  @override
  State<RestaurantRevenueScreen> createState() =>
      _RestaurantRevenueScreenState();
}

class _RestaurantRevenueScreenState extends State<RestaurantRevenueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final restaurantProvider = context.read<RestaurantProvider>();
    if (restaurantProvider.myRestaurant == null) {
      await restaurantProvider.loadMyRestaurant(user.id);
    }
    final restaurant = restaurantProvider.myRestaurant;
    if (restaurant != null && mounted) {
      await context.read<OrderProvider>().loadRestaurantOrders(restaurant.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    final completedOrders = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .toList();

    final totalRevenue =
        completedOrders.fold<double>(0, (sum, o) => sum + o.subtotal);
    final totalOrders = completedOrders.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Doanh thu')),
      body: completedOrders.isEmpty
          ? const EmptyStateWidget(
              message: 'Chưa có đơn hàng hoàn thành nào',
              icon: Icons.bar_chart,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Tổng đơn hoàn thành',
                          value: '$totalOrders',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Tổng doanh thu',
                          value: AppUtils.formatCurrency(totalRevenue),
                          icon: Icons.attach_money,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đơn hàng đã hoàn thành',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...completedOrders.map(
                    (order) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${order.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    AppUtils.formatDateTime(order.createdAt),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppUtils.formatCurrency(order.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
