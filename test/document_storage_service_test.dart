import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_log/core/utils/document_storage_service.dart';
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
  late Directory tempDir;
  late DocumentStorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);
    storageService = const DocumentStorageService();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveDocumentFile copies file to sandboxed documents directory', () async {
    final originalFile = File('${tempDir.path}/license_test.png');
    await originalFile.writeAsString('fake_image_content');

    final savedPath = await storageService.saveDocumentFile(
      originalFile,
      docType: 'driving_license',
    );

    expect(savedPath, isNotEmpty);
    expect(savedPath, contains('e_documents'));
    expect(savedPath, contains('driving_license_'));
    expect(File(savedPath).existsSync(), isTrue);
    expect(await File(savedPath).readAsString(), equals('fake_image_content'));

    // Test file type utilities
    expect(storageService.isImage(savedPath), isTrue);
    expect(storageService.isPdf(savedPath), isFalse);
    expect(storageService.getFileExtension(savedPath), equals('.png'));

    // Test deletion
    final deleted = await storageService.deleteDocumentFile(savedPath);
    expect(deleted, isTrue);
    expect(File(savedPath).existsSync(), isFalse);
  });

  test('saveDocumentFromPath handles PDF documents and file size formatting', () async {
    final pdfFile = File('${tempDir.path}/fitness_cert.pdf');
    await pdfFile.writeAsBytes(List.generate(2048, (i) => i % 256));

    final savedPath = await storageService.saveDocumentFromPath(
      pdfFile.path,
      docType: 'fitness',
      customFileName: 'fitness_2026.pdf',
    );

    expect(storageService.isPdf(savedPath), isTrue);
    expect(storageService.isImage(savedPath), isFalse);
    expect(storageService.getFileSizeFormatted(savedPath), equals('2.0 KB'));
  });
}
