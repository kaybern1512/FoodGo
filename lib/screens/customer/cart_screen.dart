import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/widgets/cart_item_card.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          if (cartProvider.itemCount > 0)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa giỏ hàng'),
                    content: const Text(
                        'Bạn có chắc muốn xóa toàn bộ giỏ hàng?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          cartProvider.clearCart();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        child: const Text('Xóa tất cả'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Xóa tất cả',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: cartProvider.isEmpty
          ? const EmptyStateWidget(
              message: 'Giỏ hàng của bạn đang trống',
              icon: Icons.shopping_cart_outlined,
            )
          : Column(
              children: [
                // Tên nhà hàng
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  color: AppColors.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        cartProvider.restaurantName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Danh sách sản phẩm
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CartItemCard(
                          cartItem: item,
                          onQuantityChanged: (qty) => cartProvider
                              .updateQuantity(item.product.id, qty),
                          onRemove: () =>
                              cartProvider.removeItem(item.product.id),
                        ),
                      );
                    },
                  ),
                ),
                // Tổng cộng và thanh toán
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tạm tính:',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(AppUtils.formatCurrency(cartProvider.subtotal)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Phí giao hàng:',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(AppUtils.formatCurrency(
                              AppConstants.shippingFee)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng cộng:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            AppUtils.formatCurrency(
                                cartProvider.subtotal + AppConstants.shippingFee),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Đặt hàng',
                        icon: Icons.payment,
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.checkout),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
