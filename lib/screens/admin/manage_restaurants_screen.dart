import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/widgets/confirm_dialog.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ManageRestaurantsScreen extends StatefulWidget {
  const ManageRestaurantsScreen({super.key});

  @override
  State<ManageRestaurantsScreen> createState() =>
      _ManageRestaurantsScreenState();
}

class _ManageRestaurantsScreenState extends State<ManageRestaurantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().loadAllRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantProvider = context.watch<RestaurantProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cửa hàng (${restaurantProvider.restaurants.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                restaurantProvider.loadAllRestaurants(),
          ),
        ],
      ),
      body: restaurantProvider.isLoading
          ? const LoadingWidget()
          : restaurantProvider.restaurants.isEmpty
              ? const EmptyStateWidget(
                  message: 'Chưa có nhà hàng nào',
                  icon: Icons.store_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: restaurantProvider.restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurantProvider.restaurants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: restaurant.isApproved
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          child: Icon(
                            restaurant.isApproved
                                ? Icons.check
                                : Icons.pending,
                            color: restaurant.isApproved
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        title: Text(restaurant.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(restaurant.address,
                                style: const TextStyle(fontSize: 12)),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    restaurant.isApproved
                                        ? 'Đã duyệt'
                                        : 'Chờ duyệt',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: restaurant.isApproved
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  padding: EdgeInsets.zero,
                                ),
                                const SizedBox(width: 4),
                                Chip(
                                  label: Text(
                                    restaurant.isOpen
                                        ? 'Đang mở'
                                        : 'Đóng cửa',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: restaurant.isOpen
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade200,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'approve') {
                              ConfirmDialog.show(
                                context,
                                title: 'Phê duyệt nhà hàng',
                                message:
                                    'Phê duyệt "${restaurant.name}"?',
                                confirmLabel: 'Phê duyệt',
                                onConfirm: () =>
                                    restaurantProvider.setApprovalStatus(
                                        restaurant.id, true),
                              );
                            } else if (action == 'reject') {
                              ConfirmDialog.show(
                                context,
                                title: 'Từ chối nhà hàng',
                                message: 'Từ chối "${restaurant.name}"?',
                                confirmLabel: 'Từ chối',
                                confirmColor: AppColors.error,
                                onConfirm: () =>
                                    restaurantProvider.setApprovalStatus(
                                        restaurant.id, false),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            if (!restaurant.isApproved)
                              const PopupMenuItem(
                                value: 'approve',
                                child: Row(
                                  children: [
                                    Icon(Icons.check, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Phê duyệt'),
                                  ],
                                ),
                              ),
                            if (restaurant.isApproved)
                              const PopupMenuItem(
                                value: 'reject',
                                child: Row(
                                  children: [
                                    Icon(Icons.close, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Thu hồi duyệt'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
