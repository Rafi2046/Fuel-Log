import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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

/// Google Nearby Connections Audio Transport Service.
/// Uses BLE discovery + Wi-Fi Direct for zero-internet P2P mesh audio.
/// Immune to AP Client Isolation & works 100% offline.
class NearbyAudioTransport {
  NearbyAudioTransport._();
  static final NearbyAudioTransport instance = NearbyAudioTransport._();

  static const int sampleRate = 16000;
  static const int numChannels = 1; // mono

  final Strategy _strategy = Strategy.P2P_CLUSTER;
  String _serviceId = 'com.ridelog.bd.intercom';

  final Set<String> _connectedEndpoints = {};
  final Map<String, String> _endpointNames = {};

  final _incomingAudioController = StreamController<NearbyAudioPacket>.broadcast();
  final _connectionStateController = StreamController<Set<String>>.broadcast();

  // Audio Engine
  AudioRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription<Uint8List>? _micSub;
  bool _isPlayerStreamStarted = false;
  bool _isTransmitting = false;
  bool _isRunning = false;

  Stream<NearbyAudioPacket> get incomingAudio => _incomingAudioController.stream;
  Stream<Set<String>> get connectionChanges => _connectionStateController.stream;

  Set<String> get connectedEndpoints => Set.unmodifiable(_connectedEndpoints);
  Map<String, String> get endpointNames => Map.unmodifiable(_endpointNames);
  int get connectedCount => _connectedEndpoints.length;
  bool get isRunning => _isRunning;

  // ── Request Required Runtime Permissions ──────────────────────────────────
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.location,
        Permission.microphone,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
      ].request();

      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final locationGranted = statuses[Permission.location]?.isGranted ?? false;

      debugPrint('[NearbyAudioTransport] Permissions -> Mic: $micGranted, Location: $locationGranted');
      return micGranted;
    }
    return true;
  }

  // ── Start Auto-Connect Mesh (Advertising + Discovery) ─────────────────────
  Future<void> start({
    required String userName,
    String? tourId,
  }) async {
    if (_isRunning) await stop();

    await requestPermissions();
    await _initAudioPlayer();

    if (tourId != null && tourId.isNotEmpty) {
      _serviceId = 'com.ridelog.bd.intercom.${tourId.toUpperCase()}';
    } else {
      _serviceId = 'com.ridelog.bd.intercom';
    }

    _isRunning = true;
    _connectedEndpoints.clear();
    _endpointNames.clear();
    _connectionStateController.add(_connectedEndpoints);

    // 1. Start Advertising so nearby riders can discover this device
    try {
      await Nearby().startAdvertising(
        userName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      debugPrint('[NearbyAudioTransport] 📡 Advertising started as "$userName" (Service: $_serviceId)');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Advertising error: $e');
    }

    // 2. Start Discovery to auto-find and connect with nearby riders
    try {
      await Nearby().startDiscovery(
        userName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, foundServiceId) {
          debugPrint('[NearbyAudioTransport] 🔍 Found rider endpoint "$name" ($id). Requesting connection...');
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          ).catchError((err) {
            debugPrint('[NearbyAudioTransport] requestConnection error: $err');
            return false;
          });
        },
        onEndpointLost: (id) {
          if (id != null) _removeEndpoint(id);
        },
      );
      debugPrint('[NearbyAudioTransport] 🔎 Discovery started...');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Discovery error: $e');
    }

    // Listen to incoming audio and feed to player
    _incomingAudioController.stream.listen((packet) {
      _playIncomingAudio(packet.bytes);
    });
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    debugPrint('[NearbyAudioTransport] 🤝 Connection initiated with "${info.endpointName}" ($id). Auto-accepting...');
    _endpointNames[id] = info.endpointName;

    // Auto-accept connection without manual prompt
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          _incomingAudioController.add(
            NearbyAudioPacket(
              fromEndpointId: endpointId,
              fromName: _endpointNames[endpointId] ?? endpointId,
              bytes: payload.bytes!,
            ),
          );
        }
      },
    ).catchError((err) {
      debugPrint('[NearbyAudioTransport] acceptConnection error: $err');
      return false;
    });
  }

  void _onConnectionResult(String id, Status status) {
    debugPrint('[NearbyAudioTransport] 📶 Connection status for $id: $status');
    if (status == Status.CONNECTED) {
      _connectedEndpoints.add(id);
      _connectionStateController.add(connectedEndpoints);
      debugPrint('[NearbyAudioTransport] ✅ CONNECTED with $id (${_endpointNames[id]}). Total riders: ${_connectedEndpoints.length}');
    } else {
      _removeEndpoint(id);
    }
  }

  void _onDisconnected(String id) {
    debugPrint('[NearbyAudioTransport] ❌ Disconnected from $id (${_endpointNames[id]})');
    _removeEndpoint(id);
  }

  void _removeEndpoint(String id) {
    _connectedEndpoints.remove(id);
    _endpointNames.remove(id);
    _connectionStateController.add(connectedEndpoints);
  }

  // ── Audio Player Setup ────────────────────────────────────────────────────
  Future<void> _initAudioPlayer() async {
    try {
      if (_player == null) {
        _player = FlutterSoundPlayer();
        await _player!.openPlayer();
        await _player!.setVolume(1.0);
      }
      await _startPlayerStream();
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Player init warning: $e');
    }
  }

  Future<void> _startPlayerStream() async {
    if (_player == null) return;
    try {
      await _player!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: numChannels,
        sampleRate: sampleRate,
        interleaved: true,
        bufferSize: 4096,
        onBufferUnderflow: () {
          _isPlayerStreamStarted = false;
        },
      );
      _isPlayerStreamStarted = true;
      debugPrint('[NearbyAudioTransport] Audio playback stream started.');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] startPlayerFromStream error: $e');
    }
  }

  Future<void> _playIncomingAudio(Uint8List pcmBytes) async {
    try {
      if (_player == null) {
        await _initAudioPlayer();
      }
      if (!_isPlayerStreamStarted || _player!.isStopped) {
        await _startPlayerStream();
      }
      await _player?.feedUint8FromStream(pcmBytes);
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Audio playback error: $e');
    }
  }

  // ── Mic Audio Transmission ────────────────────────────────────────────────
  Future<void> startTransmitting() async {
    if (_isTransmitting) return;
    _isTransmitting = true;

    _recorder ??= AudioRecorder();
    final hasPerm = await _recorder!.hasPermission();
    if (!hasPerm) {
      debugPrint('[NearbyAudioTransport] Mic permission not granted');
      return;
    }

    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    int chunkIndex = 0;
    _micSub = stream.listen((chunk) {
      if (!_isTransmitting) return;
      chunkIndex++;
      if (chunkIndex % 50 == 0) {
        debugPrint('[NearbyAudioTransport] 🎙️ Audio chunk sent to ${_connectedEndpoints.length} riders (${chunk.length} bytes)');
      }
      sendAudioChunk(chunk);
    });

    debugPrint('[NearbyAudioTransport] ▶ LIVE AUDIO TRANSMISSION STARTED');
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
    _isRunning = false;
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}
    _connectedEndpoints.clear();
    _endpointNames.clear();
    _connectionStateController.add(_connectedEndpoints);
    debugPrint('[NearbyAudioTransport] Stopped Nearby mesh.');
  }

  Future<void> dispose() async {
    await stop();
    await _incomingAudioController.close();
    await _connectionStateController.close();
    await _player?.stopPlayer();
    await _player?.closePlayer();
    _player = null;
  }
}
