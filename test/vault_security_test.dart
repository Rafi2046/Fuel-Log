import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/services/vault_security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultSecurityService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isPinSet returns false when no PIN is stored', () async {
      const service = VaultSecurityService();
      final isSet = await service.isPinSet();
      expect(isSet, isFalse);
    });

    test('setPin saves PIN and verifyPin validates correctly', () async {
      const service = VaultSecurityService();
      await service.setPin('1234');

      expect(await service.isPinSet(), isTrue);
      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
      expect(await service.verifyPin('1235'), isFalse);
    });

    test('changePin updates PIN only when old PIN matches', () async {
      const service = VaultSecurityService();
      await service.setPin('1234');

      // Wrong old PIN -> fails
      final failed = await service.changePin(oldPin: '9999', newPin: '5678');
      expect(failed, isFalse);
      expect(await service.verifyPin('1234'), isTrue);

      // Correct old PIN -> succeeds
      final success = await service.changePin(oldPin: '1234', newPin: '5678');
      expect(success, isTrue);
      expect(await service.verifyPin('1234'), isFalse);
      expect(await service.verifyPin('5678'), isTrue);
    });

    test('removePin clears stored PIN', () async {
      const service = VaultSecurityService();
      await service.setPin('4321');
      expect(await service.isPinSet(), isTrue);

      await service.removePin();
      expect(await service.isPinSet(), isFalse);
    });
  });
}
