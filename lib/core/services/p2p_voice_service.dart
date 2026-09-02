import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Represents a peer discovered over the local Wi-Fi / Hotspot network.
class P2PPeer {
  const P2PPeer({
    required this.id,
    required this.name,
    required this.address,
    this.tourName = '',
    this.tourCode = '',
    this.isHost = false,
  });

  final String id;
  final String name;
  final InternetAddress address;
  final String tourName;
  final String tourCode;
  final bool isHost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is P2PPeer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Offline P2P Voice & Discovery Service using pure Dart UDP sockets.
/// Works on local Wi-Fi / Personal Hotspot (like Mini Militia / LAN games).
/// ZERO INTERNET REQUIRED.
class P2PVoiceService {
  P2PVoiceService._();
  static final P2PVoiceService instance = P2PVoiceService._();

  static const int discoveryPort = 38888;
  static const int audioPort = 38889;
  static const int sampleRate = 16000;
  static const int numChannels = 1; // mono

  // ── Sockets & Networking ──────────────────────────────────────────────────
  RawDatagramSocket? _discoverySocket;
  RawDatagramSocket? _audioSocket;
  Timer? _beaconTimer;

  String _localId = '';
  String _localName = 'Rider';
  String _currentTourName = '';
  String _currentTourCode = '';
  bool _isHost = false;

  final Map<String, P2PPeer> _connectedPeers = {};
  final Map<String, P2PPeer> _discoveredTours = {};

  // ── Audio Engine ──────────────────────────────────────────────────────────
  AudioRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription<Uint8List>? _micSub;

  // ── Streams ───────────────────────────────────────────────────────────────
  final _peerListCtrl = StreamController<List<P2PPeer>>.broadcast();
  final _discoveredCtrl = StreamController<List<P2PPeer>>.broadcast();

  Stream<List<P2PPeer>> get connectedPeers => _peerListCtrl.stream;
  Stream<List<P2PPeer>> get discoveredTours => _discoveredCtrl.stream;

  List<P2PPeer> get currentPeers => _connectedPeers.values.toList();

  bool _isInitialized = false;
  bool _isTransmitting = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<bool> init({
    required String localId,
    required String localName,
  }) async {
    _localId = localId;
    _localName = localName;

    if (_isInitialized) return true;

    try {
      // 1. Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted && !micStatus.isLimited) {
        debugPrint('[P2PVoiceService] Microphone permission not granted');
      }

      // 2. Setup UDP Discovery Socket (broadcast enabled)
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );
      _discoverySocket!.broadcastEnabled = true;
      _discoverySocket!.listen(_handleDiscoveryEvent);

      // 3. Setup UDP Audio Socket
      _audioSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        audioPort,
        reuseAddress: true,
        reusePort: true,
      );
      _audioSocket!.broadcastEnabled = true;
      _audioSocket!.listen(_handleAudioEvent);

