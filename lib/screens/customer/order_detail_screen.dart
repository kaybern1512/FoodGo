import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/confirm_dialog.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

/// Màn hình chi tiết đơn hàng phía Khách hàng.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as FoodOrder?;
    if (order == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy đơn hàng')),
      );
    }

    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin mã đơn & trạng thái
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã đơn: #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppUtils.formatDateTime(order.createdAt),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    OrderStatusChip(status: order.orderStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách sản phẩm
            const Text('Sản phẩm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: order.items
                      .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x ${item.productName}',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(AppUtils.formatCurrency(item.totalPrice)),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin giao hàng
            const Text('Thông tin giao hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

            // Tóm tắt thanh toán
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'Phương thức',
                      value: order.paymentMethod.toVietnamese(),
                    ),
                    _InfoRow(
                      label: 'Trạng thái TT',
                      value: order.paymentStatus.toVietnamese(),
                    ),
                    const Divider(),
                    _InfoRow(
                      label: 'Tạm tính',
                      value: AppUtils.formatCurrency(order.subtotal),
                    ),
                    _InfoRow(
                      label: 'Phí giao hàng',
                      value: AppUtils.formatCurrency(order.shippingFee),
                    ),
                    _InfoRow(
                      label: 'Tổng cộng',
                      value: AppUtils.formatCurrency(order.totalAmount),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút Hủy đơn (Chỉ cho phép khi trạng thái Pending)
            if (order.orderStatus == OrderStatus.pending)
              CustomButton(
                label: 'Hủy đơn hàng',
                color: AppColors.error,
                isOutlined: true,
                isLoading: orderProvider.isLoading,
                onPressed: () => ConfirmDialog.show(
                  context,
                  title: 'Hủy đơn hàng',
                  message: 'Bạn có chắc muốn hủy đơn hàng này?',
                  confirmLabel: 'Hủy đơn',
                  confirmColor: AppColors.error,
                  onConfirm: () async {
                    final success = await orderProvider.updateOrderStatus(
                      order.id,
                      OrderStatus.cancelled,
                    );
                    if (context.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã hủy đơn hàng'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    }
                  },
                ),
              ),

            // Nút Đánh giá (Khi đơn hàng đã hoàn thành)
            if (order.orderStatus == OrderStatus.completed) ...[
              CustomButton(
                label: 'Đánh giá đơn hàng',
                icon: Icons.star_outline,
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRoutes.review,
                  arguments: order,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Nút Đặt lại đơn hàng (Re-order khi đã Hoàn thành hoặc Hủy)
            if (order.orderStatus == OrderStatus.completed ||
                order.orderStatus == OrderStatus.cancelled)
              CustomButton(
                label: 'Đặt lại đơn hàng này',
                icon: Icons.replay,
                isOutlined: true,
                onPressed: () {
                  final cartProvider = context.read<CartProvider>();
                  cartProvider.reorderItems(
                    order.items,
                    order.restaurantId,
                    'Nhà hàng',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm các món cũ vào giỏ hàng!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.of(context).pushNamed(AppRoutes.cart);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Helper hiển thị dòng thông tin (Key - Value)
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
            width: 120,
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