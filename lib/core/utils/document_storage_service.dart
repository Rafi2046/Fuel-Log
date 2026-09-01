import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for managing local document and certificate files (images & PDFs)
/// in the app's sandboxed internal document directory.
class DocumentStorageService {
  const DocumentStorageService();

  static const String _documentsDirName = 'e_documents';

  /// Resolves and ensures the internal directory for saved documents exists.
  Future<Directory> getDocumentDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory(p.join(appDir.path, _documentsDirName));
    if (!docDir.existsSync()) {
      await docDir.create(recursive: true);
    }
    return docDir;
  }

  /// Copies a picked file (from ImagePicker or FilePicker) into the app's
  /// private documents directory so it persists even if removed from gallery/downloads.
  /// Returns the permanent local absolute file path.
  Future<String> saveDocumentFile(
    File sourceFile, {
    String? customFileName,
    String? docType,
  }) async {
    final targetDir = await getDocumentDirectory();
    final extension = p.extension(sourceFile.path);

    final String fileName;
    if (customFileName != null && customFileName.isNotEmpty) {
      final cleanName = p.basenameWithoutExtension(customFileName);
      fileName = '${docType != null ? '${docType}_' : ''}${DateTime.now().millisecondsSinceEpoch}_$cleanName$extension';
    } else {
      final baseName = p.basenameWithoutExtension(sourceFile.path);
      fileName = '${docType != null ? '${docType}_' : ''}${DateTime.now().millisecondsSinceEpoch}_$baseName$extension';
    }

    final targetPath = p.join(targetDir.path, fileName);
    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }

  /// Helper taking a file path string (from ImagePicker/FilePicker), copying it
  /// to internal storage and returning the new permanent local path.
  Future<String> saveDocumentFromPath(
    String sourcePath, {
    String? customFileName,
    String? docType,
  }) async {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw FileNotFoundException('Source document file does not exist at $sourcePath');
    }
    return saveDocumentFile(
      file,
      customFileName: customFileName,
      docType: docType,
    );
  }

  /// Retrieves a [File] handle for a given path.
  File getFile(String filePath) {
    return File(filePath);
  }

  /// Checks if the file exists on the local filesystem.
  bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  /// Safely deletes the internal document file from storage.
  Future<bool> deleteDocumentFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns file extension in lowercase (e.g. '.pdf', '.jpg', '.png').
  String getExtension(String filePath) {
    return p.extension(filePath).toLowerCase();
  }

  /// Alias for [getExtension].
  String getFileExtension(String filePath) => getExtension(filePath);

  /// Checks if file is a PDF document.
  bool isPdf(String filePath) {
    return getExtension(filePath) == '.pdf';
  }

  /// Checks if file is an image (jpg, jpeg, png, webp, heic).
  bool isImage(String filePath) {
    final ext = getExtension(filePath);
    return ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.webp' ||
        ext == '.heic';
  }

  /// Returns human-readable file size (e.g. '1.2 MB', '450 KB').
  String getFileSizeFormatted(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return '0 KB';

    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileNotFoundException implements Exception {
  final String message;
  const FileNotFoundException(this.message);

  @override
  String toString() => 'FileNotFoundException: $message';
}
