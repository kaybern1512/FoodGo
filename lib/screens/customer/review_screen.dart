import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/models/review.dart';
import 'package:foodgo/providers/auth_provider.dart';
import 'package:foodgo/providers/review_provider.dart';
import 'package:foodgo/widgets/custom_button.dart';
import 'package:foodgo/widgets/custom_text_field.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(FoodOrder order) async {
    final user = context.read<AuthProvider>().currentUser!;
    final reviewProvider = context.read<ReviewProvider>();

    final hasReview = await reviewProvider.hasReviewForOrder(order.id);
    if (hasReview) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đơn hàng này đã được đánh giá'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final review = Review(
      id: '',
      orderId: order.id,
      customerId: user.id,
      restaurantId: order.restaurantId,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await reviewProvider.createReview(review);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cảm ơn bạn đã đánh giá!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reviewProvider.errorMessage ?? 'Lỗi khi gửi đánh giá'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as FoodOrder?;
    if (order == null) {
      return const Scaffold(body: Center(child: Text('Không tìm thấy đơn hàng')));
    }

    final reviewProvider = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá đơn hàng')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.star, size: 60, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Bạn cảm thấy thế nào?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Đơn hàng #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            // Rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            Text(
              '${_rating.toInt()} / 5',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _commentController,
              label: 'Nhận xét của bạn',
              hint: 'Chia sẻ trải nghiệm của bạn về đơn hàng này...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: 'Gửi đánh giá',
              icon: Icons.send,
              onPressed: () => _submitReview(order),
              isLoading: reviewProvider.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
