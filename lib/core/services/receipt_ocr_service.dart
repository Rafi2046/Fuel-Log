import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/receipt_parser.dart';

export '../utils/receipt_parser.dart';

/// Service managing camera/gallery image capture and Google ML Kit on-device OCR.
class ReceiptOcrService {
  ReceiptOcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Captures or picks an image and performs on-device OCR text recognition.
  Future<ReceiptData?> scanReceipt({
    required ImageSource source,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (file == null) {
        return null;
      }

      final inputImage = InputImage.fromFilePath(file.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final recognizedText = await textRecognizer.processImage(inputImage);
        final raw = recognizedText.text;

        debugPrint('--- [Receipt OCR Raw Text] ---\n$raw\n------------------------------');

        return ReceiptParser.parse(raw);
      } finally {
        await textRecognizer.close();
      }
    } catch (e, stack) {
      debugPrint('Error during receipt OCR: $e\n$stack');
      rethrow;
    }
  }
}
