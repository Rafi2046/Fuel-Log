import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../viewmodels/document_vault_viewmodel.dart';

enum VaultPinMode { unlock, setup, change }

/// Dedicated PIN & Biometric Screen for E-Document Vault (Unlock, Setup, Change PIN)
class VaultPinScreen extends ConsumerStatefulWidget {
  const VaultPinScreen({
    super.key,
    required this.mode,
    required this.onSuccess,
    this.onCancel,
  });

  final VaultPinMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  static Future<bool?> open(
    BuildContext context, {
    required VaultPinMode mode,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VaultPinScreen(
          mode: mode,
          onSuccess: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  @override
  ConsumerState<VaultPinScreen> createState() => _VaultPinScreenState();
}

class _VaultPinScreenState extends ConsumerState<VaultPinScreen> {
  String _enteredPin = '';
  String? _firstEnteredPin; // for setup / change confirm step
  String? _verifiedOldPin; // for change step
  String? _errorMessage;
  bool _isConfirmStep = false;
  bool _isVerifyingOldPin = false;

  bool _isBiometricsAvailable = false;
  bool _isAuthenticatingBiometrics = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == VaultPinMode.change) {
      _isVerifyingOldPin = true;
    }
    _checkAndPromptBiometrics();
  }

  Future<void> _checkAndPromptBiometrics() async {
    if (widget.mode != VaultPinMode.unlock) return;

    final security = ref.read(vaultSecurityServiceProvider);
    final isAvailable = await security.canAuthenticateWithBiometrics();
    final isEnabled = await security.isBiometricsEnabled();

    if (mounted) {
      setState(() {
        _isBiometricsAvailable = isAvailable && isEnabled;
      });
    }

    if (isAvailable && isEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometricAuth();
      });
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticatingBiometrics || !mounted) return;

    setState(() => _isAuthenticatingBiometrics = true);
    final security = ref.read(vaultSecurityServiceProvider);

    final success = await security.authenticateWithBiometrics(
      reason: 'Scan fingerprint or Face to unlock E-Document Vault',
    );

