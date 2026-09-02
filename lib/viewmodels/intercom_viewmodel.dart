import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/hardware_ptt_service.dart';
import '../core/services/p2p_voice_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

/// Connected member in the tour intercom session.
class IntercomMember {
  const IntercomMember({
    required this.id,
    required this.name,
    required this.initials,
    this.isOnline = true,
    this.isSpeaking = false,
    this.isCurrentUser = false,
    this.batteryPercent = 85,
  });

  final String id;
  final String name;
  final String initials;
  final bool isOnline;
  final bool isSpeaking;
  final bool isCurrentUser;
  final int batteryPercent;

  IntercomMember copyWith({
    String? id,
    String? name,
    String? initials,
    bool? isOnline,
    bool? isSpeaking,
    bool? isCurrentUser,
    int? batteryPercent,
  }) {
    return IntercomMember(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      isOnline: isOnline ?? this.isOnline,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      batteryPercent: batteryPercent ?? this.batteryPercent,
    );
  }

  static String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(3, name.length)).toUpperCase();
  }

  factory IntercomMember.fromPeer(P2PPeer peer) {
    return IntercomMember(
      id: peer.id,
      name: peer.name,
      initials: _initialsFor(peer.name),
      isOnline: true,
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
  final String? errorMessage;
  final bool isWindNoiseCancellationEnabled;
  final bool isHelmetAudioRouteEnabled;
  final bool isMeshBridgeEnabled;
  final bool isMuted;
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
    String? errorMessage,
    bool? isWindNoiseCancellationEnabled,
    bool? isHelmetAudioRouteEnabled,
    bool? isMeshBridgeEnabled,
    bool? isMuted,
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
      errorMessage: errorMessage,
      isWindNoiseCancellationEnabled:
          isWindNoiseCancellationEnabled ?? this.isWindNoiseCancellationEnabled,
      isHelmetAudioRouteEnabled:
          isHelmetAudioRouteEnabled ?? this.isHelmetAudioRouteEnabled,
      isMeshBridgeEnabled: isMeshBridgeEnabled ?? this.isMeshBridgeEnabled,
      isMuted: isMuted ?? this.isMuted,
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

      _hardwarePttService.startListening(setTransmitting);

      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
      );

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
    state = state.copyWith(isConnecting: true, errorMessage: null);
    try {
      state = state.copyWith(
        tourName: tourHost.tourName.isNotEmpty ? tourHost.tourName : 'Bike Tour',
        joinCode: tourHost.tourCode,
        channelCode: tourHost.tourCode,
        isHost: false,
        isConnected: true,
      );

      await _p2p.joinTour(tourHost);
      _hardwarePttService.startListening(setTransmitting);
      debugPrint('[IntercomVM] Joining tour: ${tourHost.tourName}');
    } catch (e) {
      debugPrint('[IntercomVM] joinTour error: $e');
      state = state.copyWith(
        isConnecting: false,
        errorMessage: 'Failed to join: $e',
      );
    }
  }

  /// RIDER: Joins tour manually by 6-character code
  Future<void> joinByCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    state = state.copyWith(isConnecting: true, errorMessage: null);

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
    );
  }

  // ── PTT ───────────────────────────────────────────────────────────────────

  Future<void> setTransmitting(bool isTransmitting) async {
    if (state.isTransmitting == isTransmitting) return;
    if (state.isMuted) return;

    if (isTransmitting) {
      HapticFeedback.heavyImpact();
      await _p2p.startTransmitting();
    } else {
      HapticFeedback.lightImpact();
      await _p2p.stopTransmitting();
    }

    state = state.copyWith(isTransmitting: isTransmitting);
    debugPrint('[IntercomVM] PTT: ${isTransmitting ? "TRANSMITTING" : "IDLE"}');
  }

  Future<void> toggleMute() async {
    HapticFeedback.mediumImpact();
    final newMute = !state.isMuted;
    if (newMute && state.isTransmitting) {
      await _p2p.stopTransmitting();
      state = state.copyWith(isTransmitting: false);
    }
    state = state.copyWith(isMuted: newMute);
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

  void setVolume(double volume) =>
      state = state.copyWith(audioOutputVolume: volume.clamp(0.0, 1.0));

  // ── Teardown ──────────────────────────────────────────────────────────────

  Future<void> leaveIntercom() async {
    _hardwarePttService.stopListening();
    await _peerSub?.cancel();
    await _discoverySub?.cancel();
    await _p2p.disconnect();
    state = state.copyWith(
      isConnected: false,
      isTransmitting: false,
      mode: IntercomMode.idle,
      members: const [
        IntercomMember(
          id: 'local',
          name: 'You',
          initials: 'YOU',
          isCurrentUser: true,
          isOnline: true,
          batteryPercent: 92,
        ),
      ],
      discoveredTours: [],
    );
  }

  @override
  void dispose() {
    _peerSub?.cancel();
    _discoverySub?.cancel();
    _hardwarePttService.stopListening();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final hardwarePttServiceProvider = Provider<HardwarePttService>((_) => HardwarePttService());

final intercomProvider = StateNotifierProvider<IntercomViewModel, IntercomState>((ref) {
  final pttService = ref.watch(hardwarePttServiceProvider);
  return IntercomViewModel(pttService);
});

final isTransmittingProvider = Provider<bool>((ref) {
  return ref.watch(intercomProvider).isTransmitting;
});
