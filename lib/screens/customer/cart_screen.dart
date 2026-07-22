import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/widgets/cart_item_card.dart';

/// CartScreen — Giỏ hàng
///
/// Pattern an toàn nhất cho IndexedStack:
///   Scaffold
///     appBar
///     body: ListView.builder          ← chỉ danh sách món, không có TextField
///     bottomNavigationBar: Container  ← Flutter LUÔN cấp width = screenWidth
///                                        nên TextField trong Row+Expanded luôn an toàn
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _voucherCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadShippingFee();
    });
  }

  @override
  void dispose() {
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
  }

  void _confirmClear(CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa giỏ hàng?'),
        content: const Text('Xóa toàn bộ sản phẩm?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            child: const Text('Xóa tất cả',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Giỏ hàng của bạn đang trống',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.itemCount})'),
        actions: [
          TextButton(
            onPressed: () => _confirmClear(cart),
            child: const Text('Xóa tất cả',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),

      // ── Body: CHỈ danh sách món, padding bottom để footer không che ──
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        itemCount: items.length + 1,
        itemBuilder: (ctx, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.storefront,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cart.restaurantName ?? 'Nhà hàng',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final item = items[index - 1];
          return CartItemCard(
            cartItem: item,
            onQuantityChanged: (qty) =>
                cart.updateQuantity(item.product.id, qty),
            onRemove: () => cart.removeItem(item.product.id),
          );
        },
      ),

      // ── bottomNavigationBar: Flutter cấp width = screenWidth ──
      // TextField trong Row+Expanded sẽ LUÔN có chiều rộng xác định ở đây
      bottomNavigationBar: _CartFooter(
        cart: cart,
        voucherCtrl: _voucherCtrl,
        onApply: _applyVoucher,
        onRemoveVoucher: () {
          cart.removeVoucher();
          _voucherCtrl.clear();
        },
        onCheckout: () =>
            Navigator.of(context).pushNamed(AppRoutes.checkout),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer widget — được Scaffold cấp width = screenWidth
// ─────────────────────────────────────────────────────────────────────────────
class _CartFooter extends StatelessWidget {
  final CartProvider cart;
  final TextEditingController voucherCtrl;
  final VoidCallback onApply;
  final VoidCallback onRemoveVoucher;
  final VoidCallback onCheckout;

  const _CartFooter({
    required this.cart,
    required this.voucherCtrl,
    required this.onApply,
    required this.onRemoveVoucher,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    // MediaQuery để lấy bottom safe area (notch/gesture bar)
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // shadow line trên cùng footer
          Container(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 14 + bottomPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Voucher row ──
                // Row có chiều rộng xác định (= screenWidth - padding)
                // → TextField trong Expanded luôn an toàn
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: voucherCtrl,
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giảm giá...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(
                              Icons.confirmation_number_outlined,
                              size: 18,
                              color: AppColors.primary),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // InkWell + Container thay vì ElevatedButton
                    // tránh conflict minimumSize constraints
                    InkWell(
                      onTap: onApply,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Áp dụng',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ],
                ),


                // ── Mã đang dùng ──
                if (cart.voucherCode != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mã: ${cart.voucherCode}  −${AppUtils.formatCurrency(cart.discountAmount)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemoveVoucher,
                        child: const Icon(Icons.cancel,
                            size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                ],

                const Divider(height: 14),

                // ── Tổng tiền ──
                _row('Tạm tính:',
                    AppUtils.formatCurrency(cart.subtotal)),
                const SizedBox(height: 2),
                _row('Phí giao hàng:',
                    AppUtils.formatCurrency(cart.shippingFee)),
                if (cart.discountAmount > 0) ...[
                  const SizedBox(height: 2),
                  _row(
                      'Giảm giá:',
                      '−${AppUtils.formatCurrency(cart.discountAmount)}',
                      valueColor: Colors.green),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(AppUtils.formatCurrency(cart.finalTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Nút thanh toán ──
                InkWell(
                  onTap: onCheckout,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payment,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Thanh toán  •  ${AppUtils.formatCurrency(cart.finalTotal)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
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
