enum UserRole {
  customer,
  restaurant,
  shipper,
  admin,
}

extension UserRoleExtension on UserRole {
  String toFirestoreString() {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.restaurant:
        return 'restaurant';
      case UserRole.shipper:
        return 'shipper';
      case UserRole.admin:
        return 'admin';
    }
  }

  String toVietnamese() {
    switch (this) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.restaurant:
        return 'Nhà hàng';
      case UserRole.shipper:
        return 'Shipper';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }
}

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'customer':
      return UserRole.customer;
    case 'restaurant':
      return UserRole.restaurant;
    case 'shipper':
      return UserRole.shipper;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.customer;
  }
}
