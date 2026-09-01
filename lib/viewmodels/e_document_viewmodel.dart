import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../repositories/document_repository.dart';
import 'vehicle_viewmodel.dart';

/// Provider for [DocumentRepository].
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DocumentRepository(db: db);
});

/// Reactive stream of all E-Documents in the database.
final allEDocumentsStreamProvider =
    StreamProvider.autoDispose<List<EDocument>>((ref) {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchAllDocuments();
});

/// Filter options for E-Document list (All, Vehicle, Personal, Expiring).
enum EDocumentFilterTab {
  all,
  vehicle,
  personal,
  expiring,
}

final selectedEDocumentTabProvider =
    StateProvider<EDocumentFilterTab>((ref) => EDocumentFilterTab.all);

/// Filtered E-Documents list provider based on selected tab and active vehicle.
final filteredEDocumentsProvider =
    Provider.autoDispose<List<EDocument>>((ref) {
  final docsAsync = ref.watch(allEDocumentsStreamProvider);
  final docs = docsAsync.valueOrNull ?? [];
  final activeTab = ref.watch(selectedEDocumentTabProvider);
  final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;

  final now = DateTime.now();

  return docs.where((doc) {
    switch (activeTab) {
      case EDocumentFilterTab.all:
        return true;
      case EDocumentFilterTab.vehicle:
        if (activeVehicle != null) {
          return doc.vehicleId == activeVehicle.id;
        }
        return doc.vehicleId != null;
      case EDocumentFilterTab.personal:
        return doc.vehicleId == null;
      case EDocumentFilterTab.expiring:
        if (doc.expiryDate == null) return false;
        final daysLeft = doc.expiryDate!.difference(now).inDays;
        return daysLeft <= 30; // Expired or expiring within 30 days
    }
  }).toList();
});

/// Document type presets and metadata helpers.
enum EDocumentType {
  drivingLicense('driving_license', 'Driving License'),
  taxToken('tax_token', 'Tax Token'),
  registration('registration', 'Registration / Smart Card'),
  fitness('fitness', 'Fitness Certificate'),
  insurance('insurance', 'Insurance Policy'),
  routePermit('route_permit', 'Route Permit'),
  other('other', 'Other Document');

  const EDocumentType(this.code, this.displayName);
  final String code;
  final String displayName;

  static EDocumentType fromCode(String code) {
    return EDocumentType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => EDocumentType.other,
    );
  }
}

/// Controller managing E-Document CRUD actions.
class EDocumentController {
  const EDocumentController(this._ref);
  final Ref _ref;

  DocumentRepository get _repo => _ref.read(documentRepositoryProvider);

  Future<int> addDocument({
    int? vehicleId,
    required String docType,
    required File sourceFile,
    DateTime? expiryDate,
    String? customFileName,
  }) {
    return _repo.addDocument(
      vehicleId: vehicleId,
      docType: docType,
      sourceFile: sourceFile,
      expiryDate: expiryDate,
      customFileName: customFileName,
    );
  }

  Future<int> addDocumentFromPath({
    int? vehicleId,
    required String docType,
    required String sourcePath,
    DateTime? expiryDate,
    String? customFileName,
  }) {
    return _repo.addDocumentFromPath(
      vehicleId: vehicleId,
      docType: docType,
      sourcePath: sourcePath,
      expiryDate: expiryDate,
      customFileName: customFileName,
    );
  }

  Future<bool> deleteDocument(int id) {
    return _repo.deleteDocument(id);
  }

  Future<bool> updateDocument(EDocument doc) {
    return _repo.updateDocument(doc);
  }
}

final eDocumentControllerProvider =
    Provider.autoDispose<EDocumentController>((ref) {
  return EDocumentController(ref);
});
