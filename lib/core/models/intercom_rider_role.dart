/// How this rider uses intercom — drives audio presets and background behavior.
enum IntercomRiderRole {
  /// Multi-bike group ride with Bluetooth helmet (default).
  groupRider,

  /// Same bike — driver with phone on mount, loudspeaker + PTT.
  sameBikeDriver,

  /// Same bike — pillion with phone in pocket + earphone, open mic.
  sameBikePillion,
}

extension IntercomRiderRoleX on IntercomRiderRole {
  String get label => switch (this) {
        IntercomRiderRole.groupRider => 'Group rider',
        IntercomRiderRole.sameBikeDriver => 'Driver',
        IntercomRiderRole.sameBikePillion => 'Pillion',
      };

  String get subtitle => switch (this) {
        IntercomRiderRole.groupRider =>
          'Multi-bike tour with Bluetooth helmet / earbuds',
        IntercomRiderRole.sameBikeDriver =>
          'Bike driver — phone in pocket with earbuds, or mount',
        IntercomRiderRole.sameBikePillion =>
          'Pillion rider — phone in pocket with earbuds',
      };

  String get iconName => switch (this) {
        IntercomRiderRole.groupRider => 'group',
        IntercomRiderRole.sameBikeDriver => 'driver',
        IntercomRiderRole.sameBikePillion => 'pillion',
      };

  bool get needsBackgroundSession => true;

  static IntercomRiderRole fromPref(String? value) {
    return IntercomRiderRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => IntercomRiderRole.groupRider,
    );
  }
}

/// Audio + mic preset applied when a rider role is selected.
class IntercomRolePreset {
  const IntercomRolePreset({
    required this.helmetAudioRouteEnabled,
    required this.loudspeakerEnabled,
    required this.windNoiseFilterEnabled,
    required this.openMic,
  });

  final bool helmetAudioRouteEnabled;
  final bool loudspeakerEnabled;
  final bool windNoiseFilterEnabled;
  final bool openMic;

  static IntercomRolePreset forRole(IntercomRiderRole role) => switch (role) {
        IntercomRiderRole.groupRider => const IntercomRolePreset(
              helmetAudioRouteEnabled: true,
              loudspeakerEnabled: false,
              windNoiseFilterEnabled: true,
              openMic: true,
            ),
        IntercomRiderRole.sameBikeDriver => const IntercomRolePreset(
              helmetAudioRouteEnabled: true,
              loudspeakerEnabled: false,
              windNoiseFilterEnabled: true,
              openMic: true,
            ),
        IntercomRiderRole.sameBikePillion => const IntercomRolePreset(
              helmetAudioRouteEnabled: true,
              loudspeakerEnabled: false,
              windNoiseFilterEnabled: true,
              openMic: true,
            ),
      };
}
