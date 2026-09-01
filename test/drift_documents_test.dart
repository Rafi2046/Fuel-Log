import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Drift database inserts, queries, updates, and deletes vehicle documents', () async {
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Bike',
        name: 'Yamaha FZ',
        startOdo: 500,
        capacity: 12,
        fuelType: 'Octane',
      ),
    );

    final expiryDate = DateTime.now().add(const Duration(days: 180));
    final docId = await db.insertDocument(
      VehicleDocumentsCompanion.insert(
        vehicleId: vehicleId,
        category: 'tax_token',
        title: 'Tax Token 2026',
        documentNumber: const drift.Value('DHAKA-METRO-HA-1234'),
        expiryDate: drift.Value(expiryDate),
        issuingAuthority: const drift.Value('BRTA Mirpur'),
        cost: const drift.Value(2300.0),
        note: const drift.Value('Renewed online'),
      ),
    );

    expect(docId, greaterThan(0));

    final docs = await db.getDocumentsForVehicle(vehicleId);
    expect(docs.length, equals(1));
    expect(docs.first.title, equals('Tax Token 2026'));
    expect(docs.first.category, equals('tax_token'));
    expect(docs.first.documentNumber, equals('DHAKA-METRO-HA-1234'));
    expect(docs.first.cost, equals(2300.0));
    expect(docs.first.issuingAuthority, equals('BRTA Mirpur'));

    // Test update
    final existing = docs.first;
    final updated = existing.copyWith(
      title: 'Updated Tax Token 2026',
      cost: const drift.Value(2500.0),
    );
    final updateSuccess = await db.updateDocument(updated);
    expect(updateSuccess, isTrue);

    final updatedDocs = await db.getDocumentsForVehicle(vehicleId);
    expect(updatedDocs.first.title, equals('Updated Tax Token 2026'));
    expect(updatedDocs.first.cost, equals(2500.0));

    // Test delete
    await db.deleteDocument(docId);
    final remainingDocs = await db.getDocumentsForVehicle(vehicleId);
    expect(remainingDocs.isEmpty, isTrue);
  });

  test('deleteVehicle cascades to vehicle documents', () async {
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Toyota Corolla',
        startOdo: 2000,
        capacity: 50,
        fuelType: 'Petrol',
      ),
    );

    await db.insertDocument(
      VehicleDocumentsCompanion.insert(
        vehicleId: vehicleId,
        category: 'registration',
        title: 'Registration Smart Card',
      ),
    );

    expect((await db.getDocumentsForVehicle(vehicleId)).length, equals(1));

    await db.deleteVehicle(vehicleId);
    expect((await db.getDocumentsForVehicle(vehicleId)).isEmpty, isTrue);
  });
}
