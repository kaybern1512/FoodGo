import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/confirm_dialog.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadWaitingOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final user = context.watch<AuthProvider>().currentUser;

    // Chỉ hiển thị đơn ĐANG CHỜ shipper nhận
    final waitingOrders = orderProvider.orders
        .where((o) => o.orderStatus == OrderStatus.waitingForShipper)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn có thể nhận (${waitingOrders.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => orderProvider.loadWaitingOrders(),
          ),
        ],
      ),
      body: user != null && !user.isOnline
          ? EmptyStateWidget(
              message:
                  'Bạn đang TẮT nhận đơn (Offline).\nHãy bật nhận đơn trong Hồ sơ tài xế để nhận đơn mới!',
              icon: Icons.sensors_off,
              actionLabel: 'Bật nhận đơn ngay',
              onAction: () async {
                final userService = UserService();
                await userService.setOnlineStatus(user.id, true);
                if (context.mounted) {
                  context
                      .read<AuthProvider>()
                      .updateCurrentUser(user.copyWith(isOnline: true));
                  orderProvider.loadWaitingOrders();
                }
              },
            )
          : orderProvider.isLoading
              ? const LoadingWidget(message: 'Đang tìm đơn hàng...')
              : waitingOrders.isEmpty
                  ? EmptyStateWidget(
                      message: 'Không có đơn hàng nào đang chờ shipper',
                      icon: Icons.local_shipping_outlined,
                      actionLabel: 'Làm mới',
                      onAction: () => orderProvider.loadWaitingOrders(),
                    )
                  : RefreshIndicator(
                  onRefresh: () => orderProvider.loadWaitingOrders(),
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: waitingOrders.length,
                    itemBuilder: (context, index) {
                      final order = waitingOrders[index];
                      final isPayCash = order.paymentMethod == PaymentMethod.cash;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            // Header màu cam nhạt
                            Container(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mã đơn: #${order.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${order.items.length} món',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // Body
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Địa chỉ giao hàng
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 18, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Địa chỉ giao',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.textSecondary)),
                                            Text(
                                              order.deliveryAddress.isNotEmpty
                                                  ? order.deliveryAddress
                                                  : 'Chưa có địa chỉ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Thông tin khách hàng
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(order.customerName,
                                          style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.phone_outlined,
                                          size: 16,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(order.customerPhone,
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  // Tài chính: tóm tắt
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _MoneyInfo(
                                              label: 'Tiền hàng',
                                              value: AppUtils.formatCurrency(order.subtotal),
                                            ),
                                            const SizedBox(height: 2),
                                            _MoneyInfo(
                                              label: 'Phí ship (bạn nhận)',
                                              value: AppUtils.formatCurrency(order.shippingFee),
                                              valueColor: AppColors.success,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Tiền thu COD (nếu tiền mặt)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            isPayCash ? 'Thu tiền mặt' : 'Đã thanh toán',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary),
                                          ),
                                          Text(
                                            isPayCash
                                                ? AppUtils.formatCurrency(order.totalAmount)
                                                : '0đ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isPayCash
                                                  ? AppColors.primary
                                                  : AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Nút nhận đơn
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.local_shipping,
                                          size: 18),
                                      label: const Text('Nhận đơn giao ngay'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () => ConfirmDialog.show(
                                        context,
                                        title: 'Nhận đơn hàng',
                                        message:
                                            'Bạn có muốn nhận đơn này không?\n'
                                            'Địa chỉ: ${order.deliveryAddress}\n'
                                            'Phí ship: ${AppUtils.formatCurrency(order.shippingFee)}',
                                        confirmLabel: 'Nhận đơn',
                                        onConfirm: () async {
                                          final success =
                                              await orderProvider.acceptOrder(
                                            order.id,
                                            user!.id,
                                            shipperName: user.fullName,
                                            shipperPhone: user.phone,
                                          );
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(success
                                                    ? 'Đã nhận đơn! Hãy giao ngay.'
                                                    : (orderProvider.errorMessage ??
                                                        'Không thể nhận đơn')),
                                                backgroundColor: success
                                                    ? AppColors.success
                                                    : AppColors.error,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _MoneyInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MoneyInfo({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}
