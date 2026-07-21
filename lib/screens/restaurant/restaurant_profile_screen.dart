import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/routes/app_routes.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/restaurant_provider.dart';
import 'package:foodgo/services/storage_service.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/custom_text_field.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Thông tin chủ nhà hàng
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();

  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();

  bool _isEditing = false;
  bool _isSaving = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  void _initData() {
    final restaurant = context.read<RestaurantProvider>().myRestaurant;
    final user = context.read<AuthProvider>().currentUser;

    if (restaurant != null) {
      _nameController.text = restaurant.name;
      _descriptionController.text = restaurant.description;
      _addressController.text = restaurant.address;
      _phoneController.text = restaurant.phone;
    }

    if (user != null) {
      _ownerNameController.text = user.fullName;
      _ownerPhoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveAll() async {
    if (!_formKey.currentState!.validate()) return;
    final restaurantProvider = context.read<RestaurantProvider>();
    final authProvider = context.read<AuthProvider>();
    final restaurant = restaurantProvider.myRestaurant;
    final user = authProvider.currentUser;

    if (restaurant == null || user == null) return;

    setState(() => _isSaving = true);
    try {
      // 1. Cập nhật thông tin Nhà hàng
      String imageUrl = restaurant.imageUrl;
      if (_imageFile != null) {
        try {
          imageUrl = await _storageService.uploadRestaurantImage(
              _imageFile!, restaurant.id);
        } catch (e) {
          // Ignored if storage upload fails
        }
      }

      final restaurantUpdates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'imageUrl': imageUrl,
      };

      await restaurantProvider.updateRestaurant(
          restaurant.id, restaurantUpdates);

      // 2. Cập nhật thông tin Cá nhân chủ nhà hàng
      final userUpdates = {
        'fullName': _ownerNameController.text.trim(),
        'phone': _ownerPhoneController.text.trim(),
      };
      await _userService.updateUser(user.id, userUpdates);
      authProvider.updateCurrentUser(user.copyWith(
        fullName: userUpdates['fullName'] as String,
        phone: userUpdates['phone'] as String,
      ));

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin Nhà hàng & Cá nhân thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
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
    final restaurantProvider = context.watch<RestaurantProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final restaurant = restaurantProvider.myRestaurant;

    if (restaurantProvider.isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhà hàng & Chủ sở hữu'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _initData();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (restaurant == null) ...[
                const Center(
                  child: Text(
                    'Bạn chưa khởi tạo dữ liệu nhà hàng',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const Text(
                  '1. Thông tin Nhà hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                // Banner ảnh nhà hàng
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius:
                          BorderRadius.circular(AppConstants.defaultRadius),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                                AppConstants.defaultRadius),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : (restaurant.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.defaultRadius),
                                child: Image.network(restaurant.imageUrl,
                                    fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.store,
                                      size: 50, color: Colors.grey),
                                  if (_isEditing)
                                    const Text('Nhấn để chọn ảnh banner',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                ],
                              )),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Tên nhà hàng',
                  prefixIcon: Icons.storefront_outlined,
                  readOnly: !_isEditing,
                  validator: (v) =>
                      AppUtils.validateRequired(v, 'tên nhà hàng'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Mô tả nhà hàng',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 3,
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Địa chỉ nhà hàng',
                  prefixIcon: Icons.location_on_outlined,
                  readOnly: !_isEditing,
                  validator: (v) =>
                      AppUtils.validateRequired(v, 'địa chỉ nhà hàng'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Số điện thoại nhà hàng',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  readOnly: !_isEditing,
                  validator: AppUtils.validatePhone,
                ),
              ],

              const Divider(height: 32),
              const Text(
                '2. Thông tin Tài khoản Chủ nhà hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _ownerNameController,
                label: 'Họ và tên chủ nhà hàng',
                prefixIcon: Icons.person_outlined,
                readOnly: !_isEditing,
                validator: (v) =>
                    AppUtils.validateRequired(v, 'họ và tên chủ nhà hàng'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: TextEditingController(text: user?.email ?? ''),
                label: 'Email tài khoản (không thể sửa)',
                prefixIcon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _ownerPhoneController,
                label: 'Số điện thoại cá nhân chủ nhà hàng',
                prefixIcon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                readOnly: !_isEditing,
                validator: AppUtils.validatePhone,
              ),

              const SizedBox(height: 32),
              if (_isEditing) ...[
                CustomButton(
                  label: 'Lưu tất cả thay đổi',
                  onPressed: _saveAll,
                  isLoading: _isSaving,
                ),
                const SizedBox(height: 16),
              ],

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
