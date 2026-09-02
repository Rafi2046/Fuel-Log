import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/services/hardware_ptt_service.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntercomViewModel Tests', () {
    late FakeHardwarePttService fakePttService;
    late IntercomViewModel viewModel;

    setUp(() {
      fakePttService = FakeHardwarePttService();
      viewModel = IntercomViewModel(fakePttService);
    });

    test('initial state has default tactical settings', () {
      final state = viewModel.state;
      expect(state.isTransmitting, isFalse);
      expect(state.isWindNoiseCancellationEnabled, isTrue);
      expect(state.isHelmetAudioRouteEnabled, isTrue);
      expect(state.isMeshBridgeEnabled, isTrue);
      expect(state.isMuted, isFalse);
      expect(state.tourName, equals('My Tour'));
      // Only local user (YOU) before any peers connect
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

    test('toggleWindNoiseCancellation updates state', () async {
      await viewModel.toggleWindNoiseCancellation(false);
      expect(viewModel.state.isWindNoiseCancellationEnabled, isFalse);
      await viewModel.toggleWindNoiseCancellation(true);
      expect(viewModel.state.isWindNoiseCancellationEnabled, isTrue);
    });

    test('toggleHelmetAudioRoute updates state', () async {
      await viewModel.toggleHelmetAudioRoute(false);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isFalse);
      await viewModel.toggleHelmetAudioRoute(true);
      expect(viewModel.state.isHelmetAudioRouteEnabled, isTrue);
    });

    test('toggleMeshBridge updates state', () {
      viewModel.toggleMeshBridge(false);
      expect(viewModel.state.isMeshBridgeEnabled, isFalse);
      viewModel.toggleMeshBridge(true);
      expect(viewModel.state.isMeshBridgeEnabled, isTrue);
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
      expect(viewModel.state.isTransmitting, isFalse);
    });
  });
}
