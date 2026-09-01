import 'dart:io';
import 'package:drift/drift.dart' as drift;

import '../core/database/app_database.dart';
import '../core/utils/document_storage_service.dart';

/// Repository coordinating [AppDatabase] E-Documents table and [DocumentStorageService].
class DocumentRepository {
  const DocumentRepository({
    required AppDatabase db,
    DocumentStorageService storageService = const DocumentStorageService(),
  })  : _db = db,
        _storage = storageService;

  final AppDatabase _db;
  final DocumentStorageService _storage;

  /// Saves a document by copying its source file into sandboxed storage and inserting its metadata into Drift DB.
  Future<int> addDocument({
    int? vehicleId,
    required String docType,
    required File sourceFile,
    DateTime? expiryDate,
    String? customFileName,
  }) async {
    final persistentPath = await _storage.saveDocumentFile(
      sourceFile,
      customFileName: customFileName,
      docType: docType,
    );

    final companion = EDocumentsCompanion.insert(
      vehicleId: drift.Value(vehicleId),
      docType: docType,
      filePath: persistentPath,
      expiryDate: drift.Value(expiryDate),
    );

    return _db.insertEDocument(companion);
  }

  /// Saves a document from an existing path (e.g. from FilePicker/ImagePicker result).
  Future<int> addDocumentFromPath({
    int? vehicleId,
    required String docType,
    required String sourcePath,
    DateTime? expiryDate,
    String? customFileName,
  }) async {
    final file = File(sourcePath);
    return addDocument(
      vehicleId: vehicleId,
      docType: docType,
      sourceFile: file,
      expiryDate: expiryDate,
      customFileName: customFileName,
    );
  }

  /// Retrieves all stored documents.
  Future<List<EDocument>> getAllDocuments() => _db.getAllEDocuments();

  /// Watches all documents as a reactive stream.
  Stream<List<EDocument>> watchAllDocuments() => _db.watchAllEDocuments();

  /// Retrieves documents for a specific vehicle (or personal documents if null).
  Future<List<EDocument>> getDocumentsForVehicle(int? vehicleId) =>
      _db.getEDocumentsForVehicle(vehicleId);

  /// Watches documents for a specific vehicle.
  Stream<List<EDocument>> watchDocumentsForVehicle(int? vehicleId) =>
      _db.watchEDocumentsForVehicle(vehicleId);

  /// Retrieves personal user documents (e.g. Driving License, NID).
  Future<List<EDocument>> getPersonalDocuments() => _db.getPersonalEDocuments();

  /// Watches personal user documents.
  Stream<List<EDocument>> watchPersonalDocuments() =>
      _db.watchPersonalEDocuments();

  /// Gets documents expiring within [days] (default 30 days).
  Future<List<EDocument>> getExpiringDocuments({int days = 30}) =>
      _db.getExpiringEDocuments(days: days);

  /// Retrieves a document by ID.
  Future<EDocument?> getDocumentById(int id) => _db.getEDocumentById(id);

  /// Updates document metadata (e.g. expiry date, docType, vehicle association).
  Future<bool> updateDocument(EDocument document) =>
      _db.updateEDocument(document);

  /// Deletes document metadata from Drift DB and removes the local file from storage.
  Future<bool> deleteDocument(int id) async {
    final doc = await _db.getEDocumentById(id);
    if (doc == null) return false;

    // Delete local storage file
    await _storage.deleteDocumentFile(doc.filePath);

    // Delete DB record
    final rows = await _db.deleteEDocument(id);
    return rows > 0;
  }
}
