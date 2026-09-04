import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'intercom_audio_route_service.dart';
import 'intercom_audio_settings.dart';

class NearbyAudioPacket {
  final String fromEndpointId;
  final String fromName;
  final Uint8List bytes;

  const NearbyAudioPacket({
    required this.fromEndpointId,
    required this.fromName,
    required this.bytes,
  });
}

/// Google Nearby Connections Audio Transport Service with DSP Noise Gate & Filters.
/// Uses BLE discovery + Wi-Fi Direct for zero-internet P2P mesh audio.
/// Immune to AP Client Isolation & works 100% offline.
class NearbyAudioTransport {
  NearbyAudioTransport._();
  static final NearbyAudioTransport instance = NearbyAudioTransport._();

  @visibleForTesting
  static NearbyAudioTransport createForTesting() => NearbyAudioTransport._();

  static const int sampleRate = 16000;
  static const int numChannels = 1; // mono

  final Strategy _strategy = Strategy.P2P_STAR;
  static const String _serviceId = 'com.ridelog.bd.intercom';

  final Set<String> _connectedEndpoints = {};
  final Map<String, String> _endpointNames = {};

  final _incomingAudioController = StreamController<NearbyAudioPacket>.broadcast();
  final _connectionStateController = StreamController<Set<String>>.broadcast();
  final _rosterController = StreamController<List<String>>.broadcast();

  // Audio Engine
  AudioRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription<NearbyAudioPacket>? _audioSub;

  bool _isPlayerStreamStarted = false;
  bool _isTransmitting = false;
  bool _isRunning = false;
  bool _isHost = false;
  String _targetTourCode = '';
  String _riderDiscoveryName = '';
  String? _connectingEndpointId;
  Timer? _discoveryRefreshTimer;
  final Set<String> _mutedPeerNames = {};

  void toggleMutePeer(String peerNameOrId) {
    if (_mutedPeerNames.contains(peerNameOrId)) {
      _mutedPeerNames.remove(peerNameOrId);
    } else {
      _mutedPeerNames.add(peerNameOrId);
    }
    debugPrint('[NearbyAudioTransport] Mute state for "$peerNameOrId": ${_mutedPeerNames.contains(peerNameOrId)}');
  }

  bool isPeerMuted(String peerNameOrId) => _mutedPeerNames.contains(peerNameOrId);

  // Thread-safe FIFO Queue to prevent native AudioTrack SIGSEGV crash
  final List<Uint8List> _audioQueue = [];
  bool _isProcessingQueue = false;

  // DSP State
  double _prevInputSample = 0;
  double _prevOutputSample = 0;

  IntercomAudioSettings _audioSettings = const IntercomAudioSettings();
  Uint8List? _lastPlayedChunk;
  bool _fecPlaybackPrimed = false;

  IntercomAudioSettings get audioSettings => _audioSettings;

  Stream<NearbyAudioPacket> get incomingAudio => _incomingAudioController.stream;
  Stream<Set<String>> get connectionChanges => _connectionStateController.stream;
  Stream<List<String>> get rosterChanges => _rosterController.stream;

  Set<String> get connectedEndpoints => Set.unmodifiable(_connectedEndpoints);
  Map<String, String> get endpointNames => Map.unmodifiable(_endpointNames);
  int get connectedCount => _connectedEndpoints.length;
  bool get isRunning => _isRunning;

  Future<void> updateAudioSettings(IntercomAudioSettings settings) async {
    final micConfigChanged = _audioSettings.helmetAudioRouteEnabled !=
            settings.helmetAudioRouteEnabled ||
        _audioSettings.loudspeakerEnabled != settings.loudspeakerEnabled ||
        _audioSettings.riderRole != settings.riderRole;
    _audioSettings = settings;

    if (!_fecRecoveryEnabled) {
      _fecPlaybackPrimed = true;
    } else if (!_fecPlaybackPrimed &&
        _audioQueue.length >= _fecMinBufferChunks) {
      _fecPlaybackPrimed = true;
    }

    await _applyAudioRoute();
    await _applyPlaybackVolume();

    if (micConfigChanged && _isTransmitting) {
      await stopTransmitting();
      await startTransmitting();
    }

    debugPrint('[NearbyAudioTransport] Audio settings updated: $settings');
  }

