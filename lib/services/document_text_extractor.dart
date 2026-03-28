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

  static Map<String, String> extractStructuredFields(String text) {
    final normalized = text.replaceAll('\r', ' ');
    String? firstMatch(RegExp re) {
      final match = re.firstMatch(normalized);
      if (match == null) return null;
      if (match.groupCount >= 1) {
        return match.group(1)?.trim();
      }
      return match.group(0)?.trim();
    }

    final doctor = firstMatch(RegExp(r'(?:Dr\.?\s+)([A-Za-z .]{3,40})'));
    final patient = firstMatch(RegExp(r'(?:Patient(?:\s*Name)?[:\-]\s*)([A-Za-z .]{3,40})', caseSensitive: false));
    final bp = firstMatch(RegExp(r'\b(\d{2,3}\s*/\s*\d{2,3})\b'));
    final sugar = firstMatch(RegExp(r'(?:glucose|sugar)[^\d]{0,20}(\d{2,3})', caseSensitive: false));
    final hemoglobin = firstMatch(RegExp(r'(?:hemoglobin|hb)[^\d]{0,20}(\d{1,2}\.?\d{0,2})', caseSensitive: false));
    final date = firstMatch(RegExp(r'\b(\d{1,2}[\-/]\d{1,2}[\-/]\d{2,4})\b'));

    final output = <String, String>{};
    if (patient != null && patient.isNotEmpty) output['patientName'] = patient;
    if (doctor != null && doctor.isNotEmpty) output['doctorName'] = doctor;
    if (date != null && date.isNotEmpty) output['reportDate'] = date;
    if (bp != null && bp.isNotEmpty) output['bloodPressure'] = bp;
    if (sugar != null && sugar.isNotEmpty) output['glucose'] = sugar;
    if (hemoglobin != null && hemoglobin.isNotEmpty) output['hemoglobin'] = hemoglobin;
    return output;
  }
}
