import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/hardware_ptt_service.dart';
import '../core/services/p2p_voice_service.dart';

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

  factory IntercomMember.fromPeer(P2PPeer peer) {
    final cleanName = peer.name.trim();
    final initials = cleanName.length >= 2
        ? cleanName.substring(0, 2).toUpperCase()
        : cleanName.isNotEmpty
            ? cleanName.substring(0, 1).toUpperCase()
            : 'RD';

    return IntercomMember(
      id: peer.id,
      name: peer.name,
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
    this.isWaitingForApproval = false,
    this.pendingJoinRequest,
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
    this.discoveredTours = const [],
    this.transmissionSeconds = 0,
    this.audioOutputVolume = 0.85,
  });

  final bool isTransmitting;
  final bool isConnecting;
  final bool isConnected;
  final bool isWaitingForApproval;
  final P2PJoinRequest? pendingJoinRequest;
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

  /// Tours discovered nearby on the local Wi-Fi / Hotspot network
  final List<P2PPeer> discoveredTours;

  final int transmissionSeconds;
  final double audioOutputVolume;

  int get onlineCount => members.where((m) => m.isOnline).length;

  IntercomState copyWith({
    bool? isTransmitting,
    bool? isConnecting,
    bool? isConnected,
    bool? isWaitingForApproval,
    P2PJoinRequest? pendingJoinRequest,
    bool clearPendingRequest = false,
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
    List<P2PPeer>? discoveredTours,
    int? transmissionSeconds,
    double? audioOutputVolume,
  }) {
    return IntercomState(
      isTransmitting: isTransmitting ?? this.isTransmitting,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isWaitingForApproval: isWaitingForApproval ?? this.isWaitingForApproval,
      pendingJoinRequest: clearPendingRequest ? null : (pendingJoinRequest ?? this.pendingJoinRequest),
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
      discoveredTours: discoveredTours ?? this.discoveredTours,
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
    P2PVoiceService? p2pVoiceService,
  ])  : _hardwarePttService = hardwarePttService ?? HardwarePttService(),
        _p2p = p2pVoiceService ?? P2PVoiceService.instance,
        super(const IntercomState());

  final HardwarePttService _hardwarePttService;
  final P2PVoiceService _p2p;

  StreamSubscription<List<P2PPeer>>? _peerSub;
  StreamSubscription<List<P2PPeer>>? _discoverySub;
  StreamSubscription<P2PJoinRequest?>? _joinRequestSub;
  StreamSubscription<bool>? _joinResponseSub;

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
      isConnecting: true,
      mode: IntercomMode.hosting,
      errorMessage: null,
    );

    try {
      await _p2p.startHosting(
        tourName: tourName,
        tourCode: code,
        hostName: 'Host (You)',
      );

      _peerSub?.cancel();
      _peerSub = _p2p.connectedPeers.listen(_onPeersChanged);

      _joinRequestSub?.cancel();
      _joinRequestSub = _p2p.joinRequests.listen((req) {
        state = state.copyWith(pendingJoinRequest: req);
      });

      _hardwarePttService.startListening(setTransmitting);

      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
      );

      if (state.isOpenMic && !state.isMuted) {
        await setTransmitting(true);
      }

      debugPrint('[IntercomVM] Tour "$tourName" hosted with code: $code');
    } catch (e) {
      debugPrint('[IntercomVM] createTour error: $e');
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        errorMessage: 'Failed to start tour: $e',
      );
    }
  }

  // ── HOST: Accept / Decline Join Requests ──────────────────────────────────

  Future<void> acceptJoinRequest(P2PJoinRequest req) async {
    HapticFeedback.mediumImpact();
    await _p2p.acceptJoinRequest(req);
    state = state.copyWith(clearPendingRequest: true);
  }

  Future<void> declineJoinRequest(P2PJoinRequest req) async {
    HapticFeedback.lightImpact();
    await _p2p.declineJoinRequest(req);
    state = state.copyWith(clearPendingRequest: true);
  }

  // ── RIDER: Discover + Join ─────────────────────────────────────────────────

  Future<void> startBrowsing(String riderName) async {
    state = state.copyWith(
      isConnecting: true,
      mode: IntercomMode.joining,
      discoveredTours: [],
      errorMessage: null,
    );

    try {
      await _p2p.startDiscovery(riderName: riderName);

      _discoverySub?.cancel();
      _discoverySub = _p2p.discoveredTours.listen((tours) {
        state = state.copyWith(discoveredTours: tours);
      });

      _peerSub?.cancel();
      _peerSub = _p2p.connectedPeers.listen(_onPeersChanged);

      _joinResponseSub?.cancel();
      _joinResponseSub = _p2p.joinResponses.listen((accepted) {
        if (accepted) {
          state = state.copyWith(
            isConnected: true,
            isConnecting: false,
            isWaitingForApproval: false,
          );
          if (state.isOpenMic && !state.isMuted) {
            setTransmitting(true);
          }
        } else {
          state = state.copyWith(
            isConnected: false,
            isConnecting: false,
            isWaitingForApproval: false,
            errorMessage: 'Join request declined by host.',
          );
        }
      });

      state = state.copyWith(isConnecting: false);
      debugPrint('[IntercomVM] Browsing for tours over local network...');
    } catch (e) {
      debugPrint('[IntercomVM] startBrowsing error: $e');
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Could not start discovery: $e',
      );
    }
  }

  Future<void> joinTour(P2PPeer tourHost) async {
    state = state.copyWith(
      isConnecting: true,
      isWaitingForApproval: true,
      errorMessage: null,
      tourName: tourHost.tourName.isNotEmpty ? tourHost.tourName : 'Bike Tour',
      joinCode: tourHost.tourCode,
      channelCode: tourHost.tourCode,
      isHost: false,
    );

    try {
      _joinResponseSub?.cancel();
      _joinResponseSub = _p2p.joinResponses.listen((accepted) {
        if (accepted) {
          state = state.copyWith(
            isConnected: true,
            isConnecting: false,
            isWaitingForApproval: false,
          );
          if (state.isOpenMic && !state.isMuted) {
            setTransmitting(true);
          }
        } else {
          state = state.copyWith(
            isConnected: false,
            isConnecting: false,
            isWaitingForApproval: false,
            errorMessage: 'Join request declined by host.',
          );
        }
      });

      _peerSub?.cancel();
      _peerSub = _p2p.connectedPeers.listen(_onPeersChanged);

      await _p2p.joinTour(tourHost);
      _hardwarePttService.startListening(setTransmitting);
      debugPrint('[IntercomVM] Sent join request to ${tourHost.tourName}');
    } catch (e) {
      debugPrint('[IntercomVM] joinTour error: $e');
      state = state.copyWith(
        isConnecting: false,
        isWaitingForApproval: false,
        errorMessage: 'Failed to join: $e',
      );
    }
  }

  /// RIDER: Joins tour manually by 6-character code
  Future<void> joinByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    state = state.copyWith(
      isConnecting: true,
      isWaitingForApproval: true,
      errorMessage: null,
    );

    try {
      final matching = state.discoveredTours.firstWhere(
        (t) => t.tourCode.toUpperCase() == cleanCode,
        orElse: () => P2PPeer(
          id: 'host_$cleanCode',
          name: 'Tour Host',
          address: InternetAddress('255.255.255.255'),
          tourName: 'Tour $cleanCode',
          tourCode: cleanCode,
          isHost: true,
        ),
      );

      await joinTour(matching);
    } catch (e) {
      debugPrint('[IntercomVM] joinByCode error: $e');
      state = state.copyWith(
        isConnecting: false,
        isWaitingForApproval: false,
        errorMessage: 'Failed to join by code: $e',
      );
    }
  }

  // ── Peer list update ──────────────────────────────────────────────────────

  void _onPeersChanged(List<P2PPeer> peers) {
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

    final remoteMembers = peers.map(IntercomMember.fromPeer).toList();
    final allMembers = [localMember, ...remoteMembers];

    final nowConnected = peers.isNotEmpty || state.isHost;
    state = state.copyWith(
      members: allMembers,
      isConnected: nowConnected,
      isConnecting: false,
      isWaitingForApproval: false,
    );

    // If hands-free open mic mode is active, make sure we transmit
    if (state.isOpenMic && !state.isMuted && !state.isTransmitting && nowConnected) {
      setTransmitting(true);
    }
  }

  // ── PTT / Hands-Free Transmission ─────────────────────────────────────────

  Future<void> setTransmitting(bool isTransmitting) async {
    if (state.isTransmitting == isTransmitting) return;
    if (state.isMuted && isTransmitting) return;

    if (isTransmitting) {
      HapticFeedback.heavyImpact();
      await _p2p.startTransmitting();
    } else {
      HapticFeedback.lightImpact();
      await _p2p.stopTransmitting();
    }

    state = state.copyWith(isTransmitting: isTransmitting);
    debugPrint('[IntercomVM] Audio Transmission: ${isTransmitting ? "TRANSMITTING (LIVE)" : "MUTED"}');
  }

  Future<void> toggleMute() async {
    HapticFeedback.mediumImpact();
    final newMute = !state.isMuted;
    if (newMute) {
      await _p2p.stopTransmitting();
      state = state.copyWith(isMuted: true, isTransmitting: false);
    } else {
      state = state.copyWith(isMuted: false);
      if (state.isOpenMic && state.isConnected) {
        await _p2p.startTransmitting();
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
    _peerSub?.cancel();
    _peerSub = null;
    _discoverySub?.cancel();
    _discoverySub = null;
    _joinRequestSub?.cancel();
    _joinRequestSub = null;
    _joinResponseSub?.cancel();
    _joinResponseSub = null;

    await _p2p.disconnect();

    state = const IntercomState();
    debugPrint('[IntercomVM] Intercom session reset.');
  }

  @override
  void dispose() {
    _hardwarePttService.stopListening();
    _peerSub?.cancel();
    _discoverySub?.cancel();
    _joinRequestSub?.cancel();
    _joinResponseSub?.cancel();
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