  Future<void> _applyAudioRoute() async {
    final useSpeakerphone = _loudspeakerEnabled && !_helmetAudioRouteEnabled;
    await IntercomAudioRouteService.instance
        .setSpeakerphoneEnabled(useSpeakerphone);
  }

  Future<void> _applyPlaybackVolume() async {
    if (_player == null) return;
    try {
      final volume = _loudspeakerEnabled || _coRiderModeEnabled ? 1.0 : 0.88;
      await _player!.setVolume(volume);
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Volume set warning: $e');
    }
  }

  bool get _windNoiseFilterEnabled => _audioSettings.windNoiseFilterEnabled;
  bool get _helmetAudioRouteEnabled => _audioSettings.helmetAudioRouteEnabled;
  bool get _meshBridgeEnabled => _audioSettings.meshBridgeEnabled;
  bool get _fecRecoveryEnabled => _audioSettings.fecRecoveryEnabled;
  bool get _loudspeakerEnabled => _audioSettings.loudspeakerEnabled;
  bool get _coRiderModeEnabled => _audioSettings.coRiderModeEnabled;
  bool get _pillionModeEnabled => _audioSettings.pillionModeEnabled;

  double get _noiseGateThreshold {
    if (_pillionModeEnabled) return 120.0;
    if (_coRiderModeEnabled) return 140.0;
    return 300.0;
  }

  static const int _fecMinBufferChunks = 2;

