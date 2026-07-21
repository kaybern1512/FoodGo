import 'package:flutter/material.dart';
import 'package:foodgo/screens/shipper/available_orders_screen.dart';
import 'package:foodgo/screens/shipper/current_delivery_screen.dart';
import 'package:foodgo/screens/shipper/shipper_history_screen.dart';
import 'package:foodgo/screens/common/profile_screen.dart';

class ShipperMainScreen extends StatefulWidget {
  const ShipperMainScreen({super.key});

  @override
  State<ShipperMainScreen> createState() => _ShipperMainScreenState();
}

class _ShipperMainScreenState extends State<ShipperMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AvailableOrdersScreen(),
    CurrentDeliveryScreen(),
    ShipperHistoryScreen(),
    ProfileScreen(),
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
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Đơn có thể nhận',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bike_outlined),
            activeIcon: Icon(Icons.directions_bike),
            label: 'Đang giao',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
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
