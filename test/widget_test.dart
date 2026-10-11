import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:market_mates/features/auth/services/auth_errors.dart';
import 'package:market_mates/utils/formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  group('formatDateRange', () {
    test('same year shows the year once', () {
      expect(formatDateRange(DateTime(2026, 11, 24), DateTime(2026, 12, 22, 23, 59)),
          '24.11. – 22.12.2026');
    });
    test('across years shows both years', () {
      expect(formatDateRange(DateTime(2026, 12, 28), DateTime(2027, 1, 6)),
          '28.12.2026 – 06.01.2027');
    });
    test('single day', () {
      expect(formatDateRange(DateTime(2026, 12, 6, 10), DateTime(2026, 12, 6, 20)), '06.12.2026');
    });
  });

  group('authErrorMessage', () {
    test('wrong credentials are not told apart', () {
      expect(authErrorMessage(FirebaseAuthException(code: 'wrong-password')),
          authErrorMessage(FirebaseAuthException(code: 'user-not-found')));
    });
    test('unknown errors fall back to a generic message', () {
      expect(authErrorMessage(Exception('boom')), contains('schiefgelaufen'));
    });
  });
}
