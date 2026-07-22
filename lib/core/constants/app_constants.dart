import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8C60);
  static const Color primaryDark = Color(0xFFE5501A);
  static const Color secondary = Color(0xFFFFC107);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}

class AppStrings {
  static const String appName = 'FoodGo';
  static const String tagline = 'Giao đồ ăn nhanh chóng';
}

class AppConstants {
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double cardRadius = 16.0;
  static const double shippingFee = 20000.0;
}

class FirestoreCollections {
  static const String users = 'users';
  static const String restaurants = 'restaurants';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String reviews = 'reviews';
  static const String vouchers = 'vouchers';
}
