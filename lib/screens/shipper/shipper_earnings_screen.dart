import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ShipperEarningsScreen extends StatefulWidget {
  const ShipperEarningsScreen({super.key});

  @override
  State<ShipperEarningsScreen> createState() => _ShipperEarningsScreenState();
}

class _ShipperEarningsScreenState extends State<ShipperEarningsScreen> {
  int _filterPeriod = 0; // 0: Hôm nay, 1: 7 Ngày qua, 2: Tất cả

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<OrderProvider>().loadShipperOrders(user.id);
      }
    });
  }

  void _showWithdrawDialog(BuildContext context, double currentBalance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Rút tiền về ví/NH'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số dư khả dụng: ${AppUtils.formatCurrency(currentBalance)}'),
            const SizedBox(height: 12),
            const Text(
              'Yêu cầu rút tiền sẽ được bộ phận Kế toán FoodGo xử lý trong vòng 24h làm việc.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: currentBalance <= 0
                ? null
                : () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '✅ Đã gửi yêu cầu rút tiền thành công! Vui lòng chờ đối soát.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
            child: const Text('Xác nhận rút tiền'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    final completedOrders = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .toList();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(const Duration(days: 7));

    // Lọc theo mốc thời gian
    List<FoodOrder> filteredOrders;
    if (_filterPeriod == 0) {
      filteredOrders = completedOrders
          .where((o) => o.createdAt.isAfter(todayStart))
          .toList();
    } else if (_filterPeriod == 1) {
      filteredOrders = completedOrders
          .where((o) => o.createdAt.isAfter(weekStart))
          .toList();
    } else {
      filteredOrders = completedOrders;
    }

    final totalShippingEarnings =
        completedOrders.fold<double>(0, (sum, o) => sum + o.shippingFee);
    final filteredEarnings =
        filteredOrders.fold<double>(0, (sum, o) => sum + o.shippingFee);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví thu nhập Shipper'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (user != null) {
                orderProvider.loadShipperOrders(user.id);
              }
            },
          ),
        ],
      ),
      body: orderProvider.isLoading
          ? const LoadingWidget(message: 'Đang tính toán thu nhập...')
          : RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  await orderProvider.loadShipperOrders(user.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Card Tổng Thu Nhập / Ví ──
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                      ),
                      color: AppColors.primary,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_wallet,
                                    color: Colors.white70, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Tổng thu nhập tích lũy',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppUtils.formatCurrency(totalShippingEarnings),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã hoàn thành tổng cộng ${completedOrders.length} chuyến giao',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Rút tiền về tài khoản'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _showWithdrawDialog(
                                    context, totalShippingEarnings),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Thanh lọc thời gian ──
                    const Text('Chi tiết thu nhập',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'Hôm nay',
                          isSelected: _filterPeriod == 0,
                          onTap: () => setState(() => _filterPeriod = 0),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: '7 ngày qua',
                          isSelected: _filterPeriod == 1,
                          onTap: () => setState(() => _filterPeriod = 1),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Tất cả',
                          isSelected: _filterPeriod == 2,
                          onTap: () => setState(() => _filterPeriod = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Summary Card khoảng thời gian được chọn ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppConstants.defaultRadius),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _filterPeriod == 0
                                    ? 'Thu nhập hôm nay'
                                    : (_filterPeriod == 1
                                        ? 'Thu nhập 7 ngày qua'
                                        : 'Tổng thu nhập'),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              Text(
                                AppUtils.formatCurrency(filteredEarnings),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Chip(
                            avatar: const Icon(Icons.check_circle,
                                size: 16, color: AppColors.success),
                            label: Text(
                              '${filteredOrders.length} đơn',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Danh sách lịch sử đơn thu nhập ──
                    if (filteredOrders.isEmpty)
                      const EmptyStateWidget(
                        message: 'Chưa có đơn hàng nào trong mốc thời gian này',
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFE8F5E9),
                                child: Icon(Icons.add, color: AppColors.success),
                              ),
                              title: Text(
                                '#${order.id.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${order.deliveryAddress}\n${AppUtils.formatDateTime(order.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${AppUtils.formatCurrency(order.shippingFee)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    'Tiền ship',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      showCheckmark: false,
    );
  }
}
