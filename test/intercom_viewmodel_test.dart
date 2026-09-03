import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/models/intercom_rider_role.dart';
import 'package:fuel_log/core/services/hardware_ptt_service.dart';
import 'package:fuel_log/core/services/intercom_session_service.dart';
import 'package:fuel_log/core/services/nearby_audio_transport.dart';
import 'package:fuel_log/viewmodels/intercom_viewmodel.dart';

class FakeHardwarePttService extends HardwarePttService {
  PttStateCallback? callback;
  bool startListeningCalled = false;
  bool stopListeningCalled = false;

  @override
  void startListening(PttStateCallback onPttStateChanged) {
    callback = onPttStateChanged;
    startListeningCalled = true;
  }

  @override
  void stopListening() {
    stopListeningCalled = true;
    callback = null;
  }
}

class FakeIntercomSessionService extends IntercomSessionService {
  int startSessionCalls = 0;
  int updateSessionCalls = 0;
  int stopSessionCalls = 0;
  IntercomRiderRole? lastRole;

  @override
  Future<void> startSession({
    required String tourName,
    required IntercomRiderRole role,
    required bool isTransmitting,
    required bool isMuted,
    required bool openMic,
  }) async {
    startSessionCalls++;
    lastRole = role;
    _sessionActive = true;
  }

  @override
  Future<void> updateSession({
    required String tourName,
    required IntercomRiderRole role,
    required bool isTransmitting,
    required bool isMuted,
    required bool openMic,
  }) async {
    updateSessionCalls++;
    lastRole = role;
  }

  @override
  Future<void> stopSession() async {
    stopSessionCalls++;
    _sessionActive = false;
  }

  bool _sessionActive = false;

  @override
  bool get isSessionActive => _sessionActive;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntercomViewModel Tests', () {
    late FakeHardwarePttService fakePttService;
    late NearbyAudioTransport fakeTransport;
    late FakeIntercomSessionService fakeSessionService;
    late IntercomViewModel viewModel;

    setUp(() {
      fakePttService = FakeHardwarePttService();
      fakeTransport = NearbyAudioTransport.createForTesting();
      fakeSessionService = FakeIntercomSessionService();
      viewModel = IntercomViewModel(
        fakePttService,
        fakeTransport,
        fakeSessionService,
      );
    });

    test('initial state has default tactical settings', () {
      final state = viewModel.state;
      expect(state.isTransmitting, isFalse);
      expect(state.isWindNoiseCancellationEnabled, isTrue);
      expect(state.isHelmetAudioRouteEnabled, isTrue);
      expect(state.isMeshBridgeEnabled, isTrue);
      expect(state.isFecRecoveryEnabled, isTrue);
      expect(state.isLoudspeakerEnabled, isFalse);
      expect(state.riderRole, IntercomRiderRole.groupRider);
      expect(state.isMuted, isFalse);
      expect(state.tourName, equals('My Tour'));
      expect(state.members.length, equals(1));
      expect(state.members.first.isCurrentUser, isTrue);
      expect(state.onlineCount, equals(1));
      expect(state.isHost, isFalse);
      expect(state.joinCode, isNull);
    });

    test('generateJoinCode produces valid 6-char uppercase alphanumeric codes', () {
      final code = IntercomViewModel.generateJoinCode();
      expect(code.length, equals(6));
      expect(RegExp(r'^[A-Z2-9]+$').hasMatch(code), isTrue);
    });

    test('setTourCodeAndName updates state with host flag', () {
      viewModel.setTourCodeAndName(tourName: 'Test Tour', joinCode: 'ABC123');
      expect(viewModel.state.tourName, equals('Test Tour'));
      expect(viewModel.state.joinCode, equals('ABC123'));
      expect(viewModel.state.isHost, isTrue);
    });

    test('toggleWindNoiseCancellation updates state and transport', () async {
      await viewModel.toggleWindNoiseCancellation(false);
      expect(viewModel.state.isWindNoiseCancellationEnabled, isFalse);
      expect(
        fakeTransport.audioSettings.windNoiseFilterEnabled,
        isFalse,
      );
      await viewModel.toggleWindNoiseCancellation(true);
      expect(viewModel.state.isWindNoiseCancellationEnabled, isTrue);
      expect(fakeTransport.audioSettings.windNoiseFilterEnabled, isTrue);
    });

