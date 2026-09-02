import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';

/// Callback invoked when hardware button PTT state changes.
typedef PttStateCallback = void Function(bool isTransmitting);

/// Service managing physical hardware volume keys & helmet buttons for Push-to-Talk.
class HardwarePttService {
  HardwarePttService();

  PttStateCallback? _onPttStateChanged;
  bool _isListening = false;
  bool _isHardwareTransmitting = false;
  DateTime _lastVolumeEventTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _volumeHoldTimer;

  bool get isListening => _isListening;
  bool get isHardwareTransmitting => _isHardwareTransmitting;

  /// Keys that trigger Push-to-Talk.
  static final Set<LogicalKeyboardKey> pttTriggerKeys = {
    LogicalKeyboardKey.audioVolumeUp,
    LogicalKeyboardKey.audioVolumeDown,
    LogicalKeyboardKey.headsetHook,
    LogicalKeyboardKey.mediaPlayPause,
    LogicalKeyboardKey.mediaTrackNext,
    LogicalKeyboardKey.mediaTrackPrevious,
  };

  /// Starts listening to physical volume & headset buttons.
  void startListening(PttStateCallback onPttStateChanged) {
    if (_isListening) return;
    _onPttStateChanged = onPttStateChanged;
    _isListening = true;

    try {
      // 1. Suppress native volume popup UI while in intercom mode
      FlutterVolumeController.updateShowSystemUI(false);
    } catch (e) {
      debugPrint('[HardwarePttService] Could not suppress volume UI: $e');
    }

    // 2. Register native Flutter hardware keyboard handler (Key Down & Key Up)
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);

    // 3. Register volume change listener as a fallback for devices without raw key events
    try {
      FlutterVolumeController.addListener(_handleVolumeChange);
    } catch (e) {
      debugPrint('[HardwarePttService] Volume listener error: $e');
    }

    debugPrint('[HardwarePttService] Hardware button PTT listener active.');
  }

  /// Handles KeyDown and KeyUp events for hardware volume and headset keys.
  bool _handleKeyEvent(KeyEvent event) {
    if (!_isListening || _onPttStateChanged == null) return false;

    if (pttTriggerKeys.contains(event.logicalKey)) {
      if (event is KeyDownEvent) {
        if (!_isHardwareTransmitting) {
          _isHardwareTransmitting = true;
          _onPttStateChanged!(true);
        }
        return true; // Consume event to prevent system volume changes
      } else if (event is KeyUpEvent) {
        if (_isHardwareTransmitting) {
          _isHardwareTransmitting = false;
          _onPttStateChanged!(false);
        }
        return true; // Consume event
      } else if (event is KeyRepeatEvent) {
        // Holding the button down continuously
        return true;
      }
    }
    return false;
  }

  /// Fallback handler for devices that only dispatch stream volume changes.
  void _handleVolumeChange(double volume) {
    final now = DateTime.now();
    // Debounce rapid volume spikes
    if (now.difference(_lastVolumeEventTime).inMilliseconds < 150) return;
    _lastVolumeEventTime = now;

    // If not already transmitting from KeyDownEvent, trigger brief hold or toggle
    if (!_isHardwareTransmitting && _onPttStateChanged != null) {
      _isHardwareTransmitting = true;
      _onPttStateChanged!(true);

      _volumeHoldTimer?.cancel();
      // Auto-release after 2.5 seconds if no key-up event was caught
      _volumeHoldTimer = Timer(const Duration(milliseconds: 2500), () {
        if (_isHardwareTransmitting && _onPttStateChanged != null) {
          _isHardwareTransmitting = false;
          _onPttStateChanged!(false);
        }
      });
    } else if (_isHardwareTransmitting && _onPttStateChanged != null) {
      // Toggle off on subsequent volume press
      _volumeHoldTimer?.cancel();
      _isHardwareTransmitting = false;
      _onPttStateChanged!(false);
    }
  }

  /// Stops listening and restores native system volume UI behavior.
  void stopListening() {
    if (!_isListening) return;

    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    try {
      FlutterVolumeController.removeListener();
    } catch (_) {}

    _volumeHoldTimer?.cancel();
    _volumeHoldTimer = null;

    if (_isHardwareTransmitting && _onPttStateChanged != null) {
      _isHardwareTransmitting = false;
      _onPttStateChanged!(false);
    }

    _onPttStateChanged = null;
    _isListening = false;

    try {
      // Restore native system volume UI
      FlutterVolumeController.updateShowSystemUI(true);
    } catch (e) {
      debugPrint('[HardwarePttService] Could not restore volume UI: $e');
    }

    debugPrint('[HardwarePttService] Hardware button PTT listener stopped.');
  }

  void dispose() {
    stopListening();
  }
}

/// Riverpod provider for HardwarePttService.
final hardwarePttServiceProvider = Provider<HardwarePttService>((ref) {
  final service = HardwarePttService();
  ref.onDispose(() => service.dispose());
  return service;
});
