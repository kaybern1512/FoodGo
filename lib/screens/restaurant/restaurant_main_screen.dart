import 'package:flutter/material.dart';
import 'package:foodgo/screens/restaurant/restaurant_dashboard_screen.dart';
import 'package:foodgo/screens/restaurant/restaurant_products_screen.dart';
import 'package:foodgo/screens/restaurant/restaurant_orders_screen.dart';
import 'package:foodgo/screens/restaurant/restaurant_revenue_screen.dart';
import 'package:foodgo/screens/restaurant/restaurant_profile_screen.dart';

class RestaurantMainScreen extends StatefulWidget {
  const RestaurantMainScreen({super.key});

  @override
  State<RestaurantMainScreen> createState() => _RestaurantMainScreenState();
}

class _RestaurantMainScreenState extends State<RestaurantMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RestaurantDashboardScreen(),
    RestaurantProductsScreen(),
    RestaurantOrdersScreen(),
    RestaurantRevenueScreen(),
    RestaurantProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood_outlined),
            activeIcon: Icon(Icons.fastfood),
            label: 'Món ăn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Doanh thu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
