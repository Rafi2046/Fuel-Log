import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/hardware_ptt_service.dart';
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
  final bool isMuted;
  final bool isOpenMic;
  final String tourName;
  final String channelCode;
  final String? joinCode;
  final bool isHost;
  final IntercomMode mode;
  final List<IntercomMember> members;
  final int transmissionSeconds;
  final double audioOutputVolume;

  int get onlineCount => members.where((m) => m.isOnline).length;

  IntercomState copyWith({
    bool? isTransmitting,
    bool? isConnecting,
    bool? isConnected,
    String? errorMessage,
    bool? isWindNoiseCancellationEnabled,
    bool? isHelmetAudioRouteEnabled,
    bool? isMeshBridgeEnabled,
    bool? isMuted,
    bool? isOpenMic,
    String? tourName,
    String? channelCode,
    String? joinCode,
    bool? isHost,
    IntercomMode? mode,
    List<IntercomMember>? members,
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
      isMuted: isMuted ?? this.isMuted,
      isOpenMic: isOpenMic ?? this.isOpenMic,
      tourName: tourName ?? this.tourName,
      channelCode: channelCode ?? this.channelCode,
      joinCode: joinCode ?? this.joinCode,
      isHost: isHost ?? this.isHost,
      mode: mode ?? this.mode,
      members: members ?? this.members,
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
  ])  : _hardwarePttService = hardwarePttService ?? HardwarePttService(),
        _transport = transport ?? NearbyAudioTransport.instance,
        super(const IntercomState());

  final HardwarePttService _hardwarePttService;
  final NearbyAudioTransport _transport;

  StreamSubscription<Set<String>>? _connectionSub;

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Generates a cryptographically random 6-character uppercase join code.
  static String generateJoinCode() {
    final rand = Random.secure();
    return List.generate(6, (_) => _codeChars[rand.nextInt(_codeChars.length)]).join();
  }

  // ── Lobby helpers ─────────────────────────────────────────────────────────

  void setTourCodeAndName({required String tourName, required String joinCode}) {
    state = state.copyWith(
      tourName: tourName,
      joinCode: joinCode,
      channelCode: joinCode,
      isHost: true,
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
      isConnecting: false,
      isConnected: true,
      mode: IntercomMode.hosting,
      errorMessage: null,
    );

    try {
      _connectionSub?.cancel();
      _connectionSub = _transport.connectionChanges.listen(_onConnectionsChanged);

      await _transport.start(
        userName: 'Host',
        tourId: code,
      );

      _hardwarePttService.startListening(setTransmitting);

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

  Future<void> joinByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    state = state.copyWith(
      isConnecting: false,
      isConnected: true,
      tourName: 'Tour $cleanCode',
      joinCode: cleanCode,
      channelCode: cleanCode,
      isHost: false,
      errorMessage: null,
    );

    try {
      _connectionSub?.cancel();
      _connectionSub = _transport.connectionChanges.listen(_onConnectionsChanged);

      await _transport.start(
        userName: 'Rider',
        tourId: cleanCode,
      );

      _hardwarePttService.startListening(setTransmitting);

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
  }

  // ── Smart toggles ─────────────────────────────────────────────────────────

  Future<void> toggleWindNoiseCancellation(bool? value) async {
    HapticFeedback.selectionClick();
    state = state.copyWith(
      isWindNoiseCancellationEnabled: value ?? !state.isWindNoiseCancellationEnabled,
    );
  }

  Future<void> toggleHelmetAudioRoute(bool? value) async {
    HapticFeedback.selectionClick();
    state = state.copyWith(
      isHelmetAudioRouteEnabled: value ?? !state.isHelmetAudioRouteEnabled,
    );
  }

  void toggleMeshBridge(bool? value) {
    HapticFeedback.selectionClick();
    state = state.copyWith(
      isMeshBridgeEnabled: value ?? !state.isMeshBridgeEnabled,
    );
  }

  void setTourName(String tourName) => state = state.copyWith(tourName: tourName);

  // ── Leave / Reset ─────────────────────────────────────────────────────────

  Future<void> leaveIntercom() async {
    HapticFeedback.mediumImpact();
    _hardwarePttService.stopListening();
    _connectionSub?.cancel();
    _connectionSub = null;

    await _transport.stop();

    state = const IntercomState();
    debugPrint('[IntercomVM] Intercom session reset.');
  }

  @override
  void dispose() {
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
