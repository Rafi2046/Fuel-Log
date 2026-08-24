import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/services/fuel_price_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FuelPriceRepository Tests', () {
    test('loads default baseline Bangladesh stations', () async {
      final repo = FuelPriceRepository.instance;
      final stations = await repo.getStations();

      expect(stations, isNotEmpty);
      expect(
        stations.any((s) => s.displayName.contains('সুমাত্রা') || s.name.contains('Sumatra')),
        isTrue,
      );
    });

    test('updates fuel price and persists across reloads', () async {
      final repo = FuelPriceRepository.instance;
      final initialStations = await repo.getStations();
      final target = initialStations.first;

      // Update Octane 95 price to 148.50
      await repo.updateStationPrice(
        stationId: target.id,
        fuelGradeCode: '95',
        newPrice: 148.50,
        updatedBy: 'Rafi',
      );

      final reloaded = await repo.getStations();
      final updatedStation = reloaded.firstWhere((s) => s.id == target.id);
      final priceEntry = updatedStation.prices.firstWhere((p) => p.fuelGradeCode == '95');

      expect(priceEntry.price, 148.50);
      expect(priceEntry.updatedBy, 'Rafi');
      expect(priceEntry.isCrowdSourced, isTrue);
    });

    test('toggles favorite and upvotes correctly', () async {
      final repo = FuelPriceRepository.instance;
      final initialStations = await repo.getStations();
      final target = initialStations.first;

      // Toggle favorite
      final isFav = await repo.toggleFavorite(target.id);
      expect(isFav, isTrue);

      var reloaded = await repo.getStations();
      expect(reloaded.firstWhere((s) => s.id == target.id).isFavorite, isTrue);

      // Toggle upvote
      final isUp = await repo.toggleUpvote(target.id);
      expect(isUp, isTrue);

      reloaded = await repo.getStations();
      final afterUpvote = reloaded.firstWhere((s) => s.id == target.id);
      expect(afterUpvote.isUserUpvoted, isTrue);
      expect(afterUpvote.upvotes, target.upvotes + 1);
    });
  });
}
