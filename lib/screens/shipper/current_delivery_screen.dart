import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

class CurrentDeliveryScreen extends StatefulWidget {
  const CurrentDeliveryScreen({super.key});

  @override
  State<CurrentDeliveryScreen> createState() => _CurrentDeliveryScreenState();
}

class _CurrentDeliveryScreenState extends State<CurrentDeliveryScreen> {
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

    final currentOrder = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.delivering)
        .firstOrNull;

    final isPayCash =
        currentOrder?.paymentMethod == PaymentMethod.cash;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn đang giao'),
        actions: [
          if (currentOrder != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final user = context.read<AuthProvider>().currentUser;
                if (user != null) {
                  context.read<OrderProvider>().loadShipperOrders(user.id);
                }
              },
            ),
        ],
      ),
      body: orderProvider.isLoading
          ? const LoadingWidget(message: 'Đang tải...')
          : currentOrder == null
              ? const EmptyStateWidget(
                  message: 'Bạn không có đơn hàng nào đang giao',
                  icon: Icons.directions_bike_outlined,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Trạng thái đơn ──
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                          side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${currentOrder.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppUtils.formatDateTime(currentOrder.createdAt),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              OrderStatusChip(status: currentOrder.orderStatus),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Địa chỉ giao hàng (nổi bật) ──
                      const Text('Thông tin giao hàng',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Địa chỉ
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.red, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Địa chỉ giao hàng',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary)),
                                        const SizedBox(height: 2),
                                        Text(
                                          currentOrder.deliveryAddress.isNotEmpty
                                              ? currentOrder.deliveryAddress
                                              : 'Chưa có địa chỉ',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Nút copy địa chỉ
                                  IconButton(
                                    icon: const Icon(Icons.copy_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    tooltip: 'Sao chép địa chỉ',
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text: currentOrder.deliveryAddress));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Đã sao chép địa chỉ!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              // Người nhận
                              _InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Người nhận',
                                  value: currentOrder.customerName),
                              const SizedBox(height: 8),
                              // SĐT
                              _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Điện thoại',
                                  value: currentOrder.customerPhone),
                              if (currentOrder.note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _InfoRow(
                                    icon: Icons.note_outlined,
                                    label: 'Ghi chú',
                                    value: currentOrder.note),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Thanh toán ──
                      const Text('Thanh toán',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Tiền hàng
                              _PayRow(
                                  label: 'Tiền hàng (tạm tính)',
                                  value: AppUtils.formatCurrency(
                                      currentOrder.subtotal)),
                              const SizedBox(height: 6),
                              // Phí ship (thu nhập của shipper)
                              _PayRow(
                                label: '🏍 Phí giao hàng (bạn nhận)',
                                value: AppUtils.formatCurrency(
                                    currentOrder.shippingFee),
                                valueColor: AppColors.success,
                                isBold: true,
                              ),
                              const Divider(height: 16),
                              // Tổng thu (nếu COD)
                              _PayRow(
                                label: isPayCash
                                    ? '💵 Thu tiền mặt từ khách'
                                    : '✅ Đã thanh toán trước',
                                value: isPayCash
                                    ? AppUtils.formatCurrency(
                                        currentOrder.totalAmount)
                                    : '0đ',
                                valueColor:
                                    isPayCash ? AppColors.primary : AppColors.success,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Nút xác nhận giao xong ──
                      CustomButton(
                        label: '✅ Xác nhận đã giao hàng thành công',
                        icon: Icons.check_circle_outline,
                        isLoading: orderProvider.isLoading,
                        onPressed: () async {
                          final success = await orderProvider.updateOrderStatus(
                            currentOrder.id,
                            OrderStatus.completed,
                          );
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Giao hàng thành công!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _PayRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: isBold ? 14 : 13,
                  fontWeight:
                      isBold ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isBold ? AppColors.textPrimary : AppColors.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
