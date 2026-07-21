enum OrderStatus {
  pending,
  confirmed,
  preparing,
  waitingForShipper,
  delivering,
  completed,
  cancelled,
  rejected,
}

extension OrderStatusExtension on OrderStatus {
  String toFirestoreString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.waitingForShipper:
        return 'waitingForShipper';
      case OrderStatus.delivering:
        return 'delivering';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.rejected:
        return 'rejected';
    }
  }

  String toVietnamese() {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.preparing:
        return 'Đang chuẩn bị';
      case OrderStatus.waitingForShipper:
        return 'Chờ shipper';
      case OrderStatus.delivering:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
      case OrderStatus.rejected:
        return 'Bị từ chối';
    }
  }

  bool canTransitionTo(OrderStatus next) {
    switch (this) {
      case OrderStatus.pending:
        return next == OrderStatus.confirmed ||
            next == OrderStatus.cancelled ||
            next == OrderStatus.rejected;
      case OrderStatus.confirmed:
        return next == OrderStatus.preparing;
      case OrderStatus.preparing:
        return next == OrderStatus.waitingForShipper;
      case OrderStatus.waitingForShipper:
        return next == OrderStatus.delivering;
      case OrderStatus.delivering:
        return next == OrderStatus.completed;
      default:
        return false;
    }
  }
}

OrderStatus orderStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'preparing':
      return OrderStatus.preparing;
    case 'waitingForShipper':
      return OrderStatus.waitingForShipper;
    case 'delivering':
      return OrderStatus.delivering;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'rejected':
      return OrderStatus.rejected;
    default:
      return OrderStatus.pending;
  }
}
