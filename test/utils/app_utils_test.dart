import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo/core/utils/app_utils.dart';

void main() {
  group('AppUtils Tests', () {
    test('validateEmail correctly checks emails', () {
      expect(AppUtils.validateEmail('test@gmail.com'), isNull);
      expect(AppUtils.validateEmail('invalid-email'), equals('Email không hợp lệ'));
      expect(AppUtils.validateEmail(''), equals('Vui lòng nhập email'));
    });

    test('validatePhone correctly checks Vietnamese phone numbers', () {
      expect(AppUtils.validatePhone('0901234567'), isNull);
      expect(AppUtils.validatePhone('0389999999'), isNull);
      expect(AppUtils.validatePhone('12345'), equals('Số điện thoại không hợp lệ'));
      expect(AppUtils.validatePhone(''), equals('Vui lòng nhập số điện thoại'));
    });
  });
}
