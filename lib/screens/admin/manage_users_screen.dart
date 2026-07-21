import 'package:flutter/material.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/user_role.dart';
import 'package:foodgo/models/app_user.dart';
import 'package:foodgo/services/user_service.dart';
import 'package:foodgo/widgets/empty_state_widget.dart';
import 'package:foodgo/widgets/loading_widget.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService _userService = UserService();
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải dữ liệu: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(AppUser user) async {
    // Bảo vệ không bao giờ cho phép khóa tài khoản Admin
    if (user.role == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể khóa tài khoản Quản trị viên (Admin)!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newStatus = !user.isActive;
    try {
      await _userService.setUserActiveStatus(user.id, newStatus);
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Đã duyệt / mở khóa: ${user.fullName}'
                : 'Đã khóa: ${user.fullName}'),
            backgroundColor: newStatus ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.restaurant:
        return Colors.orange;
      case UserRole.shipper:
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Người dùng (${_users.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Đang tải danh sách người dùng...')
          : _users.isEmpty
              ? const EmptyStateWidget(
                  message: 'Chưa có người dùng nào', icon: Icons.people)
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isPending = !user.isActive &&
                          (user.role == UserRole.restaurant ||
                              user.role == UserRole.shipper);
                      final roleColor = _roleColor(user.role);

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isPending
                                ? Colors.orange.shade300
                                : (!user.isActive
                                    ? Colors.red.shade200
                                    : Colors.transparent),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: roleColor.withValues(alpha: 0.15),
                                child: Text(
                                  (user.fullName.isNotEmpty
                                          ? user.fullName[0]
                                          : user.email[0])
                                      .toUpperCase(),
                                  style: TextStyle(
                                      color: roleColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.fullName.isEmpty
                                                ? '(Chưa cập nhật)'
                                                : user.fullName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // Badge
                                        if (isPending)
                                          const _Badge(
                                              label: 'Chờ duyệt',
                                              color: Colors.orange)
                                        else if (!user.isActive)
                                          const _Badge(
                                              label: 'Bị khóa', color: Colors.red),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(user.email,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    // Role badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: roleColor.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(user.role.toVietnamese(),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: roleColor,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Action button (Khóa Admin là KHÔNG ĐƯỢC PHÉP)
                              if (user.role != UserRole.admin)
                                _ActionButton(
                                  isActive: user.isActive,
                                  isPending: isPending,
                                  onTap: () => _showConfirm(user, isPending),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.purple.shade200),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.shield,
                                          size: 14, color: Colors.purple),
                                      SizedBox(width: 4),
                                      Text(
                                        'Bảo vệ',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showConfirm(AppUser user, bool isPending) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isActive
            ? 'Khóa tài khoản'
            : (isPending ? 'Phê duyệt tài khoản' : 'Mở khóa tài khoản')),
        content: Text(user.isActive
            ? 'Bạn có chắc muốn khóa tài khoản của "${user.fullName}"?'
            : 'Phê duyệt và kích hoạt tài khoản "${user.fullName}" (${user.role.toVietnamese()})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user.isActive ? AppColors.error : AppColors.success,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _toggleStatus(user);
            },
            child: Text(
              user.isActive ? 'Khóa' : 'Xác nhận duyệt',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isActive;
  final bool isPending;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.isActive, required this.isPending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.error : AppColors.success;
    final label = isActive ? 'Khóa' : (isPending ? 'Duyệt' : 'Mở khóa');
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(60, 32),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
