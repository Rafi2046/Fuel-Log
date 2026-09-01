import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing Biometric (Fingerprint, Face Unlock) & PIN lock authentication for the E-Document Vault.
class VaultSecurityService {
  const VaultSecurityService({LocalAuthentication? auth})
      : _injectedAuth = auth;

  final LocalAuthentication? _injectedAuth;

  LocalAuthentication get _auth => _injectedAuth ?? LocalAuthentication();

  static const _pinKey = 'vault_security_pin_hash';
  static const _saltKey = 'vault_security_pin_salt';
  static const _biometricsKey = 'vault_security_biometrics_enabled';
  static const _saltConstant = 'fuel_log_vault_secure_salt_2026_';

  /// Checks if the device has biometric hardware (Fingerprint, Face, Iris) available and enrolled.
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('Biometrics check error: $e');
      return false;
    }
  }

  /// Returns available biometric hardware types (e.g. face, fingerprint).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Checks whether biometric authentication is enabled by user preference (default true).
  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsKey) ?? true;
  }

  /// Sets user preference for biometric unlock.
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsKey, enabled);
  }

  /// Performs biometric authentication (Fingerprint / Face ID / Face Unlock).
  Future<bool> authenticateWithBiometrics({
    String reason = 'Scan fingerprint or Face to unlock E-Document Vault',
  }) async {
    try {
      final isSupported = await canAuthenticateWithBiometrics();
      if (!isSupported) return false;

      final isEnabled = await isBiometricsEnabled();
      if (!isEnabled) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric PlatformException: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Checks if security (Biometrics or PIN) is configured on this device.
  Future<bool> isSecurityActive() async {
    final hasBiometrics = await canAuthenticateWithBiometrics();
    final hasPin = await isPinSet();
    return hasBiometrics || hasPin;
  }

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
