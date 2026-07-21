import 'package:flutter/material.dart';
import 'package:foodgo/core/enums/order_status.dart';

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toVietnamese(),
        style: TextStyle(
          color: _getTextColor(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade100;
      case OrderStatus.confirmed:
        return Colors.blue.shade100;
      case OrderStatus.preparing:
        return Colors.purple.shade100;
      case OrderStatus.waitingForShipper:
        return Colors.amber.shade100;
      case OrderStatus.delivering:
        return Colors.teal.shade100;
      case OrderStatus.completed:
        return Colors.green.shade100;
      case OrderStatus.cancelled:
        return Colors.grey.shade200;
      case OrderStatus.rejected:
        return Colors.red.shade100;
    }
  }

  Color _getTextColor() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade800;
      case OrderStatus.confirmed:
        return Colors.blue.shade800;
      case OrderStatus.preparing:
        return Colors.purple.shade800;
      case OrderStatus.waitingForShipper:
        return Colors.amber.shade800;
      case OrderStatus.delivering:
        return Colors.teal.shade800;
      case OrderStatus.completed:
        return Colors.green.shade800;
      case OrderStatus.cancelled:
        return Colors.grey.shade700;
      case OrderStatus.rejected:
        return Colors.red.shade800;
    }
  }
}
