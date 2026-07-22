import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'package:foodgo/services/voucher_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();
  PaymentMethod _payment = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _addressCtrl.text = user.address;
      _phoneCtrl.text = user.phone;
    }
    final cart = context.read<CartProvider>();
    cart.loadShippingFee();
    if (cart.voucherCode != null) {
      _voucherCtrl.text = cart.voucherCode!;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final cart = context.read<CartProvider>();
    final ok = await cart.applyVoucher(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? '🎉 Áp dụng mã "$code" thành công!'
          : (cart.voucherError ?? '❌ Mã không hợp lệ!')),
      backgroundColor: ok ? AppColors.success : AppColors.error,
      duration: const Duration(seconds: 2),
    ));
    setState(() {}); // refresh UI
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = authProvider.currentUser!;

    if (cartProvider.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng trống!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final orderItems = cartProvider.items
        .map((ci) => OrderItem(
              productId: ci.product.id,
              productName: ci.product.name,
              imageUrl: ci.product.imageUrl,
              price: ci.product.price,
              quantity: ci.quantity,
              totalPrice: ci.totalPrice,
            ))
        .toList();

    final usedVoucherCode = cartProvider.voucherCode;
    final paymentStatus = _payment == PaymentMethod.mockWallet
        ? PaymentStatus.paid
        : PaymentStatus.unpaid;

    final order = FoodOrder(
      id: '',
      customerId: user.id,
      restaurantId: cartProvider.restaurantId!,
      shipperId: null,
      customerName: user.fullName,
      customerPhone: _phoneCtrl.text.trim(),
      deliveryAddress: _addressCtrl.text.trim(),
      items: orderItems,
      subtotal: cartProvider.subtotal,
      shippingFee: cartProvider.shippingFee,
      totalAmount: cartProvider.finalTotal,
      paymentMethod: _payment,
      paymentStatus: paymentStatus,
      orderStatus: OrderStatus.pending,
      note: _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final orderId = await orderProvider.createOrder(order);
    if (!mounted) return;

    if (orderId != null) {
      if (usedVoucherCode != null && usedVoucherCode.isNotEmpty) {
        VoucherService().incrementVoucherUsedCount(usedVoucherCode);
      }
      cartProvider.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đặt hàng thành công! Đang chờ bên shop xác nhận.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      final createdOrder = order.copyWith(id: orderId);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.customerMain,
        (route) => false,
        arguments: 1,
      );
      Navigator.of(context).pushNamed(
        AppRoutes.orderDetail,
        arguments: createdOrder,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Đặt hàng thất bại, thử lại!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final effectiveDiscount = cart.discountAmount > (cart.subtotal + cart.shippingFee)
        ? cart.subtotal + cart.shippingFee
        : cart.discountAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận & Thanh toán')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── THÔNG TIN GIAO HÀNG ──
            _sectionTitle('📍 Thông tin giao hàng'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Địa chỉ nhận hàng',
              icon: Icons.location_on_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                if (v.trim().length < 9) return 'Số điện thoại không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _noteCtrl,
              label: 'Ghi chú (tùy chọn)',
              icon: Icons.note_outlined,
              hint: 'Ít cay, giao giờ hành chính...',
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── MÃ GIẢM GIÁ ──
            _sectionTitle('🎫 Mã giảm giá'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _voucherCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Nhập mã giảm giá...',
                      prefixIcon: const Icon(Icons.card_giftcard, color: AppColors.primary, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _applyVoucher,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Áp dụng',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
            if (cart.voucherCode != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mã: ${cart.voucherCode}  −${AppUtils.formatCurrency(effectiveDiscount)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        cart.removeVoucher();
                        _voucherCtrl.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.close, size: 18, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── PHƯƠNG THỨC THANH TOÁN ──
            _sectionTitle('💳 Phương thức thanh toán'),
            const SizedBox(height: 10),
            _paymentTile(
              icon: Icons.payments_outlined,
              label: 'Tiền mặt khi nhận hàng (COD)',
              subtitle: 'Thanh toán trực tiếp cho tài xế',
              value: PaymentMethod.cash,
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── CHI TIẾT ĐƠN HÀNG ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('📋 Chi tiết đơn hàng'),
                Text(cart.restaurantName ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('${item.quantity}x ',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Expanded(
                          child: Text(item.product.name,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(AppUtils.formatCurrency(item.totalPrice),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  )),
                  const Divider(height: 16),
                  _summaryRow('Tạm tính', AppUtils.formatCurrency(cart.subtotal)),
                  const SizedBox(height: 4),
                  _summaryRow('Phí giao hàng', AppUtils.formatCurrency(cart.shippingFee)),
                  if (effectiveDiscount > 0) ...[
                    const SizedBox(height: 4),
                    _summaryRow('Giảm giá', '−${AppUtils.formatCurrency(effectiveDiscount)}',
                        valueColor: Colors.green),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(AppUtils.formatCurrency(cart.finalTotal),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // padding cho bottom button
          ],
        ),
      ),

      // ── NÚT ĐẶT HÀNG ──
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
              child: InkWell(
                onTap: orderProvider.isLoading ? null : _placeOrder,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: orderProvider.isLoading
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: orderProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          'XÁC NHẬN ĐẶT HÀNG  •  ${AppUtils.formatCurrency(cart.finalTotal)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
    );
  }

  Widget _paymentTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required PaymentMethod value,
  }) {
    final isSelected = _payment == value;
    return GestureDetector(
      onTap: () => setState(() => _payment = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}