    if (mounted) {
      setState(() => _isAuthenticatingBiometrics = false);
      if (success) {
        ref.read(isVaultUnlockedProvider.notifier).state = true;
        widget.onSuccess();
      }
    }
  }

  void _onKeyPress(String key) {
    if (_enteredPin.length >= 4) return;

    setState(() {
      _errorMessage = null;
      _enteredPin += key;
    });

    if (_enteredPin.length == 4) {
      _handlePinComplete(_enteredPin);
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _handlePinComplete(String pin) async {
    final controller = ref.read(documentVaultControllerProvider);

    if (widget.mode == VaultPinMode.unlock) {
      final isValid = await controller.unlockWithPin(pin);
      if (!mounted) return;
      if (isValid) {
        widget.onSuccess();
      } else {
        setState(() {
          _enteredPin = '';
          _errorMessage = 'documentVaultWrongPin'.tr();
        });
      }
      return;
    }

    if (widget.mode == VaultPinMode.setup) {
      if (!_isConfirmStep) {
        // First step of setup
        setState(() {
          _firstEnteredPin = pin;
          _enteredPin = '';
          _isConfirmStep = true;
        });
      } else {
        // Confirm step
        if (pin == _firstEnteredPin) {
          await controller.setupPin(pin);
          if (!mounted) return;
          widget.onSuccess();
        } else {
          setState(() {
            _enteredPin = '';
            _firstEnteredPin = null;
            _isConfirmStep = false;
            _errorMessage = 'documentVaultPinMismatch'.tr();
          });
        }
      }
      return;
    }

    if (widget.mode == VaultPinMode.change) {
      if (_isVerifyingOldPin) {
        final security = ref.read(vaultSecurityServiceProvider);
        final isValid = await security.verifyPin(pin);
        if (!mounted) return;
        if (isValid) {
          setState(() {
            _verifiedOldPin = pin;
            _enteredPin = '';
            _isVerifyingOldPin = false;
            _isConfirmStep = false;
          });
        } else {
          setState(() {
            _enteredPin = '';
            _errorMessage = 'documentVaultWrongPin'.tr();
          });
        }
      } else if (!_isConfirmStep) {
        setState(() {
          _firstEnteredPin = pin;
          _enteredPin = '';
          _isConfirmStep = true;
        });
      } else {
        if (pin == _firstEnteredPin && _verifiedOldPin != null) {
          final success = await controller.changePin(
            oldPin: _verifiedOldPin!,
            newPin: pin,
          );
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('documentVaultPinUpdated'.tr()),
                backgroundColor: AppColors.primary,
              ),
            );
            widget.onSuccess();
          }
        } else {
          setState(() {
            _enteredPin = '';
            _firstEnteredPin = null;
            _isConfirmStep = false;
            _errorMessage = 'documentVaultPinMismatch'.tr();
          });
        }
      }
    }
  }

  String _getHeaderTitle() {
    if (widget.mode == VaultPinMode.unlock) {
      return 'documentVaultLocked'.tr();
    }
    if (widget.mode == VaultPinMode.setup) {
      return _isConfirmStep
          ? 'documentVaultConfirmPin'.tr()
          : 'documentVaultSetupPin'.tr();
    }
    if (widget.mode == VaultPinMode.change) {
      if (_isVerifyingOldPin) {
        return 'documentVaultOldPin'.tr();
      }
      return _isConfirmStep
          ? 'documentVaultConfirmPin'.tr()
          : 'documentVaultNewPin'.tr();
    }
    return 'documentVaultTitle'.tr();
  }

  String _getHeaderSubtitle() {
    if (widget.mode == VaultPinMode.unlock) {
      return _isBiometricsAvailable
          ? 'Use Face, Fingerprint or enter 4-digit PIN to unlock'
          : 'documentVaultEnterPin'.tr();
    }
    if (widget.mode == VaultPinMode.setup) {
      return _isConfirmStep
          ? 'documentVaultConfirmPinSubtitle'.tr()
          : 'documentVaultSetupPinSubtitle'.tr();
    }
    if (widget.mode == VaultPinMode.change) {
      if (_isVerifyingOldPin) {
        return 'documentVaultEnterPin'.tr();
      }
      return _isConfirmStep
          ? 'documentVaultConfirmPinSubtitle'.tr()
          : 'documentVaultSetupPinSubtitle'.tr();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.onCancel != null
            ? IconButton(
                icon: Icon(LucideIcons.x, color: AppColors.textTertiary),
                onPressed: widget.onCancel,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Lock Icon with subtle glow
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                LucideIcons.shieldCheck,
                size: 32,
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Title & Subtitle
            Text(
              _getHeaderTitle(),
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _getHeaderSubtitle(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // 4 PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (_errorMessage != null
                              ? Color(0xFFEF4444)
                              : Color(0xFF10B981))
                        : AppColors.hairline,
                    border: Border.all(
                      color: isFilled
                          ? (_errorMessage != null
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981))
                          : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const Spacer(flex: 2),

            // Numeric Keypad with Biometric Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Biometric Action Button (Fingerprint / Face)
                      if (_isBiometricsAvailable &&
                          widget.mode == VaultPinMode.unlock)
                        _buildBiometricButton()
                      else
                        const SizedBox(width: 72, height: 72),
                      _buildKeyButton('0'),
                      _buildActionButton(
                        icon: LucideIcons.delete,
                        onTap: _onBackspace,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map(_buildKeyButton).toList(),
    );
  }

  Widget _buildKeyButton(String key) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(36),
        splashColor: Color(0xFF3B82F6).withValues(alpha: 0.2),
        highlightColor: AppColors.hairline,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.appBar,
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            key,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _triggerBiometricAuth,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.fingerprint,
              size: 28,
              color: Color(0xFF34D399),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(icon, size: 22, color: AppColors.textTertiary),
          ),
        ),
      ),
    );
  }
}
