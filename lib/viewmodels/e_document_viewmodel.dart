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

/// Filter options for E-Document list (All, Valid, Expiring Soon, Expired).
enum EDocumentFilterTab {
  all,
  valid,
  expiring,
  expired,
}

final selectedEDocumentTabProvider =
    StateProvider<EDocumentFilterTab>((ref) => EDocumentFilterTab.all);

/// Selected vehicle filter for E-Document list:
/// null = All vehicles & personal
/// -1 = Personal documents only (vehicleId == null)
/// int = Specific vehicleId
final selectedEDocumentVehicleFilterProvider =
    StateProvider<int?>((ref) => null);

/// Filtered E-Documents list provider based on selected status KPI tab & vehicle filter.
final filteredEDocumentsProvider =
    Provider.autoDispose<List<EDocument>>((ref) {
  final docsAsync = ref.watch(allEDocumentsStreamProvider);
  final docs = docsAsync.valueOrNull ?? [];
  final activeTab = ref.watch(selectedEDocumentTabProvider);
  final vehicleFilter = ref.watch(selectedEDocumentVehicleFilterProvider);

  final now = DateTime.now();

  return docs.where((doc) {
    // 1. Vehicle filter
    if (vehicleFilter != null) {
      if (vehicleFilter == -1) {
        if (doc.vehicleId != null) return false;
      } else {
        if (doc.vehicleId != vehicleFilter) return false;
      }
    }

    // 2. Status tab filter
    switch (activeTab) {
      case EDocumentFilterTab.all:
        return true;
      case EDocumentFilterTab.valid:
        if (doc.expiryDate == null) return true; // Lifetime
        return !doc.expiryDate!.isBefore(now);
      case EDocumentFilterTab.expiring:
        if (doc.expiryDate == null) return false;
        final daysLeft = doc.expiryDate!.difference(now).inDays;
        return !doc.expiryDate!.isBefore(now) && daysLeft <= 30;
      case EDocumentFilterTab.expired:
        if (doc.expiryDate == null) return false;
        return doc.expiryDate!.isBefore(now);
    }
  }).toList();
});

/// Document type presets and metadata helpers.
enum EDocumentType {
  drivingLicense('driving_license', 'Driving License'),
  nationalId('nid', 'NID Card (National ID)'),
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
