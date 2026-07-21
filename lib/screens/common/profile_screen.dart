import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/user_role.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/custom_text_field.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
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
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
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
      };
      await _userService.updateUser(user.id, updates);
      authProvider.updateCurrentUser(user.copyWith(
        fullName: updates['fullName'] as String,
        phone: updates['phone'] as String,
        address: updates['address'] as String,
      ));
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công!'),
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
        title: const Text('Hồ sơ của tôi'),
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
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: user.avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.avatarUrl,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                user.role.toVietnamese(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
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
                label: 'Số điện thoại',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                readOnly: !_isEditing,
                validator: AppUtils.validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Địa chỉ',
                prefixIcon: Icons.location_on_outlined,
                readOnly: !_isEditing,
              ),
              const SizedBox(height: 32),
              if (_isEditing)
                CustomButton(
                  label: 'Lưu thay đổi',
                  onPressed: _saveProfile,
                  isLoading: _isSaving,
                ),
              const SizedBox(height: 16),
              CustomButton(
                label: 'Đăng xuất',
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
