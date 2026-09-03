import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/intercom_rider_role.dart';
import '../core/services/hardware_ptt_service.dart';
import '../core/services/intercom_audio_settings.dart';
import '../core/services/intercom_session_service.dart';
import '../core/services/nearby_audio_transport.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Member model
// ─────────────────────────────────────────────────────────────────────────────

class IntercomMember {
  const IntercomMember({
    required this.id,
    required this.name,
    required this.initials,
    this.isCurrentUser = false,
    this.isSpeaking = false,
    this.isOnline = true,
    this.batteryPercent = 85,
    this.latencyMs = 12,
  });

  final String id;
  final String name;
  final String initials;
  final bool isCurrentUser;
  final bool isSpeaking;
  final bool isOnline;
  final int batteryPercent;
  final int latencyMs;

  IntercomMember copyWith({
    bool? isSpeaking,
    bool? isOnline,
    int? batteryPercent,
    int? latencyMs,
  }) {
    return IntercomMember(
      id: id,
      name: name,
      initials: initials,
      isCurrentUser: isCurrentUser,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isOnline: isOnline ?? this.isOnline,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }

  factory IntercomMember.fromEndpoint(String endpointId, String name) {
    final cleanName = name.trim();
    final initials = cleanName.length >= 2
        ? cleanName.substring(0, 2).toUpperCase()
        : cleanName.isNotEmpty
            ? cleanName.substring(0, 1).toUpperCase()
            : 'RD';

    return IntercomMember(
      id: endpointId,
      name: name,
      initials: initials,
      isCurrentUser: false,
      isOnline: true,
      batteryPercent: 88,
      latencyMs: 8,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

enum IntercomMode { idle, hosting, joining }

class IntercomState {
  const IntercomState({
    this.isTransmitting = false,
    this.isConnecting = false,
    this.isConnected = false,
    this.errorMessage,
    this.isWindNoiseCancellationEnabled = true,
    this.isHelmetAudioRouteEnabled = true,
    this.isMeshBridgeEnabled = true,
    this.isFecRecoveryEnabled = true,
    this.isLoudspeakerEnabled = false,
    this.riderRole = IntercomRiderRole.groupRider,
    this.isBackgroundSessionActive = false,
    this.isMuted = false,
    this.isOpenMic = true,
    this.tourName = 'My Tour',
    this.channelCode = '',
    this.joinCode,
    this.isHost = false,
    this.mode = IntercomMode.idle,
    this.members = const [
      IntercomMember(
        id: 'local',
        name: 'You',
        initials: 'YOU',
        isCurrentUser: true,
        isOnline: true,
        batteryPercent: 92,
      ),
    ],
    this.lastTourCode,
    this.lastTourName,
    this.lastTourIsHost = false,
    this.transmissionSeconds = 0,
    this.audioOutputVolume = 0.85,
  });

  final bool isTransmitting;
  final bool isConnecting;
  final bool isConnected;
  final String? errorMessage;
  final bool isWindNoiseCancellationEnabled;
  final bool isHelmetAudioRouteEnabled;
  final bool isMeshBridgeEnabled;
  final bool isFecRecoveryEnabled;
  final bool isLoudspeakerEnabled;
  final IntercomRiderRole riderRole;
  final bool isBackgroundSessionActive;
  final bool isMuted;
  final bool isOpenMic;
  final String tourName;
  final String channelCode;
  final String? joinCode;
  final bool isHost;
  final IntercomMode mode;
  final List<IntercomMember> members;

  // Persistent Rejoin Session Fields (WhatsApp/Messenger style)
  final String? lastTourCode;
  final String? lastTourName;
  final bool lastTourIsHost;

  final int transmissionSeconds;
  final double audioOutputVolume;

  int get onlineCount => members.where((m) => m.isOnline).length;
  bool get hasRecentTour => lastTourCode != null && lastTourCode!.isNotEmpty;
  bool get isCoRiderModeEnabled => riderRole != IntercomRiderRole.groupRider;
  bool get isPillionMode => riderRole == IntercomRiderRole.sameBikePillion;
  bool get isDriverMode => riderRole == IntercomRiderRole.sameBikeDriver;

  IntercomState copyWith({
    bool? isTransmitting,
    bool? isConnecting,
    bool? isConnected,
    String? errorMessage,
    bool? isWindNoiseCancellationEnabled,
    bool? isHelmetAudioRouteEnabled,
    bool? isMeshBridgeEnabled,
    bool? isFecRecoveryEnabled,
    bool? isLoudspeakerEnabled,
    IntercomRiderRole? riderRole,
    bool? isBackgroundSessionActive,
    bool? isMuted,
    bool? isOpenMic,
    String? tourName,
    String? channelCode,
    String? joinCode,
    bool? isHost,
    IntercomMode? mode,
    List<IntercomMember>? members,
    String? lastTourCode,
    String? lastTourName,
    bool? lastTourIsHost,
    bool clearRecentTour = false,
    int? transmissionSeconds,
    double? audioOutputVolume,
  }) {
    return IntercomState(
      isTransmitting: isTransmitting ?? this.isTransmitting,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage,
      isWindNoiseCancellationEnabled:
          isWindNoiseCancellationEnabled ?? this.isWindNoiseCancellationEnabled,
      isHelmetAudioRouteEnabled:
          isHelmetAudioRouteEnabled ?? this.isHelmetAudioRouteEnabled,
      isMeshBridgeEnabled: isMeshBridgeEnabled ?? this.isMeshBridgeEnabled,
      isFecRecoveryEnabled: isFecRecoveryEnabled ?? this.isFecRecoveryEnabled,
      isLoudspeakerEnabled: isLoudspeakerEnabled ?? this.isLoudspeakerEnabled,
      riderRole: riderRole ?? this.riderRole,
      isBackgroundSessionActive:
          isBackgroundSessionActive ?? this.isBackgroundSessionActive,
      isMuted: isMuted ?? this.isMuted,
      isOpenMic: isOpenMic ?? this.isOpenMic,
      tourName: tourName ?? this.tourName,
      channelCode: channelCode ?? this.channelCode,
      joinCode: joinCode ?? this.joinCode,
      isHost: isHost ?? this.isHost,
      mode: mode ?? this.mode,
      members: members ?? this.members,
      lastTourCode: clearRecentTour ? null : (lastTourCode ?? this.lastTourCode),
      lastTourName: clearRecentTour ? null : (lastTourName ?? this.lastTourName),
      lastTourIsHost: clearRecentTour ? false : (lastTourIsHost ?? this.lastTourIsHost),
      transmissionSeconds: transmissionSeconds ?? this.transmissionSeconds,
      audioOutputVolume: audioOutputVolume ?? this.audioOutputVolume,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────

class IntercomViewModel extends StateNotifier<IntercomState> {
  IntercomViewModel([
    HardwarePttService? hardwarePttService,
    NearbyAudioTransport? transport,
    IntercomSessionService? sessionService,
  ])  : _hardwarePttService = hardwarePttService ?? HardwarePttService(),
        _transport = transport ?? NearbyAudioTransport.instance,
        _sessionService = sessionService ?? IntercomSessionService.instance,
        super(const IntercomState()) {
    _loadRecentTourSession();
    _loadAudioPreferences();
    _sessionService.setEventHandler(_onSessionEvent);
  }

  final HardwarePttService _hardwarePttService;
  final NearbyAudioTransport _transport;
  final IntercomSessionService _sessionService;

  StreamSubscription<Set<String>>? _connectionSub;

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _prefTourCode = 'intercom_last_tour_code';
  static const _prefTourName = 'intercom_last_tour_name';
  static const _prefTourIsHost = 'intercom_last_tour_is_host';
  static const _prefWindNoise = 'intercom_wind_noise_enabled';
  static const _prefHelmetAudio = 'intercom_helmet_audio_enabled';
  static const _prefMeshBridge = 'intercom_mesh_bridge_enabled';
  static const _prefFecRecovery = 'intercom_fec_recovery_enabled';
  static const _prefLoudspeaker = 'intercom_loudspeaker_enabled';
  static const _prefRiderRole = 'intercom_rider_role';

  /// Generates a cryptographically random 6-character uppercase join code.
  static String generateJoinCode() {
    final rand = Random.secure();
    return List.generate(6, (_) => _codeChars[rand.nextInt(_codeChars.length)]).join();
  }

  // ── Persistent Session Helpers ────────────────────────────────────────────

  Future<void> _loadRecentTourSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefTourCode);
      final name = prefs.getString(_prefTourName);
      final isHost = prefs.getBool(_prefTourIsHost) ?? false;

      if (code != null && code.isNotEmpty) {
        state = state.copyWith(
          lastTourCode: code,
          lastTourName: name ?? 'Recent Tour',
          lastTourIsHost: isHost,
        );
      }
    } catch (_) {}
  }

  Future<void> _loadAudioPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        isWindNoiseCancellationEnabled:
            prefs.getBool(_prefWindNoise) ?? true,
        isHelmetAudioRouteEnabled: prefs.getBool(_prefHelmetAudio) ?? true,
        isMeshBridgeEnabled: prefs.getBool(_prefMeshBridge) ?? true,
        isFecRecoveryEnabled: prefs.getBool(_prefFecRecovery) ?? true,
        isLoudspeakerEnabled: prefs.getBool(_prefLoudspeaker) ?? false,
        riderRole: _loadRiderRole(prefs),
      );
      await _syncAudioSettingsToTransport();
    } catch (_) {}
  }

  Future<void> _saveAudioPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        _prefWindNoise,
        state.isWindNoiseCancellationEnabled,
      );
      await prefs.setBool(
        _prefHelmetAudio,
        state.isHelmetAudioRouteEnabled,
      );
      await prefs.setBool(_prefMeshBridge, state.isMeshBridgeEnabled);
      await prefs.setBool(_prefFecRecovery, state.isFecRecoveryEnabled);
      await prefs.setBool(_prefLoudspeaker, state.isLoudspeakerEnabled);
      await prefs.setString(_prefRiderRole, state.riderRole.name);
    } catch (_) {}
  }

  IntercomRiderRole _loadRiderRole(SharedPreferences prefs) {
    final saved = prefs.getString(_prefRiderRole);
    if (saved != null) {
      return IntercomRiderRoleX.fromPref(saved);
    }
    final legacyCoRider = prefs.getBool('intercom_co_rider_mode_enabled') ?? false;
    return legacyCoRider
        ? IntercomRiderRole.sameBikeDriver
        : IntercomRiderRole.groupRider;
  }

  IntercomAudioSettings get _currentAudioSettings => IntercomAudioSettings(
        windNoiseFilterEnabled: state.isWindNoiseCancellationEnabled,
        helmetAudioRouteEnabled: state.isHelmetAudioRouteEnabled,
        meshBridgeEnabled: state.isMeshBridgeEnabled,
        fecRecoveryEnabled: state.isFecRecoveryEnabled,
        loudspeakerEnabled: state.isLoudspeakerEnabled,
        riderRole: state.riderRole,
      );

  Future<void> _syncAudioSettingsToTransport() {
    return _transport.updateAudioSettings(_currentAudioSettings);
  }

  Future<void> _syncBackgroundSession() async {
    if (!state.isConnected) return;
    await _sessionService.updateSession(
      tourName: state.tourName,
      role: state.riderRole,
      isTransmitting: state.isTransmitting,
      isMuted: state.isMuted,
      openMic: state.isOpenMic,
    );
    state = state.copyWith(isBackgroundSessionActive: _sessionService.isSessionActive);
  }

  Future<void> _startBackgroundSession() async {
    await _sessionService.startSession(
      tourName: state.tourName,
      role: state.riderRole,
      isTransmitting: state.isTransmitting,
      isMuted: state.isMuted,
      openMic: state.isOpenMic,
    );
    state = state.copyWith(isBackgroundSessionActive: _sessionService.isSessionActive);
  }

  Future<void> _stopBackgroundSession() async {
    await _sessionService.stopSession();
    state = state.copyWith(isBackgroundSessionActive: false);
  }

  void _onSessionEvent(IntercomSessionEvent event) {
    switch (event) {
      case IntercomSessionEvent.pttDown:
        if (!state.isOpenMic && !state.isMuted) {
          unawaited(setTransmitting(true));
        }
      case IntercomSessionEvent.pttUp:
        if (!state.isOpenMic) {
          unawaited(setTransmitting(false));
        }
      case IntercomSessionEvent.pttToggle:
        if (!state.isOpenMic && !state.isMuted) {
          unawaited(setTransmitting(!state.isTransmitting));
        }
      case IntercomSessionEvent.muteToggle:
        unawaited(toggleMute());
      case IntercomSessionEvent.leave:
        unawaited(leaveIntercom());
    }
  }

  Future<void> onAppLifecycleChanged(AppLifecycleState lifecycle) async {
    if (!state.isConnected) return;
    if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.inactive) {
      await _syncBackgroundSession();
    }
  }

  Future<void> setRiderRole(IntercomRiderRole role) async {
    HapticFeedback.selectionClick();
    final preset = IntercomRolePreset.forRole(role);
    state = state.copyWith(
      riderRole: role,
      isHelmetAudioRouteEnabled: preset.helmetAudioRouteEnabled,
      isLoudspeakerEnabled: preset.loudspeakerEnabled,
      isWindNoiseCancellationEnabled: preset.windNoiseFilterEnabled,
      isOpenMic: preset.openMic,
    );

    if (!preset.openMic && state.isTransmitting) {
      await setTransmitting(false);
    } else if (preset.openMic && state.isConnected && !state.isMuted) {
      await setTransmitting(true);
    }

    await _syncAudioSettingsToTransport();
    await _syncBackgroundSession();
    await _saveAudioPreferences();
  }

  Future<void> _saveRecentTourSession({
    required String tourCode,
    required String tourName,
    required bool isHost,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefTourCode, tourCode);
      await prefs.setString(_prefTourName, tourName);
      await prefs.setBool(_prefTourIsHost, isHost);
    } catch (_) {}
  }

  Future<void> clearRecentTourSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefTourCode);
      await prefs.remove(_prefTourName);
      await prefs.remove(_prefTourIsHost);
    } catch (_) {}
    state = state.copyWith(clearRecentTour: true);
  }

  // ── Lobby helpers ─────────────────────────────────────────────────────────

  void setTourCodeAndName({required String tourName, required String joinCode}) {
    state = state.copyWith(
      tourName: tourName,
      joinCode: joinCode,
      channelCode: joinCode,
      isHost: true,
      lastTourCode: joinCode,
      lastTourName: tourName,
      lastTourIsHost: true,
    );
  }

  // ── HOST: Create Tour ─────────────────────────────────────────────────────

  Future<void> createTour({required String tourName, String? preGeneratedCode}) async {
    final code = preGeneratedCode ?? generateJoinCode();
    state = state.copyWith(
      tourName: tourName,
      joinCode: code,
      channelCode: code,
      isHost: true,
      isConnecting: true,
      isConnected: false,
      mode: IntercomMode.hosting,
      lastTourCode: code,
      lastTourName: tourName,
      lastTourIsHost: true,
      errorMessage: null,
    );

    await _saveRecentTourSession(
      tourCode: code,
      tourName: tourName,
      isHost: true,
    );

    await _syncAudioSettingsToTransport();

    try {
      _connectionSub?.cancel();
      _connectionSub = _transport.connectionChanges.listen(_onConnectionsChanged);

      await _transport.startHosting(
        userName: 'Host',
        tourCode: code,
      );

      state = state.copyWith(isConnecting: false, isConnected: true);

      _hardwarePttService.startListening(setTransmitting);
      await _startBackgroundSession();

      if (state.isOpenMic && !state.isMuted) {
        await setTransmitting(true);
      }

      debugPrint('[IntercomVM] Tour "$tourName" hosted with Nearby mesh (Code: $code)');
    } catch (e) {
      debugPrint('[IntercomVM] createTour error: $e');
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: 'Failed to start tour: $e',
      );
    }
  }

  // ── RIDER: Join with Code ─────────────────────────────────────────────────

  Future<void> joinByCode(String code, [String? customTourName]) async {
    final cleanCode = code.trim().toUpperCase();
    final name = customTourName ?? 'Tour $cleanCode';

    state = state.copyWith(
      isConnecting: true,
      isConnected: false,
      tourName: name,
      joinCode: cleanCode,
      channelCode: cleanCode,
      isHost: false,
      lastTourCode: cleanCode,
      lastTourName: name,
      lastTourIsHost: false,
      errorMessage: null,
    );

    await _saveRecentTourSession(
      tourCode: cleanCode,
      tourName: name,
      isHost: false,
    );

    await _syncAudioSettingsToTransport();

    try {
      _connectionSub?.cancel();
      _connectionSub = _transport.connectionChanges.listen(_onConnectionsChanged);

      await _transport.startJoining(
        userName: 'Rider',
        tourCode: cleanCode,
      );

      state = state.copyWith(isConnecting: false, isConnected: true);

      _hardwarePttService.startListening(setTransmitting);
      await _startBackgroundSession();

      if (state.isOpenMic && !state.isMuted) {
        await setTransmitting(true);
      }

      debugPrint('[IntercomVM] Rider joined Nearby mesh for tour $cleanCode');
    } catch (e) {
      debugPrint('[IntercomVM] joinByCode error: $e');
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: 'Failed to join: $e',
      );
    }
  }

  // ── 1-CLICK REJOIN RECENT TOUR (WhatsApp / Messenger Voice Call Style) ──────

  Future<void> rejoinRecentTour() async {
    if (!state.hasRecentTour) return;
    HapticFeedback.heavyImpact();

    final code = state.lastTourCode!;
    final name = state.lastTourName ?? 'Tour $code';
    final wasHost = state.lastTourIsHost;

    if (wasHost) {
      await createTour(tourName: name, preGeneratedCode: code);
    } else {
      await joinByCode(code, name);
    }
  }

  // ── Connection update ─────────────────────────────────────────────────────

  void _onConnectionsChanged(Set<String> endpointIds) {
    final localMember = state.members.firstWhere(
      (m) => m.isCurrentUser,
      orElse: () => const IntercomMember(
        id: 'local',
        name: 'You',
        initials: 'YOU',
        isCurrentUser: true,
        isOnline: true,
        batteryPercent: 92,
      ),
    );

    final remoteMembers = endpointIds.map((id) {
      final name = _transport.endpointNames[id] ?? 'Rider';
      return IntercomMember.fromEndpoint(id, name);
    }).toList();

    final allMembers = [localMember, ...remoteMembers];

    state = state.copyWith(
      members: allMembers,
      isConnected: true,
      isConnecting: false,
    );

    debugPrint('[IntercomVM] 🏍️ Active Riders Updated: ${allMembers.length} riders online!');

    if (state.isOpenMic && !state.isMuted && !state.isTransmitting) {
      setTransmitting(true);
    }
  }

  // ── PTT / Hands-Free Transmission ─────────────────────────────────────────

  Future<void> setTransmitting(bool isTransmitting) async {
    if (state.isTransmitting == isTransmitting) return;
    if (state.isMuted && isTransmitting) return;

    if (isTransmitting) {
      HapticFeedback.heavyImpact();
      await _transport.startTransmitting();
    } else {
      HapticFeedback.lightImpact();
      await _transport.stopTransmitting();
    }

    state = state.copyWith(isTransmitting: isTransmitting);
    await _syncBackgroundSession();
    debugPrint('[IntercomVM] Audio Transmission: ${isTransmitting ? "TRANSMITTING (LIVE)" : "MUTED"}');
  }

  Future<void> toggleMute() async {
    HapticFeedback.mediumImpact();
    final newMute = !state.isMuted;
    if (newMute) {
      await _transport.stopTransmitting();
      state = state.copyWith(isMuted: true, isTransmitting: false);
    } else {
      state = state.copyWith(isMuted: false);
      if (state.isOpenMic && state.isConnected) {
        await _transport.startTransmitting();
        state = state.copyWith(isTransmitting: true);
      }
    }
    await _syncBackgroundSession();
  }

  Future<void> toggleOpenMicMode([bool? value]) async {
    HapticFeedback.mediumImpact();
    final newMode = value ?? !state.isOpenMic;
    state = state.copyWith(isOpenMic: newMode);
    if (newMode && state.isConnected && !state.isMuted) {
      await setTransmitting(true);
    } else if (!newMode && state.isTransmitting) {
      await setTransmitting(false);
    }
    await _syncBackgroundSession();
  }

  // ── Smart toggles ─────────────────────────────────────────────────────────

  Future<void> toggleWindNoiseCancellation(bool? value) async {
    HapticFeedback.selectionClick();
    final enabled = value ?? !state.isWindNoiseCancellationEnabled;
    state = state.copyWith(isWindNoiseCancellationEnabled: enabled);
    await _syncAudioSettingsToTransport();
    await _saveAudioPreferences();
  }

  Future<void> toggleHelmetAudioRoute(bool? value) async {
    HapticFeedback.selectionClick();
    final enabled = value ?? !state.isHelmetAudioRouteEnabled;
    state = state.copyWith(
      isHelmetAudioRouteEnabled: enabled,
      isLoudspeakerEnabled: enabled ? false : state.isLoudspeakerEnabled,
    );
    await _syncAudioSettingsToTransport();
    await _syncBackgroundSession();
    await _saveAudioPreferences();
  }

  Future<void> toggleLoudspeaker(bool? value) async {
    HapticFeedback.selectionClick();
    final enabled = value ?? !state.isLoudspeakerEnabled;
    state = state.copyWith(
      isLoudspeakerEnabled: enabled,
      isHelmetAudioRouteEnabled: enabled ? false : state.isHelmetAudioRouteEnabled,
    );
    await _syncAudioSettingsToTransport();
    await _syncBackgroundSession();
    await _saveAudioPreferences();
  }

  Future<void> toggleCoRiderMode(bool? value) async {
    final enabled = value ?? !state.isCoRiderModeEnabled;
    await setRiderRole(
      enabled
          ? IntercomRiderRole.sameBikeDriver
          : IntercomRiderRole.groupRider,
    );
  }

  Future<void> toggleMeshBridge(bool? value) async {
    HapticFeedback.selectionClick();
    final enabled = value ?? !state.isMeshBridgeEnabled;
    state = state.copyWith(isMeshBridgeEnabled: enabled);
    await _syncAudioSettingsToTransport();
    await _saveAudioPreferences();
  }

  Future<void> toggleFecRecovery(bool? value) async {
    HapticFeedback.selectionClick();
    final enabled = value ?? !state.isFecRecoveryEnabled;
    state = state.copyWith(isFecRecoveryEnabled: enabled);
    await _syncAudioSettingsToTransport();
    await _saveAudioPreferences();
  }

  void setTourName(String tourName) => state = state.copyWith(tourName: tourName);

  // ── Leave / Reset (Retains Recent Tour for 1-Click Rejoin) ────────────────

  Future<void> leaveIntercom() async {
    HapticFeedback.mediumImpact();
    _hardwarePttService.stopListening();
    _connectionSub?.cancel();
    _connectionSub = null;

    final savedCode = state.lastTourCode ?? state.joinCode ?? state.channelCode;
    final savedName = state.lastTourName ?? state.tourName;
    final savedIsHost = state.lastTourIsHost || state.isHost;
    final savedRole = state.riderRole;

    await _stopBackgroundSession();
    await _transport.stop();

    state = IntercomState(
      lastTourCode: savedCode.isNotEmpty ? savedCode : null,
      lastTourName: savedName,
      lastTourIsHost: savedIsHost,
      riderRole: savedRole,
    );
    debugPrint('[IntercomVM] Intercom session disconnected (Recent Tour retained: $savedCode).');
  }

  @override
  void dispose() {
    _sessionService.setEventHandler(null);
    _hardwarePttService.stopListening();
    _connectionSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────────────────────────

final intercomProvider =
    StateNotifierProvider<IntercomViewModel, IntercomState>(
  (ref) => IntercomViewModel(),
);
