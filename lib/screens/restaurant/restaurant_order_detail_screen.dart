import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

class RestaurantOrderDetailScreen extends StatelessWidget {
  const RestaurantOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order =
        ModalRoute.of(context)?.settings.arguments as FoodOrder?;
    if (order == null) {
      return const Scaffold(
          body: Center(child: Text('Không tìm thấy đơn hàng')));
    }

    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    OrderStatusChip(status: order.orderStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Thông tin khách hàng
            _SectionCard(
              title: 'Khách hàng',
              children: [
                _InfoRow(label: 'Tên', value: order.customerName),
                _InfoRow(label: 'ĐT', value: order.customerPhone),
                _InfoRow(label: 'Địa chỉ', value: order.deliveryAddress),
                if (order.note.isNotEmpty)
                  _InfoRow(label: 'Ghi chú', value: order.note),
              ],
            ),
            const SizedBox(height: 12),
            // Sản phẩm
            _SectionCard(
              title: 'Sản phẩm',
              children: order.items
                  .map((item) => _InfoRow(
                        label: '${item.quantity}x ${item.productName}',
                        value: AppUtils.formatCurrency(item.totalPrice),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            // Tổng tiền
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Tổng cộng',
                      value: AppUtils.formatCurrency(order.totalAmount),
                      isBold: true,
                    ),
                    _InfoRow(
                      label: 'Thanh toán',
                      value: order.paymentMethod.toVietnamese(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Nút hành động
            _buildActionButtons(context, order, orderProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, FoodOrder order,
      OrderProvider orderProvider) {
    return Column(
      children: [
        if (order.orderStatus == OrderStatus.pending) ...[
          CustomButton(
            label: 'Xác nhận đơn hàng',
            isLoading: orderProvider.isLoading,
            onPressed: () async {
              final success = await orderProvider.updateOrderStatus(
                  order.id, OrderStatus.confirmed);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xác nhận đơn hàng')),
                );
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 8),
          CustomButton(
            label: 'Từ chối đơn hàng',
            isOutlined: true,
            color: AppColors.error,
            isLoading: orderProvider.isLoading,
            onPressed: () async {
              final success = await orderProvider.updateOrderStatus(
                  order.id, OrderStatus.rejected);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã từ chối đơn hàng')),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
        if (order.orderStatus == OrderStatus.confirmed)
          CustomButton(
            label: 'Bắt đầu chuẩn bị',
            isLoading: orderProvider.isLoading,
            onPressed: () async {
              final success = await orderProvider.updateOrderStatus(
                  order.id, OrderStatus.preparing);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang chuẩn bị')),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        if (order.orderStatus == OrderStatus.preparing)
          CustomButton(
            label: 'Chờ shipper đến lấy',
            isLoading: orderProvider.isLoading,
            onPressed: () async {
              final success = await orderProvider.updateOrderStatus(
                  order.id, OrderStatus.waitingForShipper);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang chờ shipper')),
                );
                Navigator.of(context).pop();
              }
            },
          ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InfoRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight:
                        isBold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}
