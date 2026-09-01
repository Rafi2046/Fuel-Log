import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/document_categories.dart';
import '../core/database/app_database.dart';
import '../core/services/vault_security_service.dart';
import 'vehicle_viewmodel.dart';

/// Provider for the security service managing the PIN lock.
final vaultSecurityServiceProvider = Provider<VaultSecurityService>((ref) {
  return const VaultSecurityService();
});

/// Tracks whether the Document Vault is currently unlocked in this active session.
final isVaultUnlockedProvider = StateProvider<bool>((ref) => false);

/// Checks if the user has already configured a security PIN.
final isVaultPinSetProvider = FutureProvider.autoDispose<bool>((ref) async {
  final service = ref.watch(vaultSecurityServiceProvider);
  return service.isPinSet();
});

/// Currently selected document category filter (null = all).
final selectedDocumentCategoryFilterProvider =
    StateProvider<DocumentCategory?>((ref) => null);

/// Filter for Personal vs Vehicle vs Expiring Soon
enum DocumentTabFilter {
  all,
  vehicle,
  personal,
  expiring,
}

final selectedDocumentTabFilterProvider =
    StateProvider<DocumentTabFilter>((ref) => DocumentTabFilter.all);

/// Stream of documents for the active vehicle (plus personal documents).
final vehicleDocumentsStreamProvider =
    StreamProvider.autoDispose<List<VehicleDocument>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeVehicle = ref.watch(activeVehicleProvider).valueOrNull;

  if (activeVehicle == null) {
    return db.watchAllDocuments();
  }
  return db.watchDocumentsForVehicle(activeVehicle.id);
});

/// Filtered list of documents based on active tab and category filter.
final filteredDocumentsProvider =
    Provider.autoDispose<List<VehicleDocument>>((ref) {
  final docsAsync = ref.watch(vehicleDocumentsStreamProvider);
  final docs = docsAsync.valueOrNull ?? [];

  final tabFilter = ref.watch(selectedDocumentTabFilterProvider);
  final categoryFilter = ref.watch(selectedDocumentCategoryFilterProvider);

  return docs.where((doc) {
    // 1. Category chip filter
    if (categoryFilter != null && doc.category != categoryFilter.code) {
      return false;
    }

    // 2. Tab filter
    final cat = DocumentCategoryX.fromCode(doc.category);
    switch (tabFilter) {
      case DocumentTabFilter.all:
        return true;
      case DocumentTabFilter.vehicle:
        return !cat.isPersonalDocument;
      case DocumentTabFilter.personal:
        return cat.isPersonalDocument;
      case DocumentTabFilter.expiring:
        final status = DocumentExpiryHelper.calculateStatus(doc.expiryDate);
        return status == DocumentExpiryStatus.expiringSoon ||
            status == DocumentExpiryStatus.expired;
    }
  }).toList();
});

/// Summary counts for Document Vault header stats
class DocumentVaultSummary {
  const DocumentVaultSummary({
    required this.totalDocs,
    required this.validDocs,
    required this.expiringSoonDocs,
    required this.expiredDocs,
  });

  final int totalDocs;
  final int validDocs;
  final int expiringSoonDocs;
  final int expiredDocs;
}

final documentVaultSummaryProvider =
    Provider.autoDispose<DocumentVaultSummary>((ref) {
  final docsAsync = ref.watch(vehicleDocumentsStreamProvider);
  final docs = docsAsync.valueOrNull ?? [];

  var valid = 0;
  var expiringSoon = 0;
  var expired = 0;

  for (final doc in docs) {
    final status = DocumentExpiryHelper.calculateStatus(doc.expiryDate);
    switch (status) {
      case DocumentExpiryStatus.valid:
        valid++;
        break;
      case DocumentExpiryStatus.expiringSoon:
        expiringSoon++;
        break;
      case DocumentExpiryStatus.expired:
        expired++;
        break;
      case DocumentExpiryStatus.noExpiry:
        valid++;
        break;
    }
  }

  return DocumentVaultSummary(
    totalDocs: docs.length,
    validDocs: valid,
    expiringSoonDocs: expiringSoon,
    expiredDocs: expired,
  );
});

/// Controller handling CRUD operations and PIN lock flows.
class DocumentVaultController {
  DocumentVaultController(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(databaseProvider);
  VaultSecurityService get _security => _ref.read(vaultSecurityServiceProvider);

  Future<int> addDocument(VehicleDocumentsCompanion doc) {
    return _db.insertDocument(doc);
  }

  Future<bool> updateDocument(VehicleDocument doc) {
    return _db.updateDocument(doc);
  }

  Future<int> deleteDocument(int id) {
    return _db.deleteDocument(id);
  }

  Future<bool> unlockWithPin(String pin) async {
    final isValid = await _security.verifyPin(pin);
    if (isValid) {
      _ref.read(isVaultUnlockedProvider.notifier).state = true;
    }
    return isValid;
  }

  void lockVault() {
    _ref.read(isVaultUnlockedProvider.notifier).state = false;
  }

  Future<void> setupPin(String pin) async {
    await _security.setPin(pin);
    _ref.read(isVaultUnlockedProvider.notifier).state = true;
    _ref.invalidate(isVaultPinSetProvider);
  }

  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final success = await _security.changePin(oldPin: oldPin, newPin: newPin);
    if (success) {
      _ref.invalidate(isVaultPinSetProvider);
    }
    return success;
  }
}

final documentVaultControllerProvider =
    Provider.autoDispose<DocumentVaultController>((ref) {
  return DocumentVaultController(ref);
});
