import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/data/saved_account_repository.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

CalcInput td5(int amount) => CalcInput(
  scheme: Scheme.td5,
  amount: Decimal.fromInt(amount),
  opening: DateTime(2024, 5, 1),
  rate: Decimal.parse('7.5'),
);

void main() {
  test(
    'backup restores accounts on a new phone and skips duplicates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final oldPhone = await SavedAccountRepository.load();
      await oldPhone.add('ಅಮ್ಮನ TD', td5(100000));
      await oldPhone.add('Ravi', td5(50000));
      final backup = oldPhone.exportJson();

      SharedPreferences.setMockInitialValues({});
      final newPhone = await SavedAccountRepository.load();
      expect(await newPhone.importJson(backup), 2);
      expect(
        newPhone.accounts.map((a) => a.name),
        containsAll(['ಅಮ್ಮನ TD', 'Ravi']),
      );
      expect(
        newPhone.accounts.first.result.maturityValue,
        oldPhone.accounts.first.result.maturityValue,
      );
      // Restoring the same file again adds nothing.
      expect(await newPhone.importJson(backup), 0);
      expect(newPhone.accounts, hasLength(2));
    },
  );

  test('other files are rejected', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = await SavedAccountRepository.load();
    expect(() => repo.importJson('hello'), throwsFormatException);
    expect(() => repo.importJson('{"accounts": []}'), throwsFormatException);
  });
}
