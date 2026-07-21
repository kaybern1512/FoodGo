import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/models/restaurant.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/product_card.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  Restaurant? _restaurant;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Restaurant && _restaurant == null) {
      _restaurant = args;
      context.read<ProductProvider>().loadProductsByRestaurant(_restaurant!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    if (_restaurant == null) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_restaurant!.name),
              background: _restaurant!.imageUrl.isNotEmpty
                  ? Image.network(_restaurant!.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.primary.withOpacity(0.3),
                      child: const Icon(Icons.restaurant,
                          size: 80, color: Colors.white),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        _restaurant!.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _restaurant!.isOpen
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _restaurant!.isOpen ? 'Đang mở' : 'Đã đóng',
                          style: TextStyle(
                            color: _restaurant!.isOpen
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _restaurant!.address,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (_restaurant!.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _restaurant!.description,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                  const Divider(height: 32),
                  const Text(
                    'Thực đơn',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (productProvider.isLoading)
            const SliverFillRemaining(child: LoadingWidget())
          else if (productProvider.products.isEmpty)
            const SliverFillRemaining(
              child: EmptyStateWidget(
                message: 'Nhà hàng chưa có món ăn nào',
                icon: Icons.fastfood_outlined,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = productProvider.products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ProductCard(
                        product: product,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.productDetail,
                          arguments: product,
                        ),
                        onAddToCart: product.isAvailable
                            ? () {
                                final added = cartProvider.addItem(
                                    product, _restaurant!.name);
                                if (!added) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Giỏ hàng chỉ chứa sản phẩm từ một nhà hàng. Vui lòng xóa giỏ hàng hiện tại.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Đã thêm vào giỏ hàng'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    );
                  },
                  childCount: productProvider.products.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: cartProvider.itemCount > 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.cart),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Giỏ hàng (${cartProvider.itemCount})',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
