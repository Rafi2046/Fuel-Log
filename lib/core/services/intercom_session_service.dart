import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/intercom_rider_role.dart';

typedef IntercomSessionEventHandler = void Function(IntercomSessionEvent event);

enum IntercomSessionEvent {
  pttDown,
  pttUp,
  pttToggle,
  muteToggle,
  leave,
}

/// Keeps intercom alive in the background and routes lock-screen / headset actions.
class IntercomSessionService {
  IntercomSessionService();

  static final IntercomSessionService instance = IntercomSessionService();

  static const _methodChannel = MethodChannel('com.ridelog.bd/intercom_session');
  static const _eventChannel = EventChannel('com.ridelog.bd/intercom_session_events');

  StreamSubscription<dynamic>? _eventSub;
  IntercomSessionEventHandler? _handler;
  bool _sessionActive = false;

  bool get isSessionActive => _sessionActive;

  void setEventHandler(IntercomSessionEventHandler? handler) {
    _handler = handler;
    if (handler != null) {
      _ensureEventSubscription();
    } else {
      _eventSub?.cancel();
      _eventSub = null;
    }
  }

  Future<void> startSession({
    required String tourName,
    required IntercomRiderRole role,
    required bool isTransmitting,
    required bool isMuted,
    required bool openMic,
  }) async {
    if (!Platform.isAndroid) {
      _sessionActive = true;
      return;
    }

    try {
      await _methodChannel.invokeMethod<void>('startSession', {
        'tourName': tourName,
        'role': role.name,
        'isTransmitting': isTransmitting,
        'isMuted': isMuted,
        'openMic': openMic,
      });
      _sessionActive = true;
      _ensureEventSubscription();
    } catch (e) {
      debugPrint('[IntercomSession] startSession error: $e');
    }
  }

  Future<void> updateSession({
    required String tourName,
    required IntercomRiderRole role,
    required bool isTransmitting,
    required bool isMuted,
    required bool openMic,
  }) async {
    if (!Platform.isAndroid || !_sessionActive) return;

    try {
      await _methodChannel.invokeMethod<void>('updateSession', {
        'tourName': tourName,
        'role': role.name,
        'isTransmitting': isTransmitting,
        'isMuted': isMuted,
        'openMic': openMic,
      });
    } catch (e) {
      debugPrint('[IntercomSession] updateSession error: $e');
    }
  }

  Future<void> stopSession() async {
    _sessionActive = false;
    if (!Platform.isAndroid) return;

    try {
      await _methodChannel.invokeMethod<void>('stopSession');
    } catch (e) {
      debugPrint('[IntercomSession] stopSession error: $e');
    }
  }

  void _ensureEventSubscription() {
    if (!Platform.isAndroid || _eventSub != null) return;

    _eventSub = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        final parsed = _parseEvent(event);
        if (parsed != null) {
          _handler?.call(parsed);
        }
      },
      onError: (Object error) {
        debugPrint('[IntercomSession] event stream error: $error');
      },
    );
  }

  IntercomSessionEvent? _parseEvent(dynamic raw) {
    return switch (raw) {
      'ptt_down' => IntercomSessionEvent.pttDown,
      'ptt_up' => IntercomSessionEvent.pttUp,
      'ptt_toggle' => IntercomSessionEvent.pttToggle,
      'mute_toggle' => IntercomSessionEvent.muteToggle,
      'leave' => IntercomSessionEvent.leave,
      _ => null,
    };
  }
}
