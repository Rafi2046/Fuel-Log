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

class P2PJoinRequest {
  const P2PJoinRequest({
    required this.riderId,
    required this.riderName,
    required this.address,
    required this.tourCode,
  });

  final String riderId;
  final String riderName;
  final InternetAddress address;
  final String tourCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is P2PJoinRequest && runtimeType == other.runtimeType && riderId == other.riderId;

  @override
  int get hashCode => riderId.hashCode;
}

/// Offline P2P Voice & Discovery Service using TCP Connection Mesh & UDP Audio.
/// Works 100% on local Wi-Fi / Hotspot with ZERO INTERNET.
class P2PVoiceService {
  P2PVoiceService._();
  static final P2PVoiceService instance = P2PVoiceService._();

  static const int tcpPort = 38888;
  static const int udpAudioPort = 38889;
  static const int sampleRate = 16000;
  static const int numChannels = 1; // mono

  // ── Networking Sockets ────────────────────────────────────────────────────
  ServerSocket? _serverSocket;
  final Map<String, Socket> _clientSockets = {};
  final Map<String, Socket> _pendingClientSockets = {};
  final Map<String, P2PJoinRequest> _pendingRequests = {};
  Socket? _hostSocket;

  RawDatagramSocket? _udpDiscoverySocket;
  RawDatagramSocket? _udpAudioSocket;
  Timer? _beaconTimer;
  Timer? _riderProbeTimer;

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
  final _joinRequestCtrl = StreamController<P2PJoinRequest?>.broadcast();
  final _joinResponseCtrl = StreamController<bool>.broadcast();

  Stream<List<P2PPeer>> get connectedPeers => _peerListCtrl.stream;
  Stream<List<P2PPeer>> get discoveredTours => _discoveredCtrl.stream;
  Stream<P2PJoinRequest?> get joinRequests => _joinRequestCtrl.stream;
  Stream<bool> get joinResponses => _joinResponseCtrl.stream;

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
      InternetAddress('172.20.10.1'),    // iOS Hotspot Host
      InternetAddress('172.20.10.255'),  // iOS Hotspot Subnet
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
            targets.add(InternetAddress('$prefix.1'));   // Gateway router / host
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

      await _getAllBroadcastAndGatewayTargets();

