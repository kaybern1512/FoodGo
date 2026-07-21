import 'package:flutter/material.dart';
import 'package:foodgo/core/enums/user_role.dart';
import 'package:foodgo/models/app_user.dart';
import 'package:foodgo/services/auth_service.dart';
import 'package:foodgo/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Khởi tạo: kiểm tra trạng thái đăng nhập
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _currentUser = await _userService.getUserById(uid);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Đăng nhập
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadUserData(credential.user!.uid);

      // Kiểm tra tài khoản chưa duyệt hoặc bị khóa
      if (_currentUser != null && !_currentUser!.isActive) {
        final roleName = _currentUser!.role == UserRole.restaurant
            ? 'Nhà hàng'
            : (_currentUser!.role == UserRole.shipper ? 'Shipper' : 'người dùng');

        await _authService.signOut();
        _currentUser = null;
        _setError(
            'Tài khoản $roleName của bạn đang chờ Admin phê duyệt hoặc đã bị khóa.');
        return false;
      }
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Đăng ký tài khoản (Khách hàng tự động kích hoạt, Nhà hàng & Shipper cần Admin duyệt)
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    UserRole role = UserRole.customer,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Khách hàng kích hoạt ngay, Nhà hàng & Shipper chờ Admin duyệt
      final bool isActive = (role == UserRole.customer);

      final user = AppUser(
        id: credential.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        address: '',
        avatarUrl: '',
        role: role,
        isActive: isActive,
        createdAt: DateTime.now(),
      );
      await _userService.createUser(user);

      if (isActive) {
        _currentUser = user;
      } else {
        await _authService.signOut();
        _currentUser = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Đăng xuất
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật thông tin người dùng hiện tại trong bộ nhớ
  void updateCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }
}
