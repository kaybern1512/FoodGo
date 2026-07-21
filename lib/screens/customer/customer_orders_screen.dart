import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/order_card.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<OrderProvider>().loadCustomerOrders(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final activeStatuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.waitingForShipper,
      OrderStatus.delivering,
    ];

    final activeOrders = orderProvider.orders
        .where((o) => activeStatuses.contains(o.orderStatus))
        .toList();
    final historyOrders = orderProvider.orders
        .where((o) => !activeStatuses.contains(o.orderStatus))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Đang xử lý'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: orderProvider.isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab đơn đang xử lý
                activeOrders.isEmpty
                    ? const EmptyStateWidget(
                        message: 'Không có đơn hàng nào đang xử lý',
                        icon: Icons.receipt_long_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () {
                          final user =
                              context.read<AuthProvider>().currentUser;
                          return context
                              .read<OrderProvider>()
                              .loadCustomerOrders(user!.id);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(
                              AppConstants.defaultPadding),
                          itemCount: activeOrders.length,
                          itemBuilder: (context, index) {
                            final order = activeOrders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OrderCard(
                                order: order,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.orderDetail,
                                  arguments: order,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                // Tab lịch sử
                historyOrders.isEmpty
                    ? const EmptyStateWidget(
                        message: 'Chưa có lịch sử đơn hàng',
                        icon: Icons.history,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(
                            AppConstants.defaultPadding),
                        itemCount: historyOrders.length,
                        itemBuilder: (context, index) {
                          final order = historyOrders[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OrderCard(
                              order: order,
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.orderDetail,
                                arguments: order,
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
