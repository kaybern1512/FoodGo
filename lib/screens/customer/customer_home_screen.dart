import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/models/restaurant.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/product_card.dart';
import 'package:foodgo/widgets/restaurant_card.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadOpenRestaurants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants) {
    if (_searchQuery.isEmpty) return restaurants;
    final query = _searchQuery.toLowerCase();
    return restaurants
        .where((r) =>
            r.name.toLowerCase().contains(query) ||
            r.address.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final restaurantProvider = context.watch<RestaurantProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    final filteredRestaurants =
        _filterRestaurants(restaurantProvider.restaurants);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FoodGo',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Xin chào, ${user?.fullName ?? ''}',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RestaurantProvider>().loadOpenRestaurants();
              if (_searchQuery.isNotEmpty) {
                context.read<ProductProvider>().searchProducts(_searchQuery);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Cửa hàng'),
            Tab(text: 'Tìm món ăn'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tabController.index == 0
                    ? 'Tìm kiếm nhà hàng...'
                    : 'Tìm món ăn theo tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          productProvider.clearSearchResults();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (_tabController.index == 1) {
                  productProvider.searchProducts(value);
                }
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Cửa hàng
                restaurantProvider.isLoading
                    ? const LoadingWidget(message: 'Đang tải nhà hàng...')
                    : filteredRestaurants.isEmpty
                        ? EmptyStateWidget(
                            message: _searchQuery.isEmpty
                                ? 'Chưa có nhà hàng nào đang mở'
                                : 'Không tìm thấy nhà hàng phù hợp',
                            icon: Icons.restaurant_outlined,
                            actionLabel: 'Làm mới',
                            onAction: () => context
                                .read<RestaurantProvider>()
                                .loadOpenRestaurants(),
                          )
                        : RefreshIndicator(
                            onRefresh: () => context
                                .read<RestaurantProvider>()
                                .loadOpenRestaurants(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.defaultPadding),
                              itemCount: filteredRestaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = filteredRestaurants[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: RestaurantCard(
                                    restaurant: restaurant,
                                    onTap: () =>
                                        Navigator.of(context).pushNamed(
                                      AppRoutes.restaurantDetail,
                                      arguments: restaurant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                // Tab Tìm món ăn theo tên
                productProvider.isLoading
                    ? const LoadingWidget(message: 'Đang tìm món ăn...')
                    : _searchQuery.isEmpty
                        ? const EmptyStateWidget(
                            message: 'Nhập tên món ăn ở ô tìm kiếm phía trên',
                            icon: Icons.search,
                          )
                        : productProvider.searchResults.isEmpty
                            ? EmptyStateWidget(
                                message:
                                    'Không tìm thấy món "$_searchQuery"',
                                icon: Icons.fastfood_outlined,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.defaultPadding),
                                itemCount:
                                    productProvider.searchResults.length,
                                itemBuilder: (context, index) {
                                  final product =
                                      productProvider.searchResults[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ProductCard(
                                      product: product,
                                      onTap: () =>
                                          Navigator.of(context).pushNamed(
                                        AppRoutes.productDetail,
                                        arguments: product,
                                      ),
                                      onAddToCart: product.isAvailable
                                          ? () {
                                              final restaurantName =
                                                  restaurantProvider
                                                          .restaurants
                                                          .where((r) =>
                                                              r.id ==
                                                              product
                                                                  .restaurantId)
                                                          .map((r) => r.name)
                                                          .firstOrNull ??
                                                      'Nhà hàng';
                                              final added = cartProvider
                                                  .addItem(product,
                                                      restaurantName);
                                              if (!added) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Giỏ hàng chỉ chứa sản phẩm từ một nhà hàng'),
                                                    backgroundColor:
                                                        AppColors.error,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Đã thêm vào giỏ hàng'),
                                                    backgroundColor:
                                                        AppColors.success,
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                    ),
                                  );
                                },
                              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