    test('toggleHelmetAudioRoute updates state and transport', () async {
      await viewModel.toggleHelmetAudioRoute(false);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isFalse);
      expect(fakeTransport.audioSettings.helmetAudioRouteEnabled, isFalse);
      await viewModel.toggleHelmetAudioRoute(true);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isTrue);
      expect(fakeTransport.audioSettings.helmetAudioRouteEnabled, isTrue);
    });

    test('toggleMeshBridge updates state and transport', () async {
      await viewModel.toggleMeshBridge(false);
      expect(viewModel.state.isMeshBridgeEnabled, isFalse);
      expect(fakeTransport.audioSettings.meshBridgeEnabled, isFalse);
      await viewModel.toggleMeshBridge(true);
      expect(viewModel.state.isMeshBridgeEnabled, isTrue);
      expect(fakeTransport.audioSettings.meshBridgeEnabled, isTrue);
    });

    test('toggleFecRecovery updates state and transport', () async {
      await viewModel.toggleFecRecovery(false);
      expect(viewModel.state.isFecRecoveryEnabled, isFalse);
      expect(fakeTransport.audioSettings.fecRecoveryEnabled, isFalse);
      await viewModel.toggleFecRecovery(true);
      expect(viewModel.state.isFecRecoveryEnabled, isTrue);
      expect(fakeTransport.audioSettings.fecRecoveryEnabled, isTrue);
    });

    test('toggleLoudspeaker updates state and transport', () async {
      await viewModel.toggleLoudspeaker(true);
      expect(viewModel.state.isLoudspeakerEnabled, isTrue);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isFalse);
      expect(fakeTransport.audioSettings.loudspeakerEnabled, isTrue);
      await viewModel.toggleLoudspeaker(false);
      expect(viewModel.state.isLoudspeakerEnabled, isFalse);
      expect(fakeTransport.audioSettings.loudspeakerEnabled, isFalse);
    });

    test('setRiderRole applies driver preset', () async {
      await viewModel.setRiderRole(IntercomRiderRole.sameBikeDriver);
      expect(viewModel.state.riderRole, IntercomRiderRole.sameBikeDriver);
      expect(viewModel.state.isLoudspeakerEnabled, isFalse);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isTrue);
      expect(viewModel.state.isOpenMic, isTrue);
      expect(fakeTransport.audioSettings.riderRole,
          IntercomRiderRole.sameBikeDriver);
    });

    test('setRiderRole applies pillion preset', () async {
      await viewModel.setRiderRole(IntercomRiderRole.sameBikePillion);
      expect(viewModel.state.riderRole, IntercomRiderRole.sameBikePillion);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isTrue);
      expect(viewModel.state.isLoudspeakerEnabled, isFalse);
      expect(viewModel.state.isOpenMic, isTrue);
      expect(fakeTransport.audioSettings.pillionModeEnabled, isTrue);
    });

    test('toggleCoRiderMode maps to driver role', () async {
      await viewModel.toggleCoRiderMode(true);
      expect(viewModel.state.riderRole, IntercomRiderRole.sameBikeDriver);
      await viewModel.toggleCoRiderMode(false);
      expect(viewModel.state.riderRole, IntercomRiderRole.groupRider);
    });

    test('toggleMute toggles mute state', () async {
      expect(viewModel.state.isMuted, isFalse);
      await viewModel.toggleMute();
      expect(viewModel.state.isMuted, isTrue);
      await viewModel.toggleMute();
      expect(viewModel.state.isMuted, isFalse);
    });

    test('setTourName updates tour name', () {
      viewModel.setTourName('Sylhet Highway Ride');
      expect(viewModel.state.tourName, equals('Sylhet Highway Ride'));
    });

    test('leaveIntercom stops hardware button listener and resets state', () async {
      await viewModel.leaveIntercom();
      expect(fakePttService.stopListeningCalled, isTrue);
      expect(fakeSessionService.stopSessionCalls, equals(1));
      expect(viewModel.state.isTransmitting, isFalse);
    });
  });
}
