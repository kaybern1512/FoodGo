import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/widgets/confirm_dialog.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAllProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    final filteredProducts = productProvider.products.where((p) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tất cả sản phẩm (${productProvider.products.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ProductProvider>().loadAllProducts(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: productProvider.isLoading
                ? const LoadingWidget()
                : filteredProducts.isEmpty
                    ? const EmptyStateWidget(
                        message: 'Không tìm thấy sản phẩm nào',
                        icon: Icons.fastfood_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<ProductProvider>().loadAllProducts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.defaultPadding),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: product.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          product.imageUrl,
                                          width: 50,
                                          height: 50,
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
                                  '${AppUtils.formatCurrency(product.price)} • ${product.category}',
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
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.error),
                                      onPressed: () => ConfirmDialog.show(
                                        context,
                                        title: 'Xóa sản phẩm',
                                        message:
                                            'Bạn có chắc muốn xóa "${product.name}"?',
                                        confirmLabel: 'Xóa',
                                        confirmColor: AppColors.error,
                                        onConfirm: () => productProvider
                                            .deleteProduct(product.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}
