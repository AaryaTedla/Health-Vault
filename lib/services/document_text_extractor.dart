import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentTextExtractor {
  // Extract text for image/PDF documents. Returns null when extraction is unavailable.
  static Future<String?> extractTextFromFile({
    required String filePath,
    required String fileExtension,
  }) async {
    final ext = fileExtension.toLowerCase();
    final isImage = ext == 'jpg' || ext == 'jpeg' || ext == 'png';
    final isPdf = ext == 'pdf';
    if (!isImage && !isPdf) return null;

    final file = File(filePath);
    if (!await file.exists()) return null;

    if (isPdf) {
      try {
        final bytes = await file.readAsBytes();
        final document = PdfDocument(inputBytes: bytes);
        try {
          final extracted = PdfTextExtractor(document).extractText().trim();
          if (extracted.isEmpty) return null;
          return extracted;
        } finally {
          document.dispose();
        }
      } catch (_) {
        return null;
      }
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final recognizedText = await recognizer.processImage(inputImage);
      final text = recognizedText.text.trim();
      if (text.isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
