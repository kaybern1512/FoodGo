class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Customer
  static const String customerMain = '/customer/main';
  static const String customerHome = '/customer/home';
  static const String restaurantDetail = '/customer/restaurant-detail';
  static const String productDetail = '/customer/product-detail';
  static const String cart = '/customer/cart';
  static const String checkout = '/customer/checkout';
  static const String customerOrders = '/customer/orders';
  static const String orderDetail = '/customer/order-detail';
  static const String review = '/customer/review';
  static const String profile = '/profile';

  // Restaurant
  static const String restaurantMain = '/restaurant/main';
  static const String restaurantDashboard = '/restaurant/dashboard';
  static const String restaurantProfile = '/restaurant/profile';
  static const String restaurantProducts = '/restaurant/products';
  static const String addProduct = '/restaurant/add-product';
  static const String editProduct = '/restaurant/edit-product';
  static const String restaurantOrders = '/restaurant/orders';
  static const String restaurantOrderDetail = '/restaurant/order-detail';
  static const String restaurantRevenue = '/restaurant/revenue';

  // Shipper
  static const String shipperMain = '/shipper/main';
  static const String availableOrders = '/shipper/available-orders';
  static const String currentDelivery = '/shipper/current-delivery';
  static const String shipperOrderDetail = '/shipper/order-detail';
  static const String shipperHistory = '/shipper/history';
  static const String shipperProfile = '/shipper/profile';

  // Admin
  static const String adminMain = '/admin/main';
  static const String adminDashboard = '/admin/dashboard';
  static const String manageUsers = '/admin/users';
  static const String manageRestaurants = '/admin/restaurants';
  static const String manageProducts = '/admin/products';
  static const String manageOrders = '/admin/orders';
  static const String adminProfile = '/admin/profile';
}
