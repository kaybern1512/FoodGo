import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo/core/enums/user_role.dart';
import 'package:foodgo/models/app_user.dart';

void main() {
  group('AppUser Model Tests', () {
    test('Default values for vehiclePlate and isOnline', () {
      final user = AppUser(
        id: '123',
        fullName: 'Nguyen Van A',
        email: 'shipper@test.com',
        phone: '0901234567',
        address: 'HCMC',
        avatarUrl: '',
        role: UserRole.shipper,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.vehiclePlate, equals(''));
      expect(user.isOnline, isFalse);
    });

    test('fromMap parses vehiclePlate and isOnline correctly', () {
      final map = {
        'fullName': 'Tran Shipper',
        'email': 'shipper2@test.com',
        'phone': '0907654321',
        'address': 'Ha Noi',
        'avatarUrl': 'http://avatar.url',
        'role': 'shipper',
        'isActive': true,
        'vehiclePlate': '29-A1 999.99',
        'isOnline': true,
        'createdAt': '2026-07-21T08:00:00.000Z',
      };

      final user = AppUser.fromMap(map, 'user_999');

      expect(user.id, equals('user_999'));
      expect(user.fullName, equals('Tran Shipper'));
      expect(user.role, equals(UserRole.shipper));
      expect(user.vehiclePlate, equals('29-A1 999.99'));
      expect(user.isOnline, isTrue);
    });

    test('toMap exports vehiclePlate and isOnline', () {
      final user = AppUser(
        id: 'shipper_001',
        fullName: 'Le Van Shipper',
        email: 'shipper3@test.com',
        phone: '0988888888',
        address: 'Da Nang',
        avatarUrl: '',
        role: UserRole.shipper,
        isActive: true,
        vehiclePlate: '43-C1 123.45',
        isOnline: true,
        createdAt: DateTime(2026, 7, 21),
      );

      final map = user.toMap();

      expect(map['vehiclePlate'], equals('43-C1 123.45'));
      expect(map['isOnline'], isTrue);
      expect(map['role'], equals('shipper'));
    });

    test('copyWith works correctly with new fields', () {
      final user = AppUser(
        id: '001',
        fullName: 'Base User',
        email: 'base@test.com',
        phone: '0900000000',
        address: '',
        avatarUrl: '',
        role: UserRole.shipper,
        isActive: true,
        vehiclePlate: '59-S1 111.11',
        isOnline: false,
        createdAt: DateTime.now(),
      );

      final updated = user.copyWith(
        vehiclePlate: '59-S2 222.22',
        isOnline: true,
      );

      expect(updated.vehiclePlate, equals('59-S2 222.22'));
      expect(updated.isOnline, isTrue);
      expect(updated.fullName, equals('Base User'));
    });
  });
}
