import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/theme/app_theme.dart';
import 'package:foodgo/firebase_options.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/cart_provider.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/providers/review_provider.dart';

// Screens - Auth
import 'package:foodgo/screens/auth/splash_screen.dart';
import 'package:foodgo/screens/auth/login_screen.dart';
import 'package:foodgo/screens/auth/register_screen.dart';

// Screens - Customer
import 'package:foodgo/screens/customer/customer_main_screen.dart';
import 'package:foodgo/screens/customer/restaurant_detail_screen.dart';
import 'package:foodgo/screens/customer/product_detail_screen.dart';
import 'package:foodgo/screens/customer/cart_screen.dart';
import 'package:foodgo/screens/customer/checkout_screen.dart';
import 'package:foodgo/screens/customer/customer_orders_screen.dart';
import 'package:foodgo/screens/customer/order_detail_screen.dart';
import 'package:foodgo/screens/customer/review_screen.dart';

// Screens - Restaurant
import 'package:foodgo/screens/restaurant/restaurant_main_screen.dart';
import 'package:foodgo/screens/restaurant/add_product_screen.dart';
import 'package:foodgo/screens/restaurant/edit_product_screen.dart';
import 'package:foodgo/screens/restaurant/restaurant_order_detail_screen.dart';

// Screens - Shipper
import 'package:foodgo/screens/shipper/shipper_main_screen.dart';
import 'package:foodgo/screens/shipper/shipper_order_detail_screen.dart';

// Screens - Admin
import 'package:foodgo/screens/admin/admin_main_screen.dart';
import 'package:foodgo/screens/admin/manage_products_screen.dart';
import 'package:foodgo/screens/admin/manage_vouchers_screen.dart';

// Screens - Common
import 'package:foodgo/screens/common/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo định dạng ngày tháng tiếng Việt
  await initializeDateFormatting('vi_VN', null);

  // Bọc try-catch để nếu Firebase chưa config Web thì app vẫn chạy bình thường, không bị trắng màn hình
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error (Web/Desktop): $e');
  }

  runApp(const FoodGoApp());
}

class FoodGoApp extends StatelessWidget {
  const FoodGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'FoodGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          // Auth
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),

          // Customer
          AppRoutes.customerMain: (context) => const CustomerMainScreen(),
          AppRoutes.restaurantDetail: (context) =>
          const RestaurantDetailScreen(),
          AppRoutes.productDetail: (context) => const ProductDetailScreen(),
          AppRoutes.cart: (context) => const CartScreen(),
          AppRoutes.checkout: (context) => const CheckoutScreen(),
          AppRoutes.customerOrders: (context) => const CustomerOrdersScreen(),
          AppRoutes.orderDetail: (context) => const OrderDetailScreen(),
          AppRoutes.review: (context) => const ReviewScreen(),

          // Restaurant
          AppRoutes.restaurantMain: (context) => const RestaurantMainScreen(),
          AppRoutes.addProduct: (context) => const AddProductScreen(),
          AppRoutes.editProduct: (context) => const EditProductScreen(),
          AppRoutes.restaurantOrderDetail: (context) =>
          const RestaurantOrderDetailScreen(),

          // Shipper
          AppRoutes.shipperMain: (context) => const ShipperMainScreen(),
          AppRoutes.shipperOrderDetail: (context) =>
          const ShipperOrderDetailScreen(),

          // Admin
          AppRoutes.adminMain: (context) => const AdminMainScreen(),
          AppRoutes.manageProducts: (context) => const ManageProductsScreen(),
          AppRoutes.manageVouchers: (context) => const ManageVouchersScreen(),

          // Common
          AppRoutes.profile: (context) => const ProfileScreen(),
        },
      ),
    );
  }
}