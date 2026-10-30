import 'package:flutter_test/flutter_test.dart';
import 'package:vibenance/utils/bank_detector.dart';

void main() {
  group('detectBank', () {
    test('detects Spanish banks by IBAN 4-digit entity code', () {
      expect(
        detectBank('Cuenta genérica', 'ES91 2100 1234 16 1234567890')?.fullName,
        'CaixaBank',
      );
      expect(
        detectBank('Cuenta genérica', 'ES8000491234123412345678')?.fullName,
        'Santander',
      );
      expect(
        detectBank('Cuenta genérica', 'ES8201821234123412345678')?.fullName,
        'BBVA',
      );
      expect(
        detectBank('Cuenta genérica', 'ES93 1465 1234 16 1234567890')?.fullName,
        'ING',
      );
    });

    test('falls back to account name when IBAN is empty or non-Spanish', () {
      expect(detectBank('Cuenta BBVA', null)?.fullName, 'BBVA');
      expect(
        detectBank('Cuenta Revolut', 'GB29NWBK60161331926819')?.fullName,
        'Revolut',
      );
      expect(
        detectBank('Cuenta N26', 'DE89370400440532013000')?.fullName,
        'N26',
      );
      expect(
        detectBank('Mi Openbank', 'FR1420041010050500013M02606')?.fullName,
        'Openbank',
      );
    });

    test('Spanish IBAN takes precedence over account name keywords', () {
      // Name says BBVA but IBAN belongs to CaixaBank; IBAN should win.
      expect(
        detectBank('Cuenta BBVA', 'ES91 2100 1234 16 1234567890')?.fullName,
        'CaixaBank',
      );
    });

    test('returns null when no bank matches', () {
      expect(
        detectBank('Unknown Account', 'FR1420041010050500013M02606'),
        isNull,
      );
      expect(detectBank('', null), isNull);
    });
  });
}
