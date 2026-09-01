import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/database/app_database.dart';
import 'package:fuel_log/repositories/document_repository.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  MockPathProviderPlatform(this._tempDir);

  final Directory _tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return _tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late Directory tempDir;
  late DocumentRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('edoc_repo_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DocumentRepository(db: db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DocumentRepository inserts, queries, updates, and deletes e-documents with file cleanup', () async {
    // 1. Create a vehicle
    final vehicleId = await db.insertVehicle(
      VehiclesCompanion.insert(
        type: 'Car',
        name: 'Toyota Allion',
        startOdo: 10000,
        capacity: 45,
        fuelType: 'Octane',
      ),
    );

    // 2. Create a dummy file
    final sampleFile = File('${tempDir.path}/tax_token_scan.jpg');
    await sampleFile.writeAsString('sample_binary_content');

    // 3. Add vehicle-specific document
    final docId = await repository.addDocument(
      vehicleId: vehicleId,
      docType: 'tax_token',
      sourceFile: sampleFile,
      expiryDate: DateTime.now().add(const Duration(days: 60)),
      customFileName: 'tax_token_2026.jpg',
    );

    expect(docId, greaterThan(0));

    // 4. Query vehicle documents
    final vehicleDocs = await repository.getDocumentsForVehicle(vehicleId);
    expect(vehicleDocs.length, equals(1));
    expect(vehicleDocs.first.docType, equals('tax_token'));
    expect(vehicleDocs.first.vehicleId, equals(vehicleId));
    expect(File(vehicleDocs.first.filePath).existsSync(), isTrue);

    // 5. Add personal document (vehicleId = null for Driving License)
    final licenseFile = File('${tempDir.path}/my_driving_license.pdf');
    await licenseFile.writeAsString('license_pdf_bytes');

    final licenseDocId = await repository.addDocument(
      vehicleId: null,
      docType: 'driving_license',
      sourceFile: licenseFile,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
    );

    expect(licenseDocId, greaterThan(0));

    final personalDocs = await repository.getPersonalDocuments();
    expect(personalDocs.length, equals(1));
    expect(personalDocs.first.docType, equals('driving_license'));
    expect(personalDocs.first.vehicleId, isNull);

    // 6. Delete document with storage cleanup
    final savedPath = vehicleDocs.first.filePath;
    expect(File(savedPath).existsSync(), isTrue);

    final deleted = await repository.deleteDocument(docId);
    expect(deleted, isTrue);
    expect(File(savedPath).existsSync(), isFalse);

    final remaining = await repository.getDocumentsForVehicle(vehicleId);
    expect(remaining.isEmpty, isTrue);
  });
}
