import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/services/seed_service.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  final SeedService _seedService = SeedService();
  bool _isSeeding = false;
  String _selectedFilter = 'day';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final restaurantProvider = context.read<RestaurantProvider>();
    await restaurantProvider.loadMyRestaurant(user.id);
    final restaurant = restaurantProvider.myRestaurant;
    if (restaurant != null && mounted) {
      await context.read<OrderProvider>().loadRestaurantOrders(restaurant.id);
    }
  }

  Future<void> _seedSampleData() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSeeding = true);
    try {
      await _seedService.seedRestaurantAndProducts(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Khởi tạo nhà hàng & 5 món ăn mẫu thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadData();
        final restaurant = context.read<RestaurantProvider>().myRestaurant;
        if (restaurant != null && mounted) {
          await context
              .read<ProductProvider>()
              .loadProductsByRestaurant(restaurant.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi khởi tạo: $e'),
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
    final orderProvider = context.watch<OrderProvider>();
    final restaurant = restaurantProvider.myRestaurant;

    if (restaurantProvider.isLoading || _isSeeding) {
      return const Scaffold(
          body: LoadingWidget(message: 'Đang xử lý dữ liệu...'));
    }

    if (restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tổng quan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store_outlined,
                    size: 80, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'Bạn chưa có dữ liệu nhà hàng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhấn nút bên dưới để tự động tạo nhà hàng mẫu "Cơm Tấm Sài Gòn" kèm 5 món ăn mẫu vào Firestore',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Tạo nhà hàng & món ăn mẫu (Seed Data)',
                  icon: Icons.auto_awesome,
                  onPressed: _seedSampleData,
                  isLoading: _isSeeding,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pendingOrders = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.pending)
        .length;
    final completedOrders = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .length;
    final now = DateTime.now();

    final revenueOrders = orderProvider.orders.where((o) {
      if (o.orderStatus != OrderStatus.completed) {
        return false;
      }

      switch (_selectedFilter) {
        case 'day':
          return o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day;

        case 'week':
          return now.difference(o.createdAt).inDays < 7;

        case 'month':
          return o.createdAt.year == now.year && o.createdAt.month == now.month;

        default:
          return true;
      }
    }).toList();

    final totalRevenue =
        revenueOrders.fold<double>(0, (sum, o) => sum + o.subtotal);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        actions: [
          Switch(
            value: restaurant.isOpen,
            onChanged: (value) =>
                restaurantProvider.toggleOpenStatus(restaurant.id, value),
            activeColor: Colors.white,
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
              // Trạng thái nhà hàng
              Card(
                color: restaurant.isApproved
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    children: [
                      Icon(
                        restaurant.isApproved
                            ? Icons.check_circle
                            : Icons.pending,
                        color: restaurant.isApproved
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        restaurant.isApproved
                            ? 'Nhà hàng đã được phê duyệt'
                            : 'Đang chờ phê duyệt',
                        style: TextStyle(
                          color: restaurant.isApproved
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Trạng thái mở cửa
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Row(
                    children: [
                      Icon(
                        restaurant.isOpen ? Icons.store : Icons.store_outlined,
                        color: restaurant.isOpen
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        restaurant.isOpen ? 'Đang mở cửa' : 'Đã đóng cửa',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      const Text(
                        'Công tắc ở thanh góc trên',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thống kê hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Đơn chờ',
                          value: '$pendingOrders',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Hoàn thành',
                          value: '$completedOrders',
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    label: 'Doanh thu',
                    value: AppUtils.formatCurrency(totalRevenue),
                    icon: Icons.attach_money,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('Ngày'),
                        selected: _selectedFilter == 'day',
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = 'day';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Tuần'),
                        selected: _selectedFilter == 'week',
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = 'week';
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Tháng'),
                        selected: _selectedFilter == 'month',
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = 'month';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: totalRevenue > 0 ? totalRevenue * 1.2 : 100000,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval:
                                  totalRevenue > 0 ? totalRevenue / 5 : 20000,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value / 1000).toInt()}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                List<String> labels;

                                switch (_selectedFilter) {
                                  case 'day':
                                    labels = [
                                      '0h',
                                      '4h',
                                      '8h',
                                      '12h',
                                      '16h',
                                      '20h'
                                    ];
                                    break;

                                  case 'week':
                                    labels = [
                                      'T2',
                                      'T3',
                                      'T4',
                                      'T5',
                                      'T6',
                                      'T7',
                                      'CN'
                                    ];
                                    break;

                                  case 'month':
                                    labels = [
                                      'Tuần 1',
                                      'Tuần 2',
                                      'Tuần 3',
                                      'Tuần 4'
                                    ];
                                    break;

                                  default:
                                    labels = [];
                                }

                                if (value.toInt() < 0 ||
                                    value.toInt() >= labels.length) {
                                  return const SizedBox();
                                }

                                return Text(
                                  labels[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: _buildChartData(
                          revenueOrders,
                          _selectedFilter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<BarChartGroupData> _buildChartData(
  List<dynamic> orders,
  String filter,
) {
  final values = filter == 'month'
      ? List<double>.filled(4, 0)
      : filter == 'day'
          ? List<double>.filled(6, 0)
          : List<double>.filled(7, 0);

  final now = DateTime.now();

  for (final order in orders) {
    switch (filter) {
      case 'day':
        final slot = order.createdAt.hour ~/ 4;
        if (slot >= 0 && slot < 6) {
          values[slot] += order.subtotal;
        }
        break;

      case 'week':
        final diff = now.difference(order.createdAt).inDays;
        if (diff >= 0 && diff < 7) {
          values[6 - diff] += order.subtotal;
        }
        break;

      case 'month':
        final week = ((order.createdAt.day - 1) / 7).floor();
        if (week >= 0 && week < 4) {
          values[week] += order.subtotal;
        }
        break;
    }
  }

  return List.generate(
    values.length,
    (index) => BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: values[index],
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    ),
  );
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
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
