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

/// Màn hình chính Khách hàng - Tìm kiếm nhà hàng & sản phẩm.
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
  final List<String> _searchHistory = ['Trà sữa', 'Cơm tấm', 'Bún bò', 'Burger'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Tải danh sách nhà hàng & tất cả món ăn sau khi build xong frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadOpenRestaurants();
      context.read<ProductProvider>().searchProducts('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Lọc danh sách nhà hàng theo từ khóa tìm kiếm
  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants) {
    if (_searchQuery.isEmpty) return restaurants;
    final query = _searchQuery.toLowerCase();
    return restaurants
        .where((r) =>
    r.name.toLowerCase().contains(query) ||
        r.address.toLowerCase().contains(query))
        .toList();
  }

  /// Lưu lịch sử tìm kiếm khi submit
  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 5) _searchHistory.removeLast();
      });
    }
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
            const Text('FoodGo', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Xin chào, ${user?.fullName ?? ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
          // --- THANH TÌM KIẾM ---
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
                      context.read<ProductProvider>().searchProducts('');
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
              onSubmitted: _onSearchSubmitted,
            ),
          ),

          // --- LỊCH SỬ TÌM KIẾM NHANH (Dùng Wrap chống RenderSingleChildViewport) ---
          if (_searchQuery.isEmpty && _searchHistory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tìm kiếm gần đây:',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      InkWell(
                        onTap: () => setState(() => _searchHistory.clear()),
                        child: const Text('Xóa',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _searchHistory.map((query) {
                      return ActionChip(
                        label: Text(query,
                            style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _searchController.text = query;
                          setState(() => _searchQuery = query);
                          if (_tabController.index == 1) {
                            productProvider.searchProducts(query);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // --- NỘI DUNG THEO TAB ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Danh sách Nhà hàng
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

                // TAB 2: Danh sách & Tìm kiếm Món ăn
                productProvider.isLoading
                    ? const LoadingWidget(message: 'Đang tải món ăn...')
                    : productProvider.searchResults.isEmpty
                    ? EmptyStateWidget(
                  message: _searchQuery.isEmpty
                      ? 'Chưa có món ăn nào khả dụng'
                      : 'Không tìm thấy món "$_searchQuery"',
                  icon: Icons.fastfood_outlined,
                  actionLabel: 'Làm mới',
                  onAction: () => context
                      .read<ProductProvider>()
                      .searchProducts(_searchQuery),
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
                              restaurantProvider.restaurants
                                  .where((r) =>
                              r.id ==
                                  product
                                      .restaurantId)
                                  .map((r) => r.name)
                                  .firstOrNull ??
                                  'Nhà hàng';
                          final added = cartProvider.addItem(
                              product, restaurantName);
                          if (!added) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Đổi nhà hàng?'),
                                content: Text(
                                    'Giỏ hàng hiện tại đang có món của nhà hàng khác. Bạn có muốn xóa giỏ cũ để thêm món từ "$restaurantName" không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Hủy'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      cartProvider.addItem(
                                          product, restaurantName,
                                          forceReplace: true);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Đã tạo giỏ hàng mới và thêm sản phẩm!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    },
                                    child: const Text(
                                        'Xóa giỏ cũ & Thêm món mới',
                                        style:
                                            TextStyle(color: Colors.white)),
                                  ),
                                ],
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