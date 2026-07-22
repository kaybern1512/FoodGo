import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/order_card.dart';
import 'package:foodgo/services/notification_service.dart';

class RestaurantOrdersScreen extends StatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  State<RestaurantOrdersScreen> createState() => _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends State<RestaurantOrdersScreen> {
  OrderProvider? _orderProvider;
  final Set<String> _knownOrderIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orderProvider = context.read<OrderProvider>();

      _loadOrders();

      _orderProvider!.addListener(_onOrdersChanged);
    });
  }

  Future<void> _loadOrders() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final restaurantProvider = context.read<RestaurantProvider>();
    if (restaurantProvider.myRestaurant == null) {
      await restaurantProvider.loadMyRestaurant(user.id);
    }
    final restaurant = restaurantProvider.myRestaurant;
    if (restaurant != null && mounted) {
      _orderProvider?.listenRestaurantOrders(restaurant.id);
    }
  }

  Future<void> _onOrdersChanged() async {
    if (!mounted || _orderProvider == null) return;

    final currentOrders = _orderProvider!.orders;
    final currentIds = currentOrders.map((order) => order.id).toSet();
    final newOrderIds = currentIds.difference(_knownOrderIds);

    final hasNewPendingOrder = currentOrders.any(
      (order) =>
          newOrderIds.contains(order.id) &&
          order.orderStatus == OrderStatus.pending,
    );

    if (_isInitialized && hasNewPendingOrder) {
      await NotificationService.playNewOrderSound();

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔔 Có đơn hàng mới"),
          duration: Duration(seconds: 3),
        ),
      );
    }

    _knownOrderIds.clear();
    _knownOrderIds.addAll(currentIds);
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final activeOrders = orderProvider.orders
        .where((o) =>
            o.orderStatus == OrderStatus.pending ||
            o.orderStatus == OrderStatus.confirmed ||
            o.orderStatus == OrderStatus.preparing)
        .toList();
    final completedOrders = orderProvider.orders
        .where((o) =>
            o.orderStatus == OrderStatus.completed ||
            o.orderStatus == OrderStatus.cancelled ||
            o.orderStatus == OrderStatus.rejected ||
            o.orderStatus == OrderStatus.waitingForShipper ||
            o.orderStatus == OrderStatus.delivering)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn hàng'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Đang xử lý'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: orderProvider.isLoading
            ? const LoadingWidget()
            : TabBarView(
                children: [
                  _buildOrderList(context, activeOrders, 'Không có đơn mới'),
                  _buildOrderList(
                      context, completedOrders, 'Chưa có lịch sử đơn hàng'),
                ],
              ),
      ),
    );
  }

  Widget _buildOrderList(
      BuildContext context, List orders, String emptyMessage) {
    if (orders.isEmpty) {
      return EmptyStateWidget(
        message: emptyMessage,
        icon: Icons.receipt_long_outlined,
        actionLabel: 'Làm mới',
        onAction: _loadOrders,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OrderCard(
              order: order,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.restaurantOrderDetail,
                arguments: order,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _orderProvider?.removeListener(_onOrdersChanged);
    super.dispose();
  }
}
