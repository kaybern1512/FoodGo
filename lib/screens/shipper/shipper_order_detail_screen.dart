import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

class ShipperOrderDetailScreen extends StatelessWidget {
  const ShipperOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as FoodOrder?;
    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy đơn hàng')),
      );
    }

    final orderProvider = context.watch<OrderProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng giao')),
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
                      'Mã đơn: #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    OrderStatusChip(status: order.orderStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    _InfoRow(label: 'Người nhận', value: order.customerName),
                    _InfoRow(label: 'Điện thoại', value: order.customerPhone),
                    _InfoRow(label: 'Địa chỉ', value: order.deliveryAddress),
                    if (order.note.isNotEmpty)
                      _InfoRow(label: 'Ghi chú', value: order.note),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Phương thức',
                        value: order.paymentMethod.toVietnamese()),
                    _InfoRow(
                        label: 'Trạng thái',
                        value: order.paymentStatus.toVietnamese()),
                    _InfoRow(
                      label: 'Tiền thu người nhận',
                      value: order.paymentMethod == PaymentMethod.cash
                          ? AppUtils.formatCurrency(order.totalAmount)
                          : '0đ (Đã thanh toán trước)',
                      isBold: true,
                    ),
                    _InfoRow(
                      label: 'Tiền phí giao hàng',
                      value: AppUtils.formatCurrency(order.shippingFee),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (order.orderStatus == OrderStatus.waitingForShipper)
              CustomButton(
                label: 'Nhận đơn hàng này',
                icon: Icons.local_shipping,
                isLoading: orderProvider.isLoading,
                onPressed: () async {
                  if (user == null) return;
                  final success = await orderProvider.acceptOrder(
                    order.id,
                    user.id,
                  );
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nhận đơn thành công!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(orderProvider.errorMessage ??
                              'Không thể nhận đơn'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            if (order.orderStatus == OrderStatus.delivering)
              CustomButton(
                label: 'Xác nhận đã giao hàng thành công',
                icon: Icons.check_circle_outline,
                isLoading: orderProvider.isLoading,
                onPressed: () async {
                  final success = await orderProvider.updateOrderStatus(
                    order.id,
                    OrderStatus.completed,
                  );
                  if (context.mounted && success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hoàn thành giao hàng!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
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

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
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
}
