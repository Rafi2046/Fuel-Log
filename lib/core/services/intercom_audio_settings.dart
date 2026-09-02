import '../models/intercom_rider_role.dart';

/// Runtime audio processing flags for tour intercom.
class IntercomAudioSettings {
  const IntercomAudioSettings({
    this.windNoiseFilterEnabled = true,
    this.helmetAudioRouteEnabled = true,
    this.meshBridgeEnabled = true,
    this.fecRecoveryEnabled = true,
    this.loudspeakerEnabled = false,
    this.riderRole = IntercomRiderRole.groupRider,
  });

  final bool windNoiseFilterEnabled;
  final bool helmetAudioRouteEnabled;
  final bool meshBridgeEnabled;
  final bool fecRecoveryEnabled;
  final bool loudspeakerEnabled;
  final IntercomRiderRole riderRole;

  bool get coRiderModeEnabled =>
      riderRole == IntercomRiderRole.sameBikeDriver ||
      riderRole == IntercomRiderRole.sameBikePillion;

  bool get pillionModeEnabled => riderRole == IntercomRiderRole.sameBikePillion;

  IntercomAudioSettings copyWith({
    bool? windNoiseFilterEnabled,
    bool? helmetAudioRouteEnabled,
    bool? meshBridgeEnabled,
    bool? fecRecoveryEnabled,
    bool? loudspeakerEnabled,
    IntercomRiderRole? riderRole,
  }) {
    return IntercomAudioSettings(
      windNoiseFilterEnabled:
          windNoiseFilterEnabled ?? this.windNoiseFilterEnabled,
      helmetAudioRouteEnabled:
          helmetAudioRouteEnabled ?? this.helmetAudioRouteEnabled,
      meshBridgeEnabled: meshBridgeEnabled ?? this.meshBridgeEnabled,
      fecRecoveryEnabled: fecRecoveryEnabled ?? this.fecRecoveryEnabled,
      loudspeakerEnabled: loudspeakerEnabled ?? this.loudspeakerEnabled,
      riderRole: riderRole ?? this.riderRole,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IntercomAudioSettings &&
        other.windNoiseFilterEnabled == windNoiseFilterEnabled &&
        other.helmetAudioRouteEnabled == helmetAudioRouteEnabled &&
        other.meshBridgeEnabled == meshBridgeEnabled &&
        other.fecRecoveryEnabled == fecRecoveryEnabled &&
        other.loudspeakerEnabled == loudspeakerEnabled &&
        other.riderRole == riderRole;
  }

  @override
  int get hashCode => Object.hash(
        windNoiseFilterEnabled,
        helmetAudioRouteEnabled,
        meshBridgeEnabled,
        fecRecoveryEnabled,
        loudspeakerEnabled,
        riderRole,
      );
}
