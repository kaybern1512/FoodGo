import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/custom_text_field.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ShipperProfileScreen extends StatefulWidget {
  const ShipperProfileScreen({super.key});

  @override
  State<ShipperProfileScreen> createState() => _ShipperProfileScreenState();
}

class _ShipperProfileScreenState extends State<ShipperProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final UserService _userService = UserService();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone;
      _addressController.text = user.address;
      _vehiclePlateController.text = user.vehiclePlate;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    try {
      await _userService.setOnlineStatus(user.id, value);
      authProvider.updateCurrentUser(user.copyWith(isOnline: value));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Đã bật nhận đơn! Bạn đang Online 🟢'
                : 'Đã tắt nhận đơn. Bạn đang Offline 🔴'),
            backgroundColor: value ? AppColors.success : Colors.grey.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser!;
      final updates = {
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'vehiclePlate': _vehiclePlateController.text.trim().toUpperCase(),
      };
      await _userService.updateUser(user.id, updates);
      authProvider.updateCurrentUser(user.copyWith(
        fullName: updates['fullName'] as String,
        phone: updates['phone'] as String,
        address: updates['address'] as String,
        vehiclePlate: updates['vehiclePlate'] as String,
      ));
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ tài xế thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const LoadingWidget();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Tài xế (Shipper)'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Status Online / Offline Switch Card ──
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  side: BorderSide(
                    color: user.isOnline
                        ? AppColors.success.withValues(alpha: 0.5)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                color: user.isOnline
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.grey.shade50,
                child: SwitchListTile(
                  activeThumbColor: AppColors.success,
                  title: Row(
                    children: [
                      Icon(
                        user.isOnline ? Icons.sensors : Icons.sensors_off,
                        color: user.isOnline ? AppColors.success : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        user.isOnline ? 'ĐANG BẬT NHẬN ĐƠN' : 'ĐANG TẮT NHẬN ĐƠN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: user.isOnline ? AppColors.success : Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    user.isOnline
                        ? 'Hệ thống sẽ phân bổ các đơn hàng mới cho bạn'
                        : 'Bật công tắc để bắt đầu nhận đơn giao',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: user.isOnline,
                  onChanged: _toggleOnlineStatus,
                ),
              ),
              const SizedBox(height: 16),

              // Avatar & Role
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(
                  Icons.two_wheeler,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tài xế giao hàng (Shipper)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Thông tin biển số xe
              CustomTextField(
                controller: _vehiclePlateController,
                label: 'Biển số xe',
                prefixIcon: Icons.directions_bike,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _fullNameController,
                label: 'Họ và tên tài xế',
                prefixIcon: Icons.person_outlined,
                readOnly: !_isEditing,
                validator: (v) => AppUtils.validateRequired(v, 'họ và tên'),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: TextEditingController(text: user.email),
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _phoneController,
                label: 'Số điện thoại liên hệ',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                readOnly: !_isEditing,
                validator: AppUtils.validatePhone,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _addressController,
                label: 'Khu vực hoạt động / Địa chỉ',
                prefixIcon: Icons.location_on_outlined,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 28),

              if (_isEditing)
                CustomButton(
                  label: 'Lưu thay đổi hồ sơ',
                  onPressed: _saveProfile,
                  isLoading: _isSaving,
                ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Đăng xuất tài khoản',
                onPressed: _signOut,
                isOutlined: true,
                color: AppColors.error,
                icon: Icons.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