  // ── Request Required Runtime Permissions ──────────────────────────────────
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      try {
        final permissionsToCheck = [
          Permission.microphone,
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothAdvertise,
          Permission.bluetoothConnect,
          Permission.nearbyWifiDevices,
        ];
        final needed = <Permission>[];
        for (final p in permissionsToCheck) {
          final isGranted = await p.isGranted;
          if (!isGranted) {
            needed.add(p);
          }
        }

        if (needed.isNotEmpty) {
          await needed.request().timeout(
            const Duration(seconds: 4),
            onTimeout: () => {},
          );
        }

        final micGranted = await Permission.microphone.isGranted;
        final locGranted = await Permission.location.isGranted;
        debugPrint('[NearbyAudioTransport] Permissions -> Mic: $micGranted, Location: $locGranted');
        return micGranted;
      } catch (e) {
        debugPrint('[NearbyAudioTransport] requestPermissions error: $e');
        return false;
      }
    }
    return true;
  }

  // ── HOST: Start Hosting Tour (Advertiser) ─────────────────────────────────
  Future<void> startHosting({
    required String userName,
    required String tourCode,
  }) async {
    await stop();
    _isHost = true;
    _targetTourCode = tourCode.trim().toUpperCase();

    await requestPermissions();
    await _initAudioPlayer();

    final advertisedName = 'HOST#$_targetTourCode#$userName';
    _isRunning = true;
    _connectedEndpoints.clear();
    _endpointNames.clear();
    _connectionStateController.add(_connectedEndpoints);

    try {
      final advResult = await Nearby().startAdvertising(
        advertisedName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[NearbyAudioTransport] startAdvertising timed out.');
          return false;
        },
      );
      debugPrint('[NearbyAudioTransport] 📡 HOST Advertising started ($advResult) as "$advertisedName"');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Host advertising error: $e');
    }

    await _applyAudioRoute();
    _setupAudioPacketListener();
  }

  // ── RIDER: Join Tour (Discoverer) ─────────────────────────────────────────
  Future<void> startJoining({
    required String userName,
    required String tourCode,
  }) async {
    await stop();
    _isHost = false;
    _targetTourCode = tourCode.trim().toUpperCase();

    await requestPermissions();
    await _initAudioPlayer();

    final riderName = 'RIDER#$_targetTourCode#$userName';
    _riderDiscoveryName = riderName;
    _isRunning = true;
    _connectedEndpoints.clear();
    _endpointNames.clear();
    _connectionStateController.add(_connectedEndpoints);

    await _beginRiderDiscovery();
    _scheduleDiscoveryRefresh();
    await _applyAudioRoute();
    _setupAudioPacketListener();
  }

  Future<void> _beginRiderDiscovery() async {
    if (!_isRunning || _riderDiscoveryName.isEmpty) return;

    try {
      final discResult = await Nearby().startDiscovery(
        _riderDiscoveryName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, foundServiceId) {
          debugPrint('[NearbyAudioTransport] 🔍 Found endpoint "$name" ($id).');
          if (name.contains('#')) {
            final parts = name.split('#');
            if (parts.length >= 2 && parts[1].toUpperCase() == _targetTourCode) {
              if (_connectingEndpointId != null) return;
              _connectingEndpointId = id;
              debugPrint(
                '[NearbyAudioTransport] Match found for tour $_targetTourCode! Pausing discovery and requesting connection to $id...',
              );
              _stopDiscoveryRefresh();
              // Pause discovery so Wi-Fi hardware can dedicate full radio to the P2P connection handshake
              unawaited(Nearby().stopDiscovery());

              Nearby().requestConnection(
                _riderDiscoveryName,
                id,
                onConnectionInitiated: _onConnectionInitiated,
                onConnectionResult: _onConnectionResult,
                onDisconnected: _onDisconnected,
              ).catchError((err) {
                debugPrint('[NearbyAudioTransport] requestConnection error: $err');
                _connectingEndpointId = null;
                if (!_isHost && _connectedEndpoints.isEmpty && _isRunning) {
                  _beginRiderDiscovery();
                  _scheduleDiscoveryRefresh();
                }
                return false;
              });
            }
          }
        },
        onEndpointLost: (id) {
          if (id != null) _removeEndpoint(id);
        },
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('[NearbyAudioTransport] startDiscovery timed out.');
          return false;
        },
      );
      debugPrint(
        '[NearbyAudioTransport] 🔎 RIDER Discovery started ($discResult) for tour $_targetTourCode',
      );
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Rider discovery error: $e');
    }
  }

  void _scheduleDiscoveryRefresh() {
    _discoveryRefreshTimer?.cancel();
    _discoveryRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isRunning || _isHost || _connectedEndpoints.isNotEmpty || _connectingEndpointId != null) return;
      unawaited(_refreshRiderDiscovery());
    });
  }

  Future<void> _refreshRiderDiscovery() async {
    if (_isHost || !_isRunning || _connectedEndpoints.isNotEmpty) return;

    try {
      await Nearby().stopDiscovery();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await _beginRiderDiscovery();
      debugPrint('[NearbyAudioTransport] Rider discovery refreshed.');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Discovery refresh error: $e');
    }
  }

  void _stopDiscoveryRefresh() {
    _discoveryRefreshTimer?.cancel();
    _discoveryRefreshTimer = null;
  }

  void _setupAudioPacketListener() {
    _audioSub?.cancel();
    _audioSub = _incomingAudioController.stream.listen((packet) {
      _playIncomingAudio(packet.bytes);
    });
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    debugPrint('[NearbyAudioTransport] 🤝 Connection initiated with "${info.endpointName}" ($id). Auto-accepting...');
    final rawName = info.endpointName;
    final displayName = rawName.contains('#') ? rawName.split('#').last : rawName;
    _endpointNames[id] = displayName.isNotEmpty ? displayName : 'Rider';

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          final rawBytes = payload.bytes!;

          // Check for roster control message from host (CTRL:ROSTER:Host|Rider 1|...)
          if (rawBytes.length >= 12 &&
              rawBytes[0] == 67 && // 'C'
              rawBytes[1] == 84 && // 'T'
              rawBytes[2] == 82 && // 'R'
              rawBytes[3] == 76) { // 'L'
            try {
              final msg = utf8.decode(rawBytes);
              if (msg.startsWith('CTRL:ROSTER:')) {
                final names = msg.substring(12).split('|').where((s) => s.isNotEmpty).toList();
                _rosterController.add(names);
                return;
              }
            } catch (_) {}
          }

          // Frame sanity check: 16-bit PCM must have an even number of bytes and reasonable length
          if (rawBytes.length >= 64 && rawBytes.length % 2 == 0) {
            final senderName = _endpointNames[endpointId] ?? endpointId;
            final isSenderMuted = _mutedPeerNames.contains(senderName) || _mutedPeerNames.contains(endpointId);

            if (!isSenderMuted) {
              _incomingAudioController.add(
                NearbyAudioPacket(
                  fromEndpointId: endpointId,
                  fromName: senderName,
                  bytes: rawBytes,
                ),
              );
            }

            // Host multi-rider relay when mesh bridge is enabled.
            if (_meshBridgeEnabled && _isHost && _connectedEndpoints.length > 1) {
              for (final peerId in _connectedEndpoints) {
                if (peerId != endpointId) {
                  unawaited(Nearby().sendBytesPayload(peerId, rawBytes));
                }
              }
            }
          }
        }
      },
    ).catchError((err) {
      debugPrint('[NearbyAudioTransport] acceptConnection error: $err');
      return false;
    });
  }

  void _broadcastRosterToPeers() {
    if (!_isHost || _connectedEndpoints.isEmpty) return;
    for (final targetId in _connectedEndpoints) {
      final otherRidersForThisPeer = _connectedEndpoints
          .where((id) => id != targetId)
          .map((id) => _endpointNames[id] ?? 'Rider')
          .toList();
      final rosterStr = otherRidersForThisPeer.isEmpty
          ? 'CTRL:ROSTER:Host'
          : 'CTRL:ROSTER:Host|${otherRidersForThisPeer.join('|')}';
      final bytes = Uint8List.fromList(utf8.encode(rosterStr));
      unawaited(Nearby().sendBytesPayload(targetId, bytes));
    }
  }

  void _onConnectionResult(String id, Status status) {
    debugPrint('[NearbyAudioTransport] 📶 Connection status for $id: $status');
    _connectingEndpointId = null;
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(id);
      _connectionStateController.add(connectedEndpoints);
      _stopDiscoveryRefresh();
      playChime(isJoin: true);
      debugPrint(
        '[NearbyAudioTransport] ✅ CONNECTED with $id (${_endpointNames[id]}). Total active peers: ${_connectedEndpoints.length}',
      );
      if (_isHost) {
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          _broadcastRosterToPeers();
        });
      }
    } else {
      _removeEndpoint(id);
      if (!_isHost && _connectedEndpoints.isEmpty && _isRunning) {
        _beginRiderDiscovery();
        _scheduleDiscoveryRefresh();
      }
    }
  }

  void _onDisconnected(String id) {
    debugPrint('[NearbyAudioTransport] ❌ Disconnected from $id (${_endpointNames[id]})');
    playChime(isJoin: false);
    _removeEndpoint(id);
  }

  void _removeEndpoint(String id) {
    _connectedEndpoints.remove(id);
    _endpointNames.remove(id);
    _connectionStateController.add(connectedEndpoints);
    if (_isHost) {
      _broadcastRosterToPeers();
    }
    if (!_isHost && _isRunning && _connectedEndpoints.isEmpty) {
      _scheduleDiscoveryRefresh();
    }
  }

  // ── Audio Player Setup (Thread-Safe FIFO Buffer) ──────────────────────────
  Future<void> _initAudioPlayer() async {
    try {
      if (_player == null) {
        _player = FlutterSoundPlayer();
        await _player!.openPlayer().timeout(
          const Duration(seconds: 3),
          onTimeout: () => _player,
        );
      }
      await _applyPlaybackVolume();
      await _startPlayerStream();
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Player init warning: $e');
    }
  }

  Future<void> _startPlayerStream() async {
    if (_player == null) return;
    try {
      if (_isPlayerStreamStarted && !_player!.isStopped) {
        return;
      }
      await _player!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: numChannels,
        sampleRate: sampleRate,
        interleaved: true,
        bufferSize: 8192,
        onBufferUnderflow: () {
          _isPlayerStreamStarted = false;
          if (_fecRecoveryEnabled && _lastPlayedChunk != null) {
            unawaited(_player?.feedUint8FromStream(_lastPlayedChunk!));
          }
        },
      );
      _isPlayerStreamStarted = true;
      debugPrint('[NearbyAudioTransport] Audio playback stream started.');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] startPlayerFromStream error: $e');
    }
  }

  /// Sequential, thread-safe queue to eliminate JNI race conditions and SIGSEGV crashes
  void _playIncomingAudio(Uint8List pcmBytes) {
    if (pcmBytes.isEmpty || pcmBytes.length % 2 != 0) return;

    if (_audioQueue.length > 15) {
      _audioQueue.removeRange(0, _audioQueue.length - 10);
    }
    _audioQueue.add(pcmBytes);

    if (!_fecRecoveryEnabled) {
      _fecPlaybackPrimed = true;
    } else if (!_fecPlaybackPrimed &&
        _audioQueue.length >= _fecMinBufferChunks) {
      _fecPlaybackPrimed = true;
    }

    if (_fecPlaybackPrimed) {
      _processAudioQueue();
    }
  }

  Future<void> _processAudioQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_audioQueue.isNotEmpty && _isRunning) {
      final chunk = _audioQueue.removeAt(0);
      try {
        if (_player != null) {
          if (!_isPlayerStreamStarted || _player!.isStopped) {
            await _startPlayerStream();
          }
          await _player!.feedUint8FromStream(chunk);
          _lastPlayedChunk = chunk;
        }
      } catch (e) {
        debugPrint('[NearbyAudioTransport] Audio feed error: $e');
        break;
      }
    }

    _isProcessingQueue = false;
  }

  // ── In-Ear Chimes & Status Tones ──────────────────────────────────────────
  void playChime({required bool isJoin}) {
    try {
      if (isJoin) {
        HapticFeedback.lightImpact();
        final tone = _generateTone(
          frequencies: [587.33, 880.0], // D5 -> A5 (pleasant ascending chime)
          durationsMs: [90, 140],
          volume: 0.32,
        );
        _playIncomingAudio(tone);
      } else {
        HapticFeedback.mediumImpact();
        final tone = _generateTone(
          frequencies: [784.0, 440.0], // G5 -> A4 (clear descending warning chime)
          durationsMs: [95, 160],
          volume: 0.35,
        );
        _playIncomingAudio(tone);
      }
    } catch (e) {
      debugPrint('[NearbyAudioTransport] playChime error: $e');
    }
  }

  Uint8List _generateTone({
    required List<double> frequencies,
    required List<int> durationsMs,
    double volume = 0.35,
  }) {
    const int sRate = sampleRate; // 16000
    int totalSamples = 0;
    for (final ms in durationsMs) {
      totalSamples += (sRate * ms) ~/ 1000;
    }

    final bytes = Uint8List(totalSamples * 2);
    final data = ByteData.sublistView(bytes);

    int sampleOffset = 0;
    for (int seg = 0; seg < frequencies.length; seg++) {
      final freq = frequencies[seg];
      final segSamples = (sRate * durationsMs[seg]) ~/ 1000;
      final twoPiF = 2.0 * math.pi * freq / sRate;

      for (int i = 0; i < segSamples; i++) {
        double envelope = 1.0;
        final attackSamples = (segSamples * 0.15).toInt();
        if (i < attackSamples && attackSamples > 0) {
          envelope = i / attackSamples;
        } else {
          envelope = math.exp(-3.5 * (i - attackSamples) / math.max(1, segSamples - attackSamples));
        }

        final double val = math.sin(twoPiF * i) * 32767.0 * volume * envelope;
        final int clamped = val.clamp(-32768.0, 32767.0).toInt();
        data.setInt16((sampleOffset + i) * 2, clamped, Endian.little);
      }
      sampleOffset += segSamples;
    }

    return bytes;
  }

  // ── Mic Audio Transmission with DSP Noise Gate & High-Pass Filter ─────────
  Future<void> startTransmitting() async {
    if (_isTransmitting) return;
    _isTransmitting = true;

    _recorder ??= AudioRecorder();
    final hasPerm = await _recorder!.hasPermission();
    if (!hasPerm) {
      debugPrint('[NearbyAudioTransport] Mic permission not granted');
      return;
    }

    final stream = await _recorder!.startStream(_buildRecordConfig());

    int chunkIndex = 0;
    _micSub = stream.listen((chunk) {
      if (!_isTransmitting) return;

      final cleanChunk =
          _windNoiseFilterEnabled ? _applyDsdNoiseReduction(chunk) : chunk;
      if (cleanChunk.isEmpty) return; // Muted by Noise Gate (Silence)

      chunkIndex++;
      if (chunkIndex % 50 == 0) {
        debugPrint('[NearbyAudioTransport] 🎙️ Clean audio chunk sent to ${_connectedEndpoints.length} riders (${cleanChunk.length} bytes)');
      }
      sendAudioChunk(cleanChunk);
    });

    debugPrint(
      '[NearbyAudioTransport] ▶ LIVE AUDIO TRANSMISSION STARTED '
      '(helmet route: $_helmetAudioRouteEnabled, wind filter: $_windNoiseFilterEnabled)',
    );
  }

  RecordConfig _buildRecordConfig() {
    if (_helmetAudioRouteEnabled) {
      return const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          audioManagerMode: AudioManagerMode.modeInCommunication,
        ),
      );
    }

    if (_loudspeakerEnabled || _coRiderModeEnabled) {
      return const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          audioManagerMode: AudioManagerMode.modeInCommunication,
        ),
      );
    }

    return const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: numChannels,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
      androidConfig: AndroidRecordConfig(
        audioSource: AndroidAudioSource.mic,
        audioManagerMode: AudioManagerMode.modeNormal,
      ),
    );
  }

  /// Real-Time Digital Signal Processing (DSP):
  /// 1. Energy Calculation (RMS) for Noise Gate.
  /// 2. High-Pass Filter (~150Hz) to remove wind turbulence and low rumble.
  /// 3. Soft Limiter to prevent harsh digital clipping.
  Uint8List _applyDsdNoiseReduction(Uint8List rawBytes) {
    if (rawBytes.length < 2) return rawBytes;
    final byteData = ByteData.sublistView(rawBytes);
    final numSamples = rawBytes.length ~/ 2;

    // 1. RMS Energy Calculation for Voice Activity Detection
    int sumSquared = 0;
    for (int i = 0; i < numSamples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquared += sample * sample;
    }
    final double rms = math.sqrt(sumSquared / numSamples);

    // Noise Gate: suppress wind/ambient when below threshold.
    if (rms < _noiseGateThreshold) {
      return Uint8List(0);
    }

    // 2. High-Pass Filter (removes low-frequency wind turbulence & engine drone < 150Hz)
    final output = Uint8List(rawBytes.length);
    final outData = ByteData.sublistView(output);
    const double alpha = 0.94; // ~150Hz Cutoff Filter at 16kHz

    for (int i = 0; i < numSamples; i++) {
      final double sample = byteData.getInt16(i * 2, Endian.little).toDouble();
      final double filtered = alpha * (_prevOutputSample + sample - _prevInputSample);
      _prevInputSample = sample;
      _prevOutputSample = filtered;

      int clamped = filtered.round();
      if (clamped > 32767) clamped = 32767;
      if (clamped < -32768) clamped = -32768;

      outData.setInt16(i * 2, clamped, Endian.little);
    }

    return output;
  }

  Future<void> stopTransmitting() async {
    if (!_isTransmitting) return;
    _isTransmitting = false;
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    debugPrint('[NearbyAudioTransport] ■ AUDIO TRANSMISSION STOPPED');
  }

  /// Broadcast audio chunk to all connected riders via Nearby Connections
  void sendAudioChunk(Uint8List chunk) {
    if (_connectedEndpoints.isEmpty) return;
    for (final id in _connectedEndpoints) {
      unawaited(Nearby().sendBytesPayload(id, chunk));
    }
  }

  // ── Teardown ──────────────────────────────────────────────────────────────
  Future<void> stop() async {
    await stopTransmitting();
    _stopDiscoveryRefresh();
    _riderDiscoveryName = '';
    _connectingEndpointId = null;
    _isRunning = false;
    _audioSub?.cancel();
    _audioSub = null;
    _audioQueue.clear();
    _isProcessingQueue = false;
    _lastPlayedChunk = null;
    _fecPlaybackPrimed = false;
    _prevInputSample = 0;
    _prevOutputSample = 0;
    _mutedPeerNames.clear();

    try {
      await Nearby().stopAdvertising().timeout(const Duration(seconds: 2), onTimeout: () {});
      await Nearby().stopDiscovery().timeout(const Duration(seconds: 2), onTimeout: () {});
      await Nearby().stopAllEndpoints().timeout(const Duration(seconds: 2), onTimeout: () {});
    } catch (_) {}
    _connectedEndpoints.clear();
    _endpointNames.clear();
    _connectionStateController.add(_connectedEndpoints);
    await IntercomAudioRouteService.instance.setSpeakerphoneEnabled(false);
    debugPrint('[NearbyAudioTransport] Stopped Nearby mesh.');
  }

  Future<void> dispose() async {
    await stop();
    await _incomingAudioController.close();
    await _connectionStateController.close();
    await _rosterController.close();
    await _player?.stopPlayer();
    await _player?.closePlayer();
    _player = null;
  }
}
