/// Runtime audio processing flags for tour intercom.
class IntercomAudioSettings {
  const IntercomAudioSettings({
    this.windNoiseFilterEnabled = true,
    this.helmetAudioRouteEnabled = true,
    this.meshBridgeEnabled = true,
    this.fecRecoveryEnabled = true,
    this.loudspeakerEnabled = false,
    this.coRiderModeEnabled = false,
  });

  final bool windNoiseFilterEnabled;
  final bool helmetAudioRouteEnabled;
  final bool meshBridgeEnabled;
  final bool fecRecoveryEnabled;
  final bool loudspeakerEnabled;
  final bool coRiderModeEnabled;

  IntercomAudioSettings copyWith({
    bool? windNoiseFilterEnabled,
    bool? helmetAudioRouteEnabled,
    bool? meshBridgeEnabled,
    bool? fecRecoveryEnabled,
    bool? loudspeakerEnabled,
    bool? coRiderModeEnabled,
  }) {
    return IntercomAudioSettings(
      windNoiseFilterEnabled:
          windNoiseFilterEnabled ?? this.windNoiseFilterEnabled,
      helmetAudioRouteEnabled:
          helmetAudioRouteEnabled ?? this.helmetAudioRouteEnabled,
      meshBridgeEnabled: meshBridgeEnabled ?? this.meshBridgeEnabled,
      fecRecoveryEnabled: fecRecoveryEnabled ?? this.fecRecoveryEnabled,
      loudspeakerEnabled: loudspeakerEnabled ?? this.loudspeakerEnabled,
      coRiderModeEnabled: coRiderModeEnabled ?? this.coRiderModeEnabled,
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
        other.coRiderModeEnabled == coRiderModeEnabled;
  }

  @override
  int get hashCode => Object.hash(
        windNoiseFilterEnabled,
        helmetAudioRouteEnabled,
        meshBridgeEnabled,
        fecRecoveryEnabled,
        loudspeakerEnabled,
        coRiderModeEnabled,
      );
}
