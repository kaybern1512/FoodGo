import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/widgets/custom_button.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)?.settings.arguments as Product?;
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy sản phẩm')),
      );
    }

    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(product.imageUrl, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.fastfood,
                                size: 80, color: Colors.grey),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!product.isAvailable)
                              const Chip(
                                label: Text('Hết hàng'),
                                backgroundColor: Colors.red,
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppUtils.formatCurrency(product.price),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.category.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(product.category),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            labelStyle:
                                const TextStyle(color: AppColors.primary),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (product.description.isNotEmpty) ...[
                          const Text(
                            'Mô tả',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: product.isAvailable
                ? CustomButton(
                    label: 'Thêm vào giỏ hàng',
                    icon: Icons.shopping_cart_outlined,
                    onPressed: () {
                      // Need restaurant name - get from restaurant provider
                      final restaurantProvider =
                          context.read<RestaurantProvider>();
                      final restaurantName =
                          restaurantProvider.restaurants
                              .where((r) => r.id == product.restaurantId)
                              .map((r) => r.name)
                              .firstOrNull ??
                              restaurantProvider.myRestaurant?.name ??
                              'Nhà hàng';
                      final added =
                          cartProvider.addItem(product, restaurantName);
                      if (!added) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Giỏ hàng chỉ chứa sản phẩm từ một nhà hàng'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã thêm vào giỏ hàng'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : const CustomButton(
                    label: 'Hết hàng',
                    onPressed: null,
                    color: Colors.grey,
                  ),
          ),
        ],
      ),
    );
  }
}
