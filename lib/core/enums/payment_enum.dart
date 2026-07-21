enum PaymentMethod {
  cash,
  mockWallet,
}

extension PaymentMethodExtension on PaymentMethod {
  String toFirestoreString() {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.mockWallet:
        return 'mockWallet';
    }
  }

  String toVietnamese() {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.mockWallet:
        return 'Ví điện tử';
    }
  }
}

PaymentMethod paymentMethodFromString(String value) {
  switch (value) {
    case 'cash':
      return PaymentMethod.cash;
    case 'mockWallet':
      return PaymentMethod.mockWallet;
    default:
      return PaymentMethod.cash;
  }
}

enum PaymentStatus {
  unpaid,
  paid,
}

extension PaymentStatusExtension on PaymentStatus {
  String toFirestoreString() {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'unpaid';
      case PaymentStatus.paid:
        return 'paid';
    }
  }

  String toVietnamese() {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Chưa thanh toán';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
    }
  }
}

PaymentStatus paymentStatusFromString(String value) {
  switch (value) {
    case 'unpaid':
      return PaymentStatus.unpaid;
    case 'paid':
      return PaymentStatus.paid;
    default:
      return PaymentStatus.unpaid;
  }
}
