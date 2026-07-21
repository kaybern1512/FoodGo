import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/utils/app_utils.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/providers/product_provider.dart';
import 'package:foodgo/services/storage_service.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/custom_text_field.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final StorageService _storageService = StorageService();
  File? _imageFile;
  bool _isSaving = false;
  Product? _product;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_product == null) {
      _product = ModalRoute.of(context)?.settings.arguments as Product?;
      if (_product != null) {
        _nameController.text = _product!.name;
        _descriptionController.text = _product!.description;
        _categoryController.text = _product!.category;
        _priceController.text = _product!.price.toStringAsFixed(0);
        _imageUrlController.text = _product!.imageUrl;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _product == null) return;

    setState(() => _isSaving = true);
    try {
      final productProvider = context.read<ProductProvider>();
      String imageUrl = _imageUrlController.text.trim();
      if (_imageFile != null) {
        try {
          imageUrl = await _storageService.uploadProductImage(
              _imageFile!, _product!.restaurantId);
        } catch (storageErr) {
          // Fallback if Storage fails
        }
      }

      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': imageUrl,
      };

      final success = await productProvider.updateProduct(_product!.id, updates);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi cập nhật'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sửa món ăn')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sản phẩm
              GestureDetector(
                onTap: _pickImage,
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
                      : (_imageUrlController.text.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.defaultRadius),
                              child: Image.network(
                                _imageUrlController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    const Icon(Icons.broken_image),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh từ thiết bị',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _imageUrlController,
                label: 'Hoặc dán Link URL ảnh từ Internet (Tùy chọn)',
                hint: 'https://images.unsplash.com/...',
                prefixIcon: Icons.link,
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Tên món ăn',
                prefixIcon: Icons.fastfood_outlined,
                validator: (v) =>
                    AppUtils.validateRequired(v, 'tên món ăn'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Mô tả',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _categoryController,
                label: 'Danh mục',
                prefixIcon: Icons.category_outlined,
                validator: (v) =>
                    AppUtils.validateRequired(v, 'danh mục'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'Giá (VNĐ)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: AppUtils.validatePrice,
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: 'Lưu thay đổi',
                onPressed: _save,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
