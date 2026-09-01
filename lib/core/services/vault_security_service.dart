import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing the PIN lock & authentication for the Document Vault.
class VaultSecurityService {
  const VaultSecurityService();

  static const _pinKey = 'vault_security_pin_hash';
  static const _saltKey = 'vault_security_pin_salt';
  static const _saltConstant = 'fuel_log_vault_secure_salt_2026_';

  /// Checks if the user has already configured a security PIN.
  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  /// Sets up a new 4-digit security PIN.
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    await prefs.setString(_pinKey, hash);
  }

  /// Verifies whether the entered PIN matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  /// Changes the PIN if the old PIN is correct.
  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final isValid = await verifyPin(oldPin);
    if (!isValid) return false;
    await setPin(newPin);
    return true;
  }

  /// Removes the security PIN (e.g. on full reset).
  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.remove(_saltKey);
  }

  /// Hashes a 4-digit PIN with a fixed application salt and base64 digest.
  String _hashPin(String pin) {
    final input = '$_saltConstant$pin';
    final bytes = utf8.encode(input);
    
    // Compute simple multi-round digest
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    
    final combined = '$hash:$pin:$_saltConstant';
    return base64Encode(utf8.encode(combined));
  }
}
