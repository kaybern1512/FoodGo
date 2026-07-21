import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class RestaurantProductsScreen extends StatefulWidget {
  const RestaurantProductsScreen({super.key});

  @override
  State<RestaurantProductsScreen> createState() =>
      _RestaurantProductsScreenState();
}

class _RestaurantProductsScreenState
    extends State<RestaurantProductsScreen> {
  String? _lastLoadedRestaurantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    final restaurantProvider = context.read<RestaurantProvider>();
    if (restaurantProvider.myRestaurant == null) {
      await restaurantProvider.loadMyRestaurant(user.id);
    }
    final restaurant = restaurantProvider.myRestaurant;
    if (restaurant != null && mounted) {
      _lastLoadedRestaurantId = restaurant.id;
      await context
          .read<ProductProvider>()
          .loadProductsByRestaurant(restaurant.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final restaurantProvider = context.watch<RestaurantProvider>();
    final restaurant = restaurantProvider.myRestaurant;

    // Tự động tải lại danh sách món ăn nếu vừa khởi tạo nhà hàng
    if (restaurant != null &&
        restaurant.id != _lastLoadedRestaurantId &&
        !productProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProducts();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý món ăn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      floatingActionButton: restaurant != null
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).pushNamed(AppRoutes.addProduct);
                if (mounted && restaurant.id.isNotEmpty) {
                  context
                      .read<ProductProvider>()
                      .loadProductsByRestaurant(restaurant.id);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: productProvider.isLoading
          ? const LoadingWidget(message: 'Đang tải danh sách món ăn...')
          : restaurant == null
              ? const EmptyStateWidget(
                  message: 'Bạn chưa có dữ liệu nhà hàng',
                  icon: Icons.store_outlined,
                )
              : productProvider.products.isEmpty
                  ? EmptyStateWidget(
                      message: 'Chưa có món ăn nào\nNhấn + để thêm món mới',
                      icon: Icons.fastfood_outlined,
                      actionLabel: 'Làm mới',
                      onAction: _loadProducts,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: productProvider.products.length,
                        itemBuilder: (context, index) {
                          final product = productProvider.products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: product.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        product.imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) =>
                                            _placeholder(),
                                      ),
                                    )
                                  : _placeholder(),
                              title: Text(product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${product.price.toStringAsFixed(0)}đ • ${product.category}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: product.isAvailable,
                                    onChanged: (value) => productProvider
                                        .toggleAvailability(
                                            product.id, value),
                                    activeColor: AppColors.primary,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      await Navigator.of(context).pushNamed(
                                        AppRoutes.editProduct,
                                        arguments: product,
                                      );
                                      if (mounted) _loadProducts();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppColors.error),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Xóa món ăn'),
                                          content: Text(
                                              'Xóa "${product.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                  context, false),
                                              child: const Text('Hủy'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(
                                                  context, true),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.error),
                                              child: const Text('Xóa'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true &&
                                          context.mounted) {
                                        await productProvider
                                            .deleteProduct(product.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}