      // 2. Setup UDP Discovery Socket for beacons & probes
      _udpDiscoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        tcpPort,
        reuseAddress: true,
        reusePort: true,
      );
      _udpDiscoverySocket!.broadcastEnabled = true;
      _udpDiscoverySocket!.listen(_handleUdpDiscovery);

      // 3. Setup UDP Audio Socket
      _udpAudioSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpAudioPort,
        reuseAddress: true,
        reusePort: true,
      );
      _udpAudioSocket!.broadcastEnabled = true;
      _udpAudioSocket!.listen(_handleUdpAudio);

      // 4. Setup Audio Player
      await _initAudioPlayer();

      _isInitialized = true;
      debugPrint('[P2PVoiceService] Network & Audio initialized.');
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
      debugPrint('[P2PVoiceService] Player init error: $e');
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
    } catch (e) {
      debugPrint('[P2PVoiceService] startPlayerFromStream: $e');
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
    _pendingClientSockets.clear();
    _pendingRequests.clear();

    await init(localId: _localId.isEmpty ? _randomId() : _localId, localName: hostName);

    // 1. Start TCP Server Socket
    try {
      _serverSocket?.close();
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort, shared: true);
      _serverSocket!.listen(_handleIncomingClient);
      debugPrint('[P2PVoiceService] TCP Server listening on port $tcpPort');
    } catch (e) {
      debugPrint('[P2PVoiceService] ServerSocket bind error: $e');
    }

    // 2. Broadcast UDP beacon every 1.5s
    _beaconTimer?.cancel();
    _beaconTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _broadcastBeacon();
    });

    _peerListCtrl.add([]);
    debugPrint('[P2PVoiceService] Hosting tour "$tourName" [$tourCode]');
  }

  void _handleIncomingClient(Socket client) {
    debugPrint('[P2PVoiceService] Incoming TCP connection from ${client.remoteAddress.address}:${client.remotePort}');

    String buffer = '';
    client.listen(
      (data) {
        // Check if message is audio or JSON text
        if (data.length > 6 && data[0] == 0xFE && data[1] == 0x01) {
          final pcm = data.sublist(6);
          _playIncomingAudio(pcm);
          // Forward to other connected clients
          for (final entry in _clientSockets.entries) {
            if (entry.value != client) {
              try { entry.value.add(data); } catch (_) {}
            }
          }
          return;
        }

        try {
          buffer += utf8.decode(data, allowMalformed: true);
          final lines = buffer.split('\n');
          buffer = lines.last; // keep remainder

          for (int i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            final json = jsonDecode(line) as Map<String, dynamic>;
            final type = json['type'] as String?;
            final peerId = json['id'] as String?;
            final riderName = json['name'] as String? ?? 'Rider';

            if (type == 'join' && peerId != null) {
              final req = P2PJoinRequest(
                riderId: peerId,
                riderName: riderName,
                address: client.remoteAddress,
                tourCode: _currentTourCode,
              );
              _pendingClientSockets[peerId] = client;
              _pendingRequests[peerId] = req;
              _joinRequestCtrl.add(req);
              debugPrint('[P2PVoiceService] Join request received from $riderName ($peerId). Asking host approval.');
            }
          }
        } catch (e) {
          debugPrint('[P2PVoiceService] Error handling client data: $e');
        }
      },
      onDone: () {
        _connectedPeers.removeWhere((_, p) => p.address == client.remoteAddress);
        _pendingClientSockets.removeWhere((_, s) => s == client);
        _peerListCtrl.add(_connectedPeers.values.toList());
        _broadcastMemberSync();
      },
      onError: (_) {
        _connectedPeers.removeWhere((_, p) => p.address == client.remoteAddress);
        _pendingClientSockets.removeWhere((_, s) => s == client);
        _peerListCtrl.add(_connectedPeers.values.toList());
      },
    );
  }

  /// HOST: Accept Join Request
  Future<void> acceptJoinRequest(P2PJoinRequest req) async {
    final client = _pendingClientSockets.remove(req.riderId);
    _pendingRequests.remove(req.riderId);
    _joinRequestCtrl.add(null);

    final rider = P2PPeer(
      id: req.riderId,
      name: req.riderName,
      address: req.address,
      tourName: _currentTourName,
      tourCode: _currentTourCode,
      isHost: false,
    );
    _connectedPeers[req.riderId] = rider;
    _peerListCtrl.add(_connectedPeers.values.toList());

    final acceptMsg = jsonEncode({
      'type': 'accept',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    }) + '\n';
    final acceptBytes = utf8.encode(acceptMsg);

    // 1. Send via TCP client socket
    if (client != null) {
      _clientSockets[req.riderId] = client;
      try { client.add(acceptBytes); } catch (_) {}
    }

    // 2. Also send via UDP datagram directly to Rider's IP & Broadcast
    try {
      _udpDiscoverySocket?.send(acceptBytes, req.address, tcpPort);
    } catch (_) {}
    for (final addr in _cachedBroadcastTargets) {
      try { _udpDiscoverySocket?.send(acceptBytes, addr, tcpPort); } catch (_) {}
    }

    _broadcastMemberSync();
    debugPrint('[P2PVoiceService] Host ACCEPTED rider ${req.riderName} (${req.address.address})!');
  }

  /// HOST: Decline Join Request
  Future<void> declineJoinRequest(P2PJoinRequest req) async {
    final client = _pendingClientSockets.remove(req.riderId);
    _pendingRequests.remove(req.riderId);
    _joinRequestCtrl.add(null);

    final declineMsg = jsonEncode({
      'type': 'decline',
      'reason': 'Host declined request',
    }) + '\n';
    final bytes = utf8.encode(declineMsg);

    if (client != null) {
      try {
        client.add(bytes);
        await Future.delayed(const Duration(milliseconds: 300));
        client.destroy();
      } catch (_) {}
    }

    try {
      _udpDiscoverySocket?.send(bytes, req.address, tcpPort);
    } catch (_) {}

    debugPrint('[P2PVoiceService] Host DECLINED rider ${req.riderName}.');
  }

  void _broadcastMemberSync() {
    final syncMsg = jsonEncode({
      'type': 'sync',
      'id': _localId,
      'tour': _currentTourName,
      'code': _currentTourCode,
      'members': _connectedPeers.values.map((p) => {
        'id': p.id,
        'name': p.name,
        'addr': p.address.address,
      }).toList(),
    }) + '\n';

    final bytes = utf8.encode(syncMsg);
    for (final client in _clientSockets.values) {
      try { client.add(bytes); } catch (_) {}
    }
    for (final addr in _cachedBroadcastTargets) {
      try { _udpDiscoverySocket?.send(bytes, addr, tcpPort); } catch (_) {}
    }
  }

  void _broadcastBeacon() async {
    if (_udpDiscoverySocket == null) return;
    final targets = await _getAllBroadcastAndGatewayTargets();
    final beacon = jsonEncode({
      'type': 'beacon',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    });
    final data = utf8.encode(beacon);
    for (final addr in targets) {
      try {
        _udpDiscoverySocket?.send(data, addr, tcpPort);
      } catch (_) {}
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

    await init(localId: _localId.isEmpty ? _randomId() : _localId, localName: _localName);

    // Dynamic targets computation
    final targets = <InternetAddress>[];
    if (tourHost.address.address != '255.255.255.255' &&
        tourHost.address.address != '0.0.0.0' &&
        !tourHost.address.isLoopback) {
      targets.add(tourHost.address);
    }
    targets.add(InternetAddress('192.168.43.1')); // Android Hotspot
    targets.add(InternetAddress('192.168.49.1')); // Wi-Fi Direct
    targets.add(InternetAddress('172.20.10.1'));  // iOS Hotspot
    for (final a in _cachedBroadcastTargets) {
      if (a.address.endsWith('.1') && !targets.contains(a)) {
        targets.add(a);
      }
    }

    // 1. Try TCP Connection across possible gateways
    for (final target in targets) {
      try {
        _hostSocket?.destroy();
        _hostSocket = await Socket.connect(target, tcpPort, timeout: const Duration(milliseconds: 1200));
        _setupHostSocketListener(_hostSocket!);
        debugPrint('[P2PVoiceService] TCP connected to host at ${target.address}:$tcpPort');
        break;
      } catch (_) {}
    }

    // 2. Continuous UDP join-request probe until accepted
    _riderProbeTimer?.cancel();
    _riderProbeTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (_connectedPeers.isNotEmpty) {
        _riderProbeTimer?.cancel();
        return;
      }
      _sendUdpJoinProbe();
    });
    _sendUdpJoinProbe();

    debugPrint('[P2PVoiceService] Sent join request for tour ${_currentTourCode}');
  }

  void _sendUdpJoinProbe() async {
    if (_udpDiscoverySocket == null) return;
    final targets = await _getAllBroadcastAndGatewayTargets();
    final probe = jsonEncode({
      'type': 'join_request',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    });
    final data = utf8.encode(probe);
    for (final addr in targets) {
      try {
        _udpDiscoverySocket?.send(data, addr, tcpPort);
      } catch (_) {}
    }
  }

  void _setupHostSocketListener(Socket socket) {
    // Send join greeting to host
    final joinMsg = jsonEncode({
      'type': 'join',
      'id': _localId,
      'name': _localName,
      'tour': _currentTourName,
      'code': _currentTourCode,
    }) + '\n';
    socket.add(utf8.encode(joinMsg));

    String buffer = '';
    socket.listen(
      (data) {
        // Audio stream packet check
        if (data.length > 6 && data[0] == 0xFE && data[1] == 0x01) {
          final pcm = data.sublist(6);
          _playIncomingAudio(pcm);
          return;
        }

        try {
          buffer += utf8.decode(data, allowMalformed: true);
          final lines = buffer.split('\n');
          buffer = lines.last;

          for (int i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            final json = jsonDecode(line) as Map<String, dynamic>;
            final type = json['type'] as String?;

            if (type == 'accept') {
              _riderProbeTimer?.cancel();
              _joinResponseCtrl.add(true);
              final hostId = json['id'] as String? ?? 'host';
              final host = P2PPeer(
                id: hostId,
                name: json['name'] as String? ?? 'Host',
                address: socket.remoteAddress,
                tourName: _currentTourName,
                tourCode: _currentTourCode,
                isHost: true,
              );
              _connectedPeers[hostId] = host;
              _peerListCtrl.add(_connectedPeers.values.toList());
              debugPrint('[P2PVoiceService] Host ACCEPTED our join request (TCP)!');
            } else if (type == 'decline') {
              _riderProbeTimer?.cancel();
              _joinResponseCtrl.add(false);
              _connectedPeers.clear();
              _peerListCtrl.add([]);
              debugPrint('[P2PVoiceService] Host DECLINED our join request.');
            } else if (type == 'sync') {
              _riderProbeTimer?.cancel();
              final hostId = json['id'] as String? ?? 'host';
              final host = P2PPeer(
                id: hostId,
                name: json['name'] as String? ?? 'Host',
                address: socket.remoteAddress,
                tourName: _currentTourName,
                tourCode: _currentTourCode,
                isHost: true,
              );
              _connectedPeers[hostId] = host;

              final membersRaw = json['members'] as List<dynamic>? ?? [];
              for (final m in membersRaw) {
                final mId = m['id'] as String?;
                if (mId != null && mId != _localId) {
                  _connectedPeers[mId] = P2PPeer(
                    id: mId,
                    name: m['name'] as String? ?? 'Rider',
                    address: socket.remoteAddress,
                    tourName: _currentTourName,
                    tourCode: _currentTourCode,
                    isHost: false,
                  );
                }
              }
              _peerListCtrl.add(_connectedPeers.values.toList());
            }
          }
        } catch (e) {
          debugPrint('[P2PVoiceService] Host socket parse error: $e');
        }
      },
      onDone: () {
        debugPrint('[P2PVoiceService] Host socket closed.');
      },
      onError: (err) {
        debugPrint('[P2PVoiceService] Host socket error: $err');
      },
    );
  }

  // ── UDP Handlers ──────────────────────────────────────────────────────────

  void _handleUdpDiscovery(RawSocketEvent event) {
    if (event == RawSocketEvent.read && _udpDiscoverySocket != null) {
      final datagram = _udpDiscoverySocket!.receive();
      if (datagram == null) return;

      try {
        final text = utf8.decode(datagram.data);
        final json = jsonDecode(text) as Map<String, dynamic>;
        final type = json['type'] as String?;
        final peerId = json['id'] as String?;

        if (peerId == null || peerId == _localId) return;

        if (type == 'beacon') {
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
        } else if (type == 'join_request' && _isHost) {
          final tourCode = (json['code'] as String?)?.toUpperCase();
          if (tourCode != null && tourCode.isNotEmpty && tourCode != _currentTourCode.toUpperCase()) {
            return;
          }

          final req = P2PJoinRequest(
            riderId: peerId,
            riderName: json['name'] as String? ?? 'Rider',
            address: datagram.address,
            tourCode: _currentTourCode,
          );
          _pendingRequests[peerId] = req;
          _joinRequestCtrl.add(req);
          debugPrint('[P2PVoiceService] UDP Join request from ${req.riderName} (${datagram.address.address}). Triggering dialog on Host!');
        } else if (type == 'accept' && !_isHost) {
          _riderProbeTimer?.cancel();
          _joinResponseCtrl.add(true);
          final hostId = json['id'] as String? ?? 'host';
          final host = P2PPeer(
            id: hostId,
            name: json['name'] as String? ?? 'Host',
            address: datagram.address,
            tourName: _currentTourName,
            tourCode: _currentTourCode,
            isHost: true,
          );
          _connectedPeers[hostId] = host;
          _peerListCtrl.add(_connectedPeers.values.toList());
          debugPrint('[P2PVoiceService] Host ACCEPTED via UDP datagram!');
        }
      } catch (_) {}
    }
  }

  void _handleUdpAudio(RawSocketEvent event) {
    if (event == RawSocketEvent.read && _udpAudioSocket != null) {
      final datagram = _udpAudioSocket!.receive();
      if (datagram == null) return;

      final data = datagram.data;
      if (data.length > 6 && data[0] == 0xFE && data[1] == 0x01) {
        final pcm = data.sublist(6);
        _playIncomingAudio(pcm);
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

    // 6-byte header: [0xFE, 0x01, 4 bytes id prefix]
    final header = Uint8List(6);
    header[0] = 0xFE;
    header[1] = 0x01;
    final prefix = utf8.encode((_localId.padRight(4)).substring(0, 4));
    header.setRange(2, 6, prefix);

    int chunkCount = 0;
    _micSub = stream.listen((chunk) {
      if (!_isTransmitting) return;
      chunkCount++;
      if (chunkCount % 50 == 0) {
        debugPrint('[P2PVoiceService] 🎙️ Audio stream active (${chunk.length} bytes)');
      }

      final packet = Uint8List(header.length + chunk.length);
      packet.setRange(0, header.length, header);
      packet.setRange(header.length, packet.length, chunk);

      // 1. Send via TCP host socket (if rider)
      if (_hostSocket != null) {
        try { _hostSocket?.add(packet); } catch (_) {}
      }

      // 2. Send via TCP client sockets (if host)
      for (final client in _clientSockets.values) {
        try { client.add(packet); } catch (_) {}
      }

      // 3. Send via UDP unicast to peer IPs
      for (final peer in _connectedPeers.values) {
        try {
          _udpAudioSocket?.send(packet, peer.address, udpAudioPort);
        } catch (_) {}
      }
    });

    debugPrint('[P2PVoiceService] ▶ TRANSMISSION STARTED');
  }

  Future<void> stopTransmitting() async {
    if (!_isTransmitting) return;
    _isTransmitting = false;
    await _micSub?.cancel();
    _micSub = null;
    await _recorder?.stop();
    debugPrint('[P2PVoiceService] ■ TRANSMISSION STOPPED');
  }

  // ── Teardown ──────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    await stopTransmitting();
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _riderProbeTimer?.cancel();
    _riderProbeTimer = null;

    _hostSocket?.destroy();
    _hostSocket = null;

    for (final client in _clientSockets.values) {
      try { client.destroy(); } catch (_) {}
    }
    _clientSockets.clear();

    for (final client in _pendingClientSockets.values) {
      try { client.destroy(); } catch (_) {}
    }
    _pendingClientSockets.clear();
    _pendingRequests.clear();

    _serverSocket?.close();
    _serverSocket = null;

    _connectedPeers.clear();
    _discoveredTours.clear();
    _peerListCtrl.add([]);
    _discoveredCtrl.add([]);
  }

  Future<void> dispose() async {
    await disconnect();
    _udpDiscoverySocket?.close();
    _udpAudioSocket?.close();
    _udpDiscoverySocket = null;
    _udpAudioSocket = null;
    await _player?.stopPlayer();
    await _player?.closePlayer();
    _player = null;
    _isInitialized = false;
  }

  static String _randomId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  }
}
