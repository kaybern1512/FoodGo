# FoodGo 🍔

Ứng dụng đặt và giao đồ ăn Android viết bằng Flutter — Đồ án môn học cho nhóm 4 người.

---

## Công nghệ sử dụng

| Thành phần | Công nghệ |
|-----------|----------|
| Framework | Flutter (Dart) |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| State Management | Provider (ChangeNotifier) |
| UI | Material 3 |

---

## Cấu trúc thư mục

```
lib/
├── main.dart                  # Entry point
├── firebase_options.dart      # Firebase config (cần thay thế)
├── core/
│   ├── constants/             # Màu sắc, chuỗi, hằng số
│   ├── enums/                 # OrderStatus, UserRole, PaymentMethod
│   ├── routes/                # AppRoutes
│   ├── theme/                 # AppTheme (Material 3)
│   └── utils/                 # AppUtils (format, validate)
├── models/                    # AppUser, Restaurant, Product, CartItem, OrderItem, FoodOrder, Review
├── services/                  # AuthService, UserService, RestaurantService, ProductService,
│                              # OrderService, ReviewService, StorageService, SeedService
├── providers/                 # AuthProvider, RestaurantProvider, ProductProvider,
│                              # CartProvider, OrderProvider, ReviewProvider
├── screens/
│   ├── auth/                  # SplashScreen, LoginScreen, RegisterScreen
│   ├── common/                # ProfileScreen
│   ├── customer/              # CustomerMainScreen, CustomerHomeScreen, RestaurantDetailScreen,
│   │                          # ProductDetailScreen, CartScreen, CheckoutScreen,
│   │                          # CustomerOrdersScreen, OrderDetailScreen, ReviewScreen
│   ├── restaurant/            # RestaurantMainScreen, RestaurantDashboardScreen,
│   │                          # RestaurantProductsScreen, AddProductScreen, EditProductScreen,
│   │                          # RestaurantOrdersScreen, RestaurantOrderDetailScreen,
│   │                          # RestaurantRevenueScreen
│   ├── shipper/               # ShipperMainScreen, AvailableOrdersScreen,
│   │                          # CurrentDeliveryScreen, ShipperHistoryScreen
│   └── admin/                 # AdminMainScreen, AdminDashboardScreen, ManageUsersScreen,
│                              # ManageRestaurantsScreen, ManageOrdersScreen
└── widgets/                   # CustomButton, CustomTextField, LoadingWidget, EmptyStateWidget,
                               # RestaurantCard, ProductCard, CartItemCard, OrderCard,
                               # OrderStatusChip, ConfirmDialog
```

---

## Hướng dẫn thiết lập Firebase

### Bước 1 — Tạo dự án Firebase

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Nhấn **Add project** → Đặt tên `foodgo`
3. Bật **Google Analytics** nếu muốn

### Bước 2 — Kích hoạt Firebase services

- **Authentication**: Console → Authentication → Sign-in method → Bật **Email/Password**
- **Cloud Firestore**: Console → Firestore Database → Create database (chọn **test mode** để dev)
- **Storage**: Console → Storage → Get started

### Bước 3 — Kết nối Flutter với Firebase

```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Đăng nhập Firebase
firebase login

# Chạy trong thư mục dự án
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

Lệnh này sẽ tự động tạo/cập nhật `lib/firebase_options.dart`.

### Bước 4 — Chạy ứng dụng

```bash
flutter pub get
flutter run
```

---

## Hướng dẫn tạo tài khoản cho từng vai trò

### Quy trình chung

1. **Tạo tài khoản Firebase Auth** (email + password)
2. **Tạo tài liệu Firestore** tương ứng trong collection `users`

### Tài khoản Customer (tự đăng ký)

Khách hàng có thể tự đăng ký trong ứng dụng qua màn hình **Đăng ký**.  
Hệ thống tự tạo tài khoản với `role: "customer"`.

### Tài khoản Restaurant / Shipper / Admin (tạo thủ công)

**Bước 1 — Tạo tài khoản Firebase Auth:**

Vào Firebase Console → Authentication → Users → **Add user**:
```
Email: restaurant@foodgo.com
Password: 123456
```

Ghi lại UID sau khi tạo (dạng: `AbCdEfGhIjKlMnOp...`).

**Bước 2 — Tạo tài liệu Firestore:**

Vào Console → Firestore → Collection `users` → **Add document**:
- Document ID: **(chính xác UID ở trên)**
- Fields:

```json
{
  "fullName": "Nhà Hàng Mẫu",
  "email": "restaurant@foodgo.com",
  "phone": "0901234567",
  "address": "123 Đường ABC, TP.HCM",
  "avatarUrl": "",
  "role": "restaurant",
  "isActive": true,
  "createdAt": (timestamp hiện tại)
}
```

**Giá trị `role` hợp lệ:**

| Vai trò | Giá trị Firestore |
|---------|------------------|
| Khách hàng | `customer` |
| Nhà hàng | `restaurant` |
| Shipper | `shipper` |
| Quản trị | `admin` |

### Ví dụ tạo tài khoản Admin

```json
Document ID: <UID từ Firebase Auth>
{
  "fullName": "Admin FoodGo",
  "email": "admin@foodgo.com",
  "phone": "0900000000",
  "address": "Hà Nội",
  "avatarUrl": "",
  "role": "admin",
  "isActive": true,
  "createdAt": <Timestamp>
}
```

---

## Firestore Security Rules (Development)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

> ⚠️ Đây là quy tắc dành cho môi trường dev. Cần siết chặt hơn khi deploy production.

---

## Seed dữ liệu mẫu (Tùy chọn)

Trong `SeedService` (`lib/services/seed_service.dart`) có sẵn các method để seed dữ liệu:

```dart
final seedService = SeedService();

// Seed tài khoản admin (cần tạo Auth trước, truyền UID vào)
await seedService.seedAdminUser('YOUR_ADMIN_UID');

// Seed nhà hàng + 5 sản phẩm mẫu
await seedService.seedRestaurantAndProducts('YOUR_RESTAURANT_OWNER_UID');
```

Gọi trong màn hình debug hoặc trong initState tạm thời, **không** gọi tự động khi khởi động.

---

## Phân chia công việc (4 người)

| Thành viên | Phần phụ trách |
|-----------|---------------|
| Thành viên 1 | Xác thực (AuthService, AuthProvider, LoginScreen, RegisterScreen, SplashScreen) + Models + Enums |
| Thành viên 2 | Tính năng Customer (CustomerHomeScreen, RestaurantDetailScreen, CartScreen, CheckoutScreen) |
| Thành viên 3 | Tính năng Restaurant (RestaurantDashboardScreen, RestaurantProductsScreen, AddProductScreen, RestaurantOrdersScreen, RestaurantRevenueScreen) |
| Thành viên 4 | Tính năng Shipper + Admin (ShipperMainScreen, AdminMainScreen, ManageUsersScreen, ManageRestaurantsScreen) |

---

## Trạng thái đơn hàng

```
pending → confirmed → preparing → waitingForShipper → delivering → completed
pending → cancelled (khách hủy)
pending → rejected (nhà hàng từ chối)
```

---

## Lưu ý quan trọng

- `firebase_options.dart` hiện là **placeholder** — phải chạy `flutterfire configure` để thay thế
- Không lưu mật khẩu vào Firestore
- Tài khoản bị khóa (`isActive: false`) sẽ không thể đăng nhập
- Giỏ hàng chỉ chứa sản phẩm từ **một nhà hàng** tại một thời điểm
- Shipper nhận đơn dùng **Firestore Transaction** để tránh xung đột
