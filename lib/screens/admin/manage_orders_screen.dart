import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

import 'package:foodgo/core/enums/order_status.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  OrderStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  void _showOrderDetailModal(BuildContext context, FoodOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết đơn #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      OrderStatusChip(status: order.orderStatus),
                    ],
                  ),
                  const Divider(height: 24),
                  _row('Khách hàng', order.customerName),
                  _row('Số điện thoại', order.customerPhone),
                  _row('Địa chỉ giao', order.deliveryAddress),
                  if (order.note.isNotEmpty) _row('Ghi chú', order.note),
                  const Divider(height: 24),
                  const Text('Sản phẩm',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${item.quantity}x ${item.productName}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const Spacer(),
                          Text(AppUtils.formatCurrency(item.totalPrice)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _row('Thanh toán', order.paymentMethod.toVietnamese()),
                  _row('Trạng thái TT', order.paymentStatus.toVietnamese()),
                  _row('Tạm tính', AppUtils.formatCurrency(order.subtotal)),
                  _row('Phí giao hàng',
                      AppUtils.formatCurrency(order.shippingFee)),
                  _row('Tổng cộng', AppUtils.formatCurrency(order.totalAmount),
                      isBold: true),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final filteredOrders = orderProvider.orders.where((o) {
      if (_selectedStatusFilter == null) return true;
      return o.orderStatus == _selectedStatusFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Đơn hàng (${filteredOrders.length}/${orderProvider.orders.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderProvider.loadAllOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedStatusFilter == null,
                  onSelected: (_) =>
                      setState(() => _selectedStatusFilter = null),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Chờ xác nhận'),
                  selected: _selectedStatusFilter == OrderStatus.pending,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.pending),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Chờ shipper'),
                  selected:
                      _selectedStatusFilter == OrderStatus.waitingForShipper,
                  onSelected: (_) => setState(() => _selectedStatusFilter =
                      OrderStatus.waitingForShipper),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Đang giao'),
                  selected: _selectedStatusFilter == OrderStatus.delivering,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.delivering),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Hoàn thành'),
                  selected: _selectedStatusFilter == OrderStatus.completed,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.completed),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Đã hủy'),
                  selected: _selectedStatusFilter == OrderStatus.cancelled,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.cancelled),
                ),
              ],
            ),
          ),
          Expanded(
            child: orderProvider.isLoading
                ? const LoadingWidget()
                : filteredOrders.isEmpty
                    ? const EmptyStateWidget(
                        message: 'Không có đơn hàng nào phù hợp',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _showOrderDetailModal(context, order),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${order.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  OrderStatusChip(status: order.orderStatus),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.customerName,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                              Text(
                                '${order.items.length} món • ${AppUtils.formatCurrency(order.totalAmount)}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              Text(
                                AppUtils.formatDateTime(order.createdAt),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary),
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