      // 4. Setup Audio Player for receiving streams
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      await _player!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: numChannels,
        sampleRate: sampleRate,
        interleaved: true,
        bufferSize: 2048,
      );

      _isInitialized = true;
      debugPrint('[P2PVoiceService] Initialized sockets on ports $discoveryPort/$audioPort');
      return true;
    } catch (e) {
      debugPrint('[P2PVoiceService] Init error: $e');
      return false;
    }
  }

  // ── HOST: Start Hosting Tour ──────────────────────────────────────────────

  Future<void> startHosting({
    required String tourName,
    required String tourCode,
    required String hostName,
  }) async {
    _isHost = true;
    _currentTourName = tourName;
    _currentTourCode = tourCode;
    _localName = hostName;
    _connectedPeers.clear();

    await init(localId: _localId.isEmpty ? _randomId() : _localId, localName: hostName);

    // Periodically broadcast tour beacon across the LAN/Hotspot
    _beaconTimer?.cancel();
    _beaconTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _broadcastBeacon();
    });

    _peerListCtrl.add([]);
    debugPrint('[P2PVoiceService] Hosting tour "$tourName" [$tourCode]');
  }

  void _broadcastBeacon() {
    if (_discoverySocket == null) return;
    final msg = jsonEncode({
      'type': 'beacon',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    });
    final data = utf8.encode(msg);
    _discoverySocket?.send(data, InternetAddress('255.255.255.255'), discoveryPort);
  }

  // ── RIDER: Start Discovery ────────────────────────────────────────────────

  Future<void> startDiscovery({required String riderName}) async {
    _isHost = false;
    _localName = riderName;
    _discoveredTours.clear();

    await init(localId: _localId.isEmpty ? _randomId() : _localId, localName: riderName);
    _discoveredCtrl.add([]);
    debugPrint('[P2PVoiceService] Listening for tour beacons...');
  }

  // ── RIDER: Join a Tour ────────────────────────────────────────────────────

  Future<void> joinTour(P2PPeer tourHost) async {
    _currentTourName = tourHost.tourName;
    _currentTourCode = tourHost.tourCode;
    _connectedPeers[tourHost.id] = tourHost;

    // Send join packet to the host
    final msg = jsonEncode({
      'type': 'join',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    });
    final data = utf8.encode(msg);
    _discoverySocket?.send(data, tourHost.address, discoveryPort);

    _peerListCtrl.add(_connectedPeers.values.toList());
    debugPrint('[P2PVoiceService] Sent join request to ${tourHost.name} (${tourHost.address.address})');
  }

  // ── Socket Message Handlers ───────────────────────────────────────────────

  void _handleDiscoveryEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read && _discoverySocket != null) {
      final datagram = _discoverySocket!.receive();
      if (datagram == null) return;

      try {
        final text = utf8.decode(datagram.data);
        final json = jsonDecode(text) as Map<String, dynamic>;
        final type = json['type'] as String?;
        final peerId = json['id'] as String?;

        if (peerId == null || peerId == _localId) return; // Ignore own packets

        if (type == 'beacon') {
          // Received a tour advertisement from a host
          final peer = P2PPeer(
            id: peerId,
            name: json['name'] as String? ?? 'Host',
            address: datagram.address,
            tourName: json['tour'] as String? ?? 'Bike Tour',
            tourCode: json['code'] as String? ?? '',
            isHost: true,
          );
          _discoveredTours[peerId] = peer;
          _discoveredCtrl.add(_discoveredTours.values.toList());
        } else if (type == 'join' && _isHost) {
          // A rider joined our hosted tour
          final rider = P2PPeer(
            id: peerId,
            name: json['name'] as String? ?? 'Rider',
            address: datagram.address,
            tourName: _currentTourName,
            tourCode: _currentTourCode,
            isHost: false,
          );
          _connectedPeers[peerId] = rider;
          _peerListCtrl.add(_connectedPeers.values.toList());

          // Send welcome ack back to the rider
          final ack = jsonEncode({
            'type': 'ack',
            'id': _localId,
            'name': _localName,
            'tour': _currentTourName,
            'code': _currentTourCode,
          });
          _discoverySocket?.send(utf8.encode(ack), datagram.address, discoveryPort);
          debugPrint('[P2PVoiceService] Rider ${rider.name} joined the tour.');
        } else if (type == 'ack' && !_isHost) {
          // Host acknowledged our join
          final host = P2PPeer(
            id: peerId,
            name: json['name'] as String? ?? 'Host',
            address: datagram.address,
            tourName: _currentTourName,
            tourCode: _currentTourCode,
            isHost: true,
          );
          _connectedPeers[peerId] = host;
          _peerListCtrl.add(_connectedPeers.values.toList());
        } else if (type == 'leave') {
          _connectedPeers.remove(peerId);
          _peerListCtrl.add(_connectedPeers.values.toList());
        }
      } catch (e) {
        // Silently skip malformed packets
      }
    }
  }

  void _handleAudioEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read && _audioSocket != null) {
      final datagram = _audioSocket!.receive();
      if (datagram == null) return;

      final data = datagram.data;
      // Minimum packet size check: 4 bytes sender prefix + audio payload
      if (data.length > 4) {
        final senderPrefix = utf8.decode(data.sublist(0, 4), allowMalformed: true);
        if (senderPrefix == _localId.substring(0, 4.clamp(0, _localId.length))) {
          return; // Ignore own looped audio
        }
        final pcmBytes = data.sublist(4);
        _player?.feedFromStream(pcmBytes);
      }
    }
  }

  // ── PTT Audio Transmission ────────────────────────────────────────────────

  Future<void> startTransmitting() async {
    if (_isTransmitting) return;
    _isTransmitting = true;

    _recorder ??= AudioRecorder();
    final hasPerm = await _recorder!.hasPermission();
    if (!hasPerm) {
      debugPrint('[P2PVoiceService] Mic permission not granted');
      return;
    }

    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: numChannels,
        bitRate: 16000 * 16,
      ),
    );

    final prefixBytes = utf8.encode(
      (_localId.padRight(4)).substring(0, 4),
    );

    _micSub = stream.listen((chunk) {
      if (_audioSocket == null) return;
      final packet = Uint8List(prefixBytes.length + chunk.length);
      packet.setRange(0, prefixBytes.length, prefixBytes);
      packet.setRange(prefixBytes.length, packet.length, chunk);

      // Broadcast to entire local network / Hotspot subnet
      _audioSocket?.send(packet, InternetAddress('255.255.255.255'), audioPort);

      // Also unicast directly to all known connected peer IPs
      for (final peer in _connectedPeers.values) {
        _audioSocket?.send(packet, peer.address, audioPort);
      }
    });

    debugPrint('[P2PVoiceService] ▶ PTT TRANSMITTING');
  }

  Future<void> stopTransmitting() async {
    if (!_isTransmitting) return;
    _isTransmitting = false;
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    debugPrint('[P2PVoiceService] ■ PTT IDLE (MUTED)');
  }

  // ── Teardown ──────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    await stopTransmitting();
    _beaconTimer?.cancel();
    _beaconTimer = null;

    if (_discoverySocket != null && _connectedPeers.isNotEmpty) {
      final leaveMsg = utf8.encode(jsonEncode({'type': 'leave', 'id': _localId}));
      _discoverySocket?.send(leaveMsg, InternetAddress('255.255.255.255'), discoveryPort);
    }

    _connectedPeers.clear();
    _discoveredTours.clear();
    _peerListCtrl.add([]);
    _discoveredCtrl.add([]);
  }

  Future<void> dispose() async {
    await disconnect();
    _discoverySocket?.close();
    _audioSocket?.close();
    _discoverySocket = null;
    _audioSocket = null;
    await _player?.stopPlayer();
    await _player?.closePlayer();
    _player = null;
    _isInitialized = false;
  }

  static String _randomId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  }
}
