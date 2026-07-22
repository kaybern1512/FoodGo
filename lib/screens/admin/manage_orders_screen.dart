import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/providers/order_provider.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';
import 'package:foodgo/widgets/order_status_chip.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  OrderStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadAllOrders();
    });
  }

  /// Xuất báo cáo danh sách đơn hàng sang CSV
  void _exportCSV(List<FoodOrder> orders) {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không có đơn hàng để xuất CSV!'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
        'Mã Đơn,Khách Hàng,SĐT,Nhà Hàng,Tổng Tiền,Trạng Thái,Ngày Tạo');

    for (var o in orders) {
      final code = '#${o.id.substring(0, 8).toUpperCase()}';
      final name = o.customerName.replaceAll(',', ' ');
      final phone = o.customerPhone;
      final amount = o.totalAmount;
      final status = o.orderStatus.toVietnamese();
      final date = AppUtils.formatDateTime(o.createdAt);
      buffer.writeln('$code,$name,$phone,$amount,$status,$date');
    }

    final csvData = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvData));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Đã xuất và sao chép báo cáo đơn hàng (CSV) vào Clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// Hủy đơn hàng khẩn cấp & Xử lý tranh chấp
  void _emergencyCancelOrder(FoodOrder order) {
    String selectedReason = 'Tranh chấp Khách - Shipper';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 8),
                Text('Hủy đơn khẩn cấp', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn đang hủy đơn hàng #${order.id.substring(0, 8).toUpperCase()} với tư cách Quản trị viên.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  const Text('Chọn lý do hủy khẩn cấp:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Tranh chấp Khách - Shipper',
                        child: Text('Tranh chấp Khách - Shipper'),
                      ),
                      DropdownMenuItem(
                        value: 'Nhà hàng báo hết món / Sự cố',
                        child: Text('Nhà hàng báo hết món / Sự cố'),
                      ),
                      DropdownMenuItem(
                        value: 'Shipper gặp sự cố di chuyển',
                        child: Text('Shipper gặp sự cố di chuyển'),
                      ),
                      DropdownMenuItem(
                        value: 'Nghi vấn gian lận',
                        child: Text('Nghi vấn gian lận'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedReason = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú bổ sung của Admin (tùy chọn)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy bỏ'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () async {
                  final finalReason = reasonController.text.trim().isNotEmpty
                      ? '$selectedReason: ${reasonController.text.trim()}'
                      : selectedReason;

                  final orderProvider = context.read<OrderProvider>();
                  final ok = await orderProvider.updateOrderStatus(
                    order.id,
                    OrderStatus.cancelled,
                  );

                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);

                  if (ok) {
                    if (context.mounted) {
                      Navigator.pop(context); // đóng Modal Detail
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '🚨 Đã hủy đơn khẩn cấp thành công! Lý do: $finalReason'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('Xác nhận hủy đơn',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderDetailModal(BuildContext context, FoodOrder order) {
    final canCancel = order.orderStatus != OrderStatus.completed &&
        order.orderStatus != OrderStatus.cancelled &&
        order.orderStatus != OrderStatus.rejected;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết đơn #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      OrderStatusChip(status: order.orderStatus),
                    ],
                  ),
                  const Divider(height: 24),
                  _row('Khách hàng', order.customerName),
                  _row('Số điện thoại', order.customerPhone),
                  _row('Địa chỉ giao', order.deliveryAddress),
                  if (order.note.isNotEmpty) _row('Ghi chú', order.note),
                  const Divider(height: 24),
                  const Text('Sản phẩm',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${item.quantity}x ${item.productName}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const Spacer(),
                          Text(AppUtils.formatCurrency(item.totalPrice)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  _row('Thanh toán', order.paymentMethod.toVietnamese()),
                  _row('Trạng thái TT', order.paymentStatus.toVietnamese()),
                  _row('Tạm tính', AppUtils.formatCurrency(order.subtotal)),
                  _row('Phí giao hàng',
                      AppUtils.formatCurrency(order.shippingFee)),
                  _row('Tổng cộng', AppUtils.formatCurrency(order.totalAmount),
                      isBold: true),
                  const SizedBox(height: 20),

                  // ── Nút Hủy Khẩn Cấp Dành Cho Admin ──
                  if (canCancel) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('🚨 HỦY KHẨN CẤP / XỬ LÝ SỰ CỐ'),
                        onPressed: () => _emergencyCancelOrder(order),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    final filteredOrders = orderProvider.orders.where((o) {
      if (_selectedStatusFilter == null) return true;
      return o.orderStatus == _selectedStatusFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Đơn hàng (${filteredOrders.length}/${orderProvider.orders.length})'),
        actions: [
          IconButton(
            tooltip: 'Xuất CSV Báo Cáo',
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _exportCSV(filteredOrders),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => orderProvider.loadAllOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedStatusFilter == null,
                  onSelected: (_) =>
                      setState(() => _selectedStatusFilter = null),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Chờ xác nhận'),
                  selected: _selectedStatusFilter == OrderStatus.pending,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.pending),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Chờ shipper'),
                  selected:
                      _selectedStatusFilter == OrderStatus.waitingForShipper,
                  onSelected: (_) => setState(() => _selectedStatusFilter =
                      OrderStatus.waitingForShipper),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Đang giao'),
                  selected: _selectedStatusFilter == OrderStatus.delivering,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.delivering),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Hoàn thành'),
                  selected: _selectedStatusFilter == OrderStatus.completed,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.completed),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Đã hủy'),
                  selected: _selectedStatusFilter == OrderStatus.cancelled,
                  onSelected: (_) => setState(
                      () => _selectedStatusFilter = OrderStatus.cancelled),
                ),
              ],
            ),
          ),
          Expanded(
            child: orderProvider.isLoading
                ? const LoadingWidget()
                : filteredOrders.isEmpty
                    ? const EmptyStateWidget(
                        message: 'Không có đơn hàng nào phù hợp',
                        icon: Icons.receipt_long_outlined,
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _showOrderDetailModal(context, order),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '#${order.id.substring(0, 8).toUpperCase()}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        OrderStatusChip(status: order.orderStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.customerName,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      '${order.items.length} món • ${AppUtils.formatCurrency(order.totalAmount)}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12),
                                    ),
                                    Text(
                                      AppUtils.formatDateTime(order.createdAt),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
