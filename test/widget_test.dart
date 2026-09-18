import 'package:account_new/models/backup_envelope.dart';
import 'package:account_new/models/tx_record.dart';
import 'package:account_new/utils/backup_codec.dart';
import 'package:account_new/utils/calculator.dart';
import 'package:account_new/utils/constants.dart';
import 'package:account_new/utils/date_x.dart';
import 'package:account_new/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calculator', () {
    test('respects operator precedence', () {
      expect(Calculator.evaluate('12+8'), 20);
      expect(Calculator.evaluate('2+3×4'), 14);
      expect(Calculator.evaluate('10-4÷2'), 8);
    });

    test('rejects incomplete or invalid input', () {
      expect(Calculator.evaluate('12+'), isNull);
      expect(Calculator.evaluate(''), isNull);
      expect(Calculator.evaluate('1÷0'), isNull);
    });

    test('converts to cents', () {
      expect(Calculator.toCents('12+8'), 2000);
      expect(Calculator.toCents('12.34'), 1234);
    });
  });

  group('Money', () {
    test('formats cents with grouping', () {
      expect(Money.centsToPlain(123456), '1,234.56');
      expect(Money.format(123456), '¥1,234.56');
    });

    test('parses user input', () {
      expect(Money.parseToCents('12.3'), 1230);
      expect(Money.parseToCents('1,200'), 120000);
      expect(Money.parseToCents('abc'), isNull);
    });
  });

  group('DateX', () {
    test('left-closed right-open range', () {
      final start = DateTime(2026, 1, 1);
      final end = DateTime(2026, 2, 1);
      expect(DateX.inRange(DateTime(2026, 1, 1), start, end), isTrue);
      expect(DateX.inRange(DateTime(2026, 1, 31), start, end), isTrue);
      expect(DateX.inRange(end, start, end), isFalse);
    });

    test('month end exclusive', () {
      expect(DateX.endOfMonthExclusive(DateTime(2026, 1, 15)),
          DateTime(2026, 2, 1));
    });
  });

  group('BackupCodec', () {
    test('round-trips an envelope', () {
      const envelope = BackupEnvelope(
        schemaVersion: 1,
        appVersion: '1.0.0',
        exportedAt: '2026-01-01T00:00:00.000',
        exportType: 'all',
        categories: [
          {'id': 1, 'name': '餐饮', 'type': 'expense'},
        ],
        transactions: [
          {'id': 1, 'type': 'expense', 'amount_cents': 1200, 'date': '2026-01-01'},
        ],
        settings: {'currency': 'CNY'},
      );
      final decoded = BackupCodec.decode(BackupCodec.encode(envelope));
      expect(decoded.categories.length, 1);
      expect(decoded.transactions.first['amount_cents'], 1200);
      expect(decoded.settings['currency'], 'CNY');
    });

    test('rejects invalid json', () {
      expect(() => BackupCodec.decode('not json'), throwsFormatException);
    });

    test('rejects newer schema versions', () {
      expect(
        () => BackupCodec.decode('{"schema_version": 99}'),
        throwsFormatException,
      );
    });

    test('formats backup file name', () {
      expect(BackupCodec.fileName(DateTime(2026, 3, 4, 5, 6, 7)),
          '记账本备份_20260304_050607.json');
    });
  });

  group('TxRecord', () {
    test('signed amount', () {
      const expense = TxRecord(
          type: TxType.expense, amountCents: 100, date: '2026-01-01', time: '08:00');
      const income = TxRecord(
          type: TxType.income, amountCents: 100, date: '2026-01-01', time: '08:00');
      expect(expense.signedAmountCents, -100);
      expect(income.signedAmountCents, 100);
    });

    test('business fingerprint', () {
      const tx = TxRecord(
        type: TxType.expense,
        amountCents: 100,
        date: '2026-01-01',
        time: '08:00',
        note: 'lunch',
      );
      expect(tx.fingerprint('餐饮'), '2026-01-01|100|expense|餐饮|lunch');
    });
  });
}
