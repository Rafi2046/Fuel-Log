/// Runtime audio processing flags for tour intercom.
class IntercomAudioSettings {
  const IntercomAudioSettings({
    this.windNoiseFilterEnabled = true,
    this.helmetAudioRouteEnabled = true,
    this.meshBridgeEnabled = true,
    this.fecRecoveryEnabled = true,
  });

  final bool windNoiseFilterEnabled;
  final bool helmetAudioRouteEnabled;
  final bool meshBridgeEnabled;
  final bool fecRecoveryEnabled;

  IntercomAudioSettings copyWith({
    bool? windNoiseFilterEnabled,
    bool? helmetAudioRouteEnabled,
    bool? meshBridgeEnabled,
    bool? fecRecoveryEnabled,
  }) {
    return IntercomAudioSettings(
      windNoiseFilterEnabled:
          windNoiseFilterEnabled ?? this.windNoiseFilterEnabled,
      helmetAudioRouteEnabled:
          helmetAudioRouteEnabled ?? this.helmetAudioRouteEnabled,
      meshBridgeEnabled: meshBridgeEnabled ?? this.meshBridgeEnabled,
      fecRecoveryEnabled: fecRecoveryEnabled ?? this.fecRecoveryEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IntercomAudioSettings &&
        other.windNoiseFilterEnabled == windNoiseFilterEnabled &&
        other.helmetAudioRouteEnabled == helmetAudioRouteEnabled &&
        other.meshBridgeEnabled == meshBridgeEnabled &&
        other.fecRecoveryEnabled == fecRecoveryEnabled;
  }

  @override
  int get hashCode => Object.hash(
        windNoiseFilterEnabled,
        helmetAudioRouteEnabled,
        meshBridgeEnabled,
        fecRecoveryEnabled,
      );
}
