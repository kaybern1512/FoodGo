import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/models/order_item.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/custom_text_field.dart';
import 'package:foodgo/core/utils/restaurant_time_utils.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  PaymentMethod _selectedPayment = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _addressController.text = user.address;
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final restaurantProvider = context.read<RestaurantProvider>();
    final user = authProvider.currentUser!;

    final restaurant = restaurantProvider.restaurants
        .where((r) => r.id == cartProvider.restaurantId)
        .firstOrNull;

    if (restaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin nhà hàng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RestaurantTimeUtils.isRestaurantOpen(
      restaurant.openTime,
      restaurant.closeTime,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nhà hàng hiện chỉ phục vụ từ '
            '${restaurant.openTime} đến ${restaurant.closeTime}.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final orderItems = cartProvider.items
        .map((cartItem) => OrderItem(
              productId: cartItem.product.id,
              productName: cartItem.product.name,
              imageUrl: cartItem.product.imageUrl,
              price: cartItem.product.price,
              quantity: cartItem.quantity,
              totalPrice: cartItem.totalPrice,
            ))
        .toList();

    final subtotal = cartProvider.subtotal;
    final shippingFee = AppConstants.shippingFee;
    final totalAmount = subtotal + shippingFee;

    // Xác định trạng thái thanh toán dựa trên phương thức
    final paymentStatus = _selectedPayment == PaymentMethod.mockWallet
        ? PaymentStatus.paid
        : PaymentStatus.unpaid;

    final order = FoodOrder(
      id: '',
      customerId: user.id,
      restaurantId: cartProvider.restaurantId!,
      shipperId: null,
      customerName: user.fullName,
      customerPhone: _phoneController.text.trim(),
      deliveryAddress: _addressController.text.trim(),
      items: orderItems,
      subtotal: subtotal,
      shippingFee: shippingFee,
      totalAmount: totalAmount,
      paymentMethod: _selectedPayment,
      paymentStatus: paymentStatus,
      orderStatus: OrderStatus.pending,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final orderId = await orderProvider.createOrder(order);
    if (!mounted) return;

    if (orderId != null) {
      cartProvider.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt hàng thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.customerMain,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Đặt hàng thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final subtotal = cartProvider.subtotal;
    final shippingFee = AppConstants.shippingFee;
    final total = subtotal + shippingFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin giao hàng
                    const Text(
                      'Thông tin giao hàng',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _addressController,
                      label: 'Địa chỉ giao hàng',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) =>
                          AppUtils.validateRequired(v, 'địa chỉ giao hàng'),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: AppUtils.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _noteController,
                      label: 'Ghi chú (tùy chọn)',
                      hint: 'Ghi chú cho shipper hoặc nhà hàng',
                      prefixIcon: Icons.note_outlined,
                      maxLines: 2,
                    ),
                    const Divider(height: 32),
                    // Phương thức thanh toán
                    const Text(
                      'Phương thức thanh toán',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _PaymentOption(
                      value: PaymentMethod.cash,
                      groupValue: _selectedPayment,
                      label: 'Tiền mặt khi nhận hàng',
                      icon: Icons.money,
                      onChanged: (v) => setState(() => _selectedPayment = v!),
                    ),
                    _PaymentOption(
                      value: PaymentMethod.mockWallet,
                      groupValue: _selectedPayment,
                      label: 'Ví điện tử (mô phỏng)',
                      icon: Icons.account_balance_wallet_outlined,
                      onChanged: (v) => setState(() => _selectedPayment = v!),
                    ),
                    const Divider(height: 32),
                    // Tóm tắt đơn hàng
                    const Text(
                      'Tóm tắt đơn hàng',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...cartProvider.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x ${item.product.name}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            const Spacer(),
                            Text(AppUtils.formatCurrency(item.totalPrice)),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    _SummaryRow(
                        label: 'Tạm tính',
                        value: AppUtils.formatCurrency(subtotal)),
                    const SizedBox(height: 4),
                    _SummaryRow(
                        label: 'Phí giao hàng',
                        value: AppUtils.formatCurrency(shippingFee)),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Tổng cộng',
                      value: AppUtils.formatCurrency(total),
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: CustomButton(
                label: 'Đặt hàng • ${AppUtils.formatCurrency(total)}',
                onPressed: _placeOrder,
                isLoading: orderProvider.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod value;
  final PaymentMethod groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<PaymentMethod?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: value == groupValue
          ? AppColors.primary.withOpacity(0.05)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(
          color: value == groupValue ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: RadioListTile<PaymentMethod>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        title: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
