import 'package:flutter/material.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/voucher.dart';
import 'package:foodgo/services/voucher_service.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ManageVouchersScreen extends StatefulWidget {
  const ManageVouchersScreen({super.key});

  @override
  State<ManageVouchersScreen> createState() => _ManageVouchersScreenState();
}

class _ManageVouchersScreenState extends State<ManageVouchersScreen> {
  final VoucherService _voucherService = VoucherService();
  List<Voucher> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _voucherService.getAllVouchers();
      if (mounted) setState(() => _vouchers = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddVoucherDialog() {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final minOrderCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo Mã Giảm Giá Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Mã Voucher (VD: TET2026)',
                  hintText: 'Nhập mã in hoa không dấu',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mô tả ngắn',
                  hintText: 'Giảm 20k ship cho đơn từ 40k',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: discountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền giảm (đ)',
                  hintText: '20000',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: minOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Đơn tối thiểu (đ)',
                  hintText: '40000',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: limitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lượng voucher phát ra (lượt)',
                  hintText: '50',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              final discount = double.tryParse(discountCtrl.text.trim()) ?? 0;
              final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0;
              final limit = int.tryParse(limitCtrl.text.trim()) ?? 50;

              if (code.isEmpty || discount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập Mã và Số tiền giảm hợp lệ!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              final newVoucher = Voucher(
                id: '',
                code: code,
                description: descCtrl.text.trim().isEmpty
                    ? 'Giảm ${AppUtils.formatCurrency(discount)}'
                    : descCtrl.text.trim(),
                discountAmount: discount,
                minOrderAmount: minOrder,
                usageLimit: limit,
                usedCount: 0,
                isActive: true,
                createdAt: DateTime.now(),
              );

              await _voucherService.createVoucher(newVoucher);
              _loadVouchers();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã tạo thành công voucher "$code"!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Tạo ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Voucher (${_vouchers.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadVouchers),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Đang tải danh sách voucher...')
          : _vouchers.isEmpty
              ? const EmptyStateWidget(
                  message: 'Chưa có mã giảm giá nào trên Firebase',
                  icon: Icons.confirmation_number_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: _vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = _vouchers[index];
                    final isOutOfStock = voucher.remainingCount <= 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.defaultRadius),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon voucher
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: (voucher.isActive && !isOutOfStock)
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.confirmation_number,
                                color: (voucher.isActive && !isOutOfStock)
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Thông tin voucher (Expanded để chống tràn màn hình)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          voucher.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? Colors.orange.shade100
                                              : (voucher.isActive
                                                  ? Colors.green.shade100
                                                  : Colors.red.shade100),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isOutOfStock
                                              ? 'Hết lượt'
                                              : (voucher.isActive
                                                  ? 'Đang bật'
                                                  : 'Đã tắt'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isOutOfStock
                                                ? Colors.orange.shade900
                                                : (voucher.isActive
                                                    ? Colors.green.shade800
                                                    : Colors.red.shade800),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    voucher.description,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Giảm: ${AppUtils.formatCurrency(voucher.discountAmount)} (Đơn từ ${AppUtils.formatCurrency(voucher.minOrderAmount)})',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),

                                  // Hiển thị Số lượng còn lại
                                  Row(
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined,
                                          size: 13, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Số lượng còn: ',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        '${voucher.remainingCount} / ${voucher.usageLimit} lượt',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOutOfStock
                                              ? Colors.red
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Công tắc & Nút xóa
                            Column(
                              children: [
                                SizedBox(
                                  height: 32,
                                  width: 44,
                                  child: Transform.scale(
                                    scale: 0.7,
                                    child: Switch(
                                      value: voucher.isActive,
                                      activeTrackColor: AppColors.primary,
                                      onChanged: (val) async {
                                        await _voucherService
                                            .toggleVoucherStatus(
                                                voucher.id, val);
                                        _loadVouchers();
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(top: 8),
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () async {
                                    await _voucherService
                                        .deleteVoucher(voucher.id);
                                    _loadVouchers();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddVoucherDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo Voucher', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
