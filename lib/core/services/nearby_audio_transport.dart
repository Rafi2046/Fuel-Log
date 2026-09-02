import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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

/// Google Nearby Connections Audio Transport Service with DSP Noise Gate & Filters.
/// Uses BLE discovery + Wi-Fi Direct for zero-internet P2P mesh audio.
/// Immune to AP Client Isolation & works 100% offline.
class NearbyAudioTransport {
  NearbyAudioTransport._();
  static final NearbyAudioTransport instance = NearbyAudioTransport._();

  static const int sampleRate = 16000;
  static const int numChannels = 1; // mono

  final Strategy _strategy = Strategy.P2P_STAR;
  static const String _serviceId = 'com.ridelog.bd.intercom';

  final Set<String> _connectedEndpoints = {};
  final Map<String, String> _endpointNames = {};

  final _incomingAudioController = StreamController<NearbyAudioPacket>.broadcast();
  final _connectionStateController = StreamController<Set<String>>.broadcast();

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

  // Thread-safe FIFO Queue to prevent native AudioTrack SIGSEGV crash
  final List<Uint8List> _audioQueue = [];
  bool _isProcessingQueue = false;

  // DSP State
  double _prevInputSample = 0;
  double _prevOutputSample = 0;

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
        Permission.microphone,
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.nearbyWifiDevices,
      ].request();

      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
      final locGranted = statuses[Permission.location]?.isGranted ?? false;
      debugPrint('[NearbyAudioTransport] Permissions -> Mic: $micGranted, Location: $locGranted');
      return micGranted;
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
      );
      debugPrint('[NearbyAudioTransport] 📡 HOST Advertising started ($advResult) as "$advertisedName"');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Host advertising error: $e');
    }

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
    _isRunning = true;
    _connectedEndpoints.clear();
    _endpointNames.clear();
    _connectionStateController.add(_connectedEndpoints);

    try {
      final discResult = await Nearby().startDiscovery(
        riderName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, foundServiceId) {
          debugPrint('[NearbyAudioTransport] 🔍 Found endpoint "$name" ($id).');
          if (name.contains('#')) {
            final parts = name.split('#');
            if (parts.length >= 2 && parts[1].toUpperCase() == _targetTourCode) {
              debugPrint('[NearbyAudioTransport] Match found for tour $_targetTourCode! Requesting connection...');
              Nearby().requestConnection(
                riderName,
                id,
                onConnectionInitiated: _onConnectionInitiated,
                onConnectionResult: _onConnectionResult,
                onDisconnected: _onDisconnected,
              ).catchError((err) {
                debugPrint('[NearbyAudioTransport] requestConnection error: $err');
                return false;
              });
            }
          }
        },
        onEndpointLost: (id) {
          if (id != null) _removeEndpoint(id);
        },
      );
      debugPrint('[NearbyAudioTransport] 🔎 RIDER Discovery started ($discResult) for tour $_targetTourCode');
    } catch (e) {
      debugPrint('[NearbyAudioTransport] Rider discovery error: $e');
    }

    _setupAudioPacketListener();
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
          // Frame sanity check: 16-bit PCM must have an even number of bytes and reasonable length
          if (rawBytes.length >= 64 && rawBytes.length % 2 == 0) {
            _incomingAudioController.add(
              NearbyAudioPacket(
                fromEndpointId: endpointId,
                fromName: _endpointNames[endpointId] ?? endpointId,
                bytes: rawBytes,
              ),
            );
          }
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
      debugPrint('[NearbyAudioTransport] ✅ CONNECTED with $id (${_endpointNames[id]}). Total active peers: ${_connectedEndpoints.length}');
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

  // ── Audio Player Setup (Thread-Safe FIFO Buffer) ──────────────────────────
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

    // Keep max 15 chunks in queue (~500ms buffer) to avoid memory pile-up and latency
    if (_audioQueue.length > 15) {
      _audioQueue.removeRange(0, _audioQueue.length - 10);
    }
    _audioQueue.add(pcmBytes);

    _processAudioQueue();
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
        }
      } catch (e) {
        debugPrint('[NearbyAudioTransport] Audio feed error: $e');
        break;
      }
    }

    _isProcessingQueue = false;
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

    // Hardware VoIP Acoustic Echo Cancellation & Noise Suppression on Android
    final stream = await _recorder!.startStream(
      const RecordConfig(
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
      ),
    );

    int chunkIndex = 0;
    _micSub = stream.listen((chunk) {
      if (!_isTransmitting) return;

      // Apply real-time Noise Gate and High-Pass Filter to eliminate hissing/rumble
      final cleanChunk = _applyDsdNoiseReduction(chunk);
      if (cleanChunk.isEmpty) return; // Muted by Noise Gate (Silence)

      chunkIndex++;
      if (chunkIndex % 50 == 0) {
        debugPrint('[NearbyAudioTransport] 🎙️ Clean audio chunk sent to ${_connectedEndpoints.length} riders (${cleanChunk.length} bytes)');
      }
      sendAudioChunk(cleanChunk);
    });

    debugPrint('[NearbyAudioTransport] ▶ LIVE AUDIO TRANSMISSION STARTED (VoIP Hardware Filter Active)');
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

    // Noise Gate: If energy is below ambient hiss threshold (~300), suppress background hiss
    if (rms < 300) {
      return Uint8List(0); // Noise Gate cuts transmission when silent
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
    _isRunning = false;
    _audioSub?.cancel();
    _audioSub = null;
    _audioQueue.clear();
    _isProcessingQueue = false;
    _prevInputSample = 0;
    _prevOutputSample = 0;

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
