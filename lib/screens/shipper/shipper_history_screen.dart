import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

class ShipperHistoryScreen extends StatefulWidget {
  const ShipperHistoryScreen({super.key});

  @override
  State<ShipperHistoryScreen> createState() => _ShipperHistoryScreenState();
}

class _ShipperHistoryScreenState extends State<ShipperHistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final historyOrders = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .toList();

    final totalEarnings = historyOrders.fold<double>(
        0, (sum, o) => sum + o.shippingFee);

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao hàng')),
      body: orderProvider.isLoading
          ? const LoadingWidget()
          : historyOrders.isEmpty
              ? const EmptyStateWidget(
                  message: 'Chưa có lịch sử giao hàng',
                  icon: Icons.history,
                )
              : Column(
                  children: [
                    // Tổng thu nhập
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      color: AppColors.primary,
                      child: Column(
                        children: [
                          const Text(
                            'Tổng thu nhập',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppUtils.formatCurrency(totalEarnings),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${historyOrders.length} đơn hoàn thành',
                            style:
                                const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: historyOrders.length,
                        itemBuilder: (context, index) {
                          final order = historyOrders[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.shipperOrderDetail,
                                arguments: order,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '#${order.id.substring(0, 8).toUpperCase()}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            order.deliveryAddress,
                                            style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            AppUtils.formatDateTime(
                                                order.createdAt),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppUtils.formatCurrency(order.shippingFee),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        OrderStatusChip(status: order.orderStatus),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
