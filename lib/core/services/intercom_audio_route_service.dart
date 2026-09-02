import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Routes intercom playback to the loudspeaker on Android (hands-free riding).
class IntercomAudioRouteService {
  IntercomAudioRouteService._();
  static final IntercomAudioRouteService instance = IntercomAudioRouteService._();

  static const _channel = MethodChannel('com.ridelog.bd/intercom_audio');

  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSpeakerphoneOn', {
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('[IntercomAudioRoute] Speakerphone error: $e');
    }
  }
}
