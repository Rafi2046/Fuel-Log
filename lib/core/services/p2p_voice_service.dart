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
  Timer? _heartbeatTimer;

  String _localId = '';
  String _localName = 'Rider';
  String _currentTourName = '';
  String _currentTourCode = '';
  bool _isHost = false;

  final Map<String, P2PPeer> _connectedPeers = {};
  final Map<String, P2PPeer> _discoveredTours = {};
  List<InternetAddress> _cachedBroadcastTargets = [];

  // ── Audio Engine ──────────────────────────────────────────────────────────
  AudioRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamSubscription<Uint8List>? _micSub;
  bool _isPlayerStreamStarted = false;

  // ── Streams ───────────────────────────────────────────────────────────────
  final _peerListCtrl = StreamController<List<P2PPeer>>.broadcast();
  final _discoveredCtrl = StreamController<List<P2PPeer>>.broadcast();

  Stream<List<P2PPeer>> get connectedPeers => _peerListCtrl.stream;
  Stream<List<P2PPeer>> get discoveredTours => _discoveredCtrl.stream;

  List<P2PPeer> get currentPeers => _connectedPeers.values.toList();

  bool _isInitialized = false;
  bool _isTransmitting = false;

  // ── Network Discovery Targets ─────────────────────────────────────────────

  Future<List<InternetAddress>> _getAllBroadcastAndGatewayTargets() async {
    final targets = <InternetAddress>{
      InternetAddress('255.255.255.255'),
      InternetAddress('192.168.43.1'),   // Android Hotspot Host
      InternetAddress('192.168.43.255'), // Android Hotspot Subnet
      InternetAddress('192.168.49.1'),   // Wi-Fi Direct Host
      InternetAddress('192.168.49.255'), // Wi-Fi Direct Subnet
    };

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          final parts = ip.split('.');
          if (parts.length == 4) {
            final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
            targets.add(InternetAddress('$prefix.255')); // Subnet broadcast
            targets.add(InternetAddress('$prefix.1'));   // Gateway/Host router
          }
        }
      }
    } catch (_) {}

    _cachedBroadcastTargets = targets.toList();
    return _cachedBroadcastTargets;
  }

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

      // 2. Discover local IP subnets
      await _getAllBroadcastAndGatewayTargets();

      // 3. Setup UDP Discovery Socket
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );
      _discoverySocket!.broadcastEnabled = true;
      _discoverySocket!.listen(_handleDiscoveryEvent);

      // 4. Setup UDP Audio Socket
      _audioSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        audioPort,
        reuseAddress: true,
        reusePort: true,
      );
      _audioSocket!.broadcastEnabled = true;
      _audioSocket!.listen(_handleAudioEvent);

      // 5. Setup Audio Player for receiving streams
      await _initAudioPlayer();

      _isInitialized = true;
      debugPrint('[P2PVoiceService] Sockets & Audio Player initialized on ports $discoveryPort/$audioPort');
      return true;
    } catch (e) {
      debugPrint('[P2PVoiceService] Init error: $e');
      return false;
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      if (_player == null) {
        _player = FlutterSoundPlayer();
        await _player!.openPlayer();
        await _player!.setVolume(1.0);
      }
      await _startPlayerStream();
    } catch (e) {
      debugPrint('[P2PVoiceService] Player init warning: $e');
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
      debugPrint('[P2PVoiceService] Audio playback stream started.');
    } catch (e) {
      debugPrint('[P2PVoiceService] startPlayerFromStream error: $e');
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

    // Periodically broadcast tour beacon + member sync across the LAN/Hotspot
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _broadcastBeaconAndSync();
    });

    _peerListCtrl.add([]);
    debugPrint('[P2PVoiceService] Hosting tour "$tourName" [$tourCode]');
  }

  void _broadcastBeaconAndSync() async {
    if (_discoverySocket == null) return;

    // Refresh targets periodically
    final targets = await _getAllBroadcastAndGatewayTargets();

    // 1. Tour Beacon
    final beacon = jsonEncode({
      'type': 'beacon',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    });
    final beaconData = utf8.encode(beacon);
    for (final addr in targets) {
      try {
        _discoverySocket?.send(beaconData, addr, discoveryPort);
      } catch (_) {}
    }

    // 2. Member Sync (so all riders have the full live list)
    if (_connectedPeers.isNotEmpty) {
      final sync = jsonEncode({
        'type': 'sync',
        'id': _localId,
        'tour': _currentTourName,
        'code': _currentTourCode,
        'members': _connectedPeers.values.map((p) => {
          'id': p.id,
          'name': p.name,
          'addr': p.address.address,
        }).toList(),
      });
      final syncData = utf8.encode(sync);
      for (final peer in _connectedPeers.values) {
        try {
          _discoverySocket?.send(syncData, peer.address, discoveryPort);
        } catch (_) {}
      }
      for (final addr in targets) {
        try {
          _discoverySocket?.send(syncData, addr, discoveryPort);
        } catch (_) {}
      }
    }
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
    _isHost = false;
    _currentTourName = tourHost.tourName;
    _currentTourCode = tourHost.tourCode;
    _connectedPeers[tourHost.id] = tourHost;

    await init(localId: _localId.isEmpty ? _randomId() : _localId, localName: _localName);

    // Send join packet repeatedly to host & broadcast
    _sendJoinPackets(tourHost);

    // Keep heartbeat active so host knows we are online
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      _sendJoinPackets(tourHost);
    });

    _peerListCtrl.add(_connectedPeers.values.toList());
    debugPrint('[P2PVoiceService] Joined tour: ${tourHost.tourName} (${tourHost.address.address})');
  }

  void _sendJoinPackets(P2PPeer tourHost) async {
    if (_discoverySocket == null) return;
    final msg = jsonEncode({
      'type': 'join',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    });
    final data = utf8.encode(msg);

    // Direct unicast to host IP
    try {
      _discoverySocket?.send(data, tourHost.address, discoveryPort);
    } catch (_) {}

    // Send to all computed broadcast and gateway targets
    final targets = await _getAllBroadcastAndGatewayTargets();
    for (final addr in targets) {
      try {
        _discoverySocket?.send(data, addr, discoveryPort);
      } catch (_) {}
    }
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
          final tourCode = (json['code'] as String?)?.toUpperCase();
          if (tourCode != null && tourCode.isNotEmpty && tourCode != _currentTourCode.toUpperCase()) {
            return;
          }

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

          // Send welcome ack directly back to the rider
          final ack = jsonEncode({
            'type': 'ack',
            'id': _localId,
            'name': _localName,
            'tour': _currentTourName,
            'code': _currentTourCode,
          });
          _discoverySocket?.send(utf8.encode(ack), datagram.address, discoveryPort);
          _broadcastBeaconAndSync();
          debugPrint('[P2PVoiceService] Rider ${rider.name} registered (${datagram.address.address}). Total peers: ${_connectedPeers.length}');
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
        } else if (type == 'sync' && !_isHost) {
          // Sync full member list from host
          final membersRaw = json['members'] as List<dynamic>? ?? [];
          final host = P2PPeer(
            id: peerId,
            name: json['name'] as String? ?? 'Host (Leader)',
            address: datagram.address,
            tourName: _currentTourName,
            tourCode: _currentTourCode,
            isHost: true,
          );
          _connectedPeers[peerId] = host;

          for (final m in membersRaw) {
            final mId = m['id'] as String?;
            if (mId != null && mId != _localId) {
              final mAddr = m['addr'] as String?;
              _connectedPeers[mId] = P2PPeer(
                id: mId,
                name: m['name'] as String? ?? 'Rider',
                address: mAddr != null ? InternetAddress(mAddr) : datagram.address,
                tourName: _currentTourName,
                tourCode: _currentTourCode,
                isHost: false,
              );
            }
          }
          _peerListCtrl.add(_connectedPeers.values.toList());
        } else if (type == 'leave') {
          _connectedPeers.remove(peerId);
          _peerListCtrl.add(_connectedPeers.values.toList());
        }
      } catch (e) {
        // Skip malformed packets
      }
    }
  }

  void _handleAudioEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read && _audioSocket != null) {
      final datagram = _audioSocket!.receive();
      if (datagram == null) return;

      final data = datagram.data;
      if (data.length > 4) {
        final senderPrefix = utf8.decode(data.sublist(0, 4), allowMalformed: true);
        if (senderPrefix == _localId.substring(0, 4.clamp(0, _localId.length))) {
          return; // Ignore own audio loopback
        }
        final pcmBytes = data.sublist(4);
        _playIncomingAudio(pcmBytes);
      }
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
      debugPrint('[P2PVoiceService] Audio playback feed error: $e');
    }
  }

  // ── PTT / Live Audio Transmission ─────────────────────────────────────────

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
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
    );

    final prefixBytes = utf8.encode(
      (_localId.padRight(4)).substring(0, 4),
    );

    int chunkIndex = 0;
    _micSub = stream.listen((chunk) {
      if (_audioSocket == null || !_isTransmitting) return;
      chunkIndex++;
      if (chunkIndex % 60 == 0) {
        debugPrint('[P2PVoiceService] 🎙️ Streaming audio packet (${chunk.length} bytes)');
      }

      final packet = Uint8List(prefixBytes.length + chunk.length);
      packet.setRange(0, prefixBytes.length, prefixBytes);
      packet.setRange(prefixBytes.length, packet.length, chunk);

      // 1. Send DIRECT UNICAST to every connected peer IP
      for (final peer in _connectedPeers.values) {
        try {
          _audioSocket?.send(packet, peer.address, audioPort);
        } catch (_) {}
      }

      // 2. Send to all cached subnet targets & broadcast addresses
      for (final addr in _cachedBroadcastTargets) {
        try {
          _audioSocket?.send(packet, addr, audioPort);
        } catch (_) {}
      }
    });

    debugPrint('[P2PVoiceService] ▶ LIVE AUDIO TRANSMISSION STARTED');
  }

  Future<void> stopTransmitting() async {
    if (!_isTransmitting) return;
    _isTransmitting = false;
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    debugPrint('[P2PVoiceService] ■ AUDIO MUTED / IDLE');
  }

  // ── Teardown ──────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    await stopTransmitting();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_discoverySocket != null && _connectedPeers.isNotEmpty) {
      final leaveMsg = utf8.encode(jsonEncode({'type': 'leave', 'id': _localId}));
      for (final addr in _cachedBroadcastTargets) {
        try {
          _discoverySocket?.send(leaveMsg, addr, discoveryPort);
        } catch (_) {}
      }
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
