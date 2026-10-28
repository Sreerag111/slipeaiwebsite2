import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'cloud_function_service.dart';

/// Result of a PDF extraction operation.
class PdfExtractionResult {
  final String text;
  final int pageCount;
  final bool usedOcr;
  final String? error;

  const PdfExtractionResult({
    required this.text,
    required this.pageCount,
    this.usedOcr = false,
    this.error,
  });

  bool get hasText => text.trim().isNotEmpty;
  bool get hasError => error != null;
}

class PdfService {
  static const int _maxFileSizeMb = 50;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Extracts text from a PDF file.
  ///
  /// Strategy:
  /// 1. Validate the file (size, type, header).
  /// 2. Try native selectable-text extraction via syncfusion.
  /// 3. If no text found → OCR fallback via Cloud Functions.
  Future<PdfExtractionResult> extractText(
    String filePath,
  ) async {
    _log('Starting extraction: $filePath');

    // 1. Validate
    final validation = _validateFile(filePath);
    if (validation != null) {
      _log('Validation failed: $validation');
      return PdfExtractionResult(text: '', pageCount: 0, error: validation);
    }

    // 2. Native text extraction (background isolate so UI stays responsive)
    PdfExtractionResult nativeResult;
    try {
      nativeResult = await compute(_extractTextIsolate, filePath);
      _log('Native extraction done: ${nativeResult.text.length} chars, '
          '${nativeResult.pageCount} pages, error=${nativeResult.error}');
    } catch (e) {
      _log('compute() failed: $e');
      nativeResult = PdfExtractionResult(
        text: '',
        pageCount: 0,
        error: 'Failed to read PDF: ${_friendlyError(e)}',
      );
    }

    // If native extraction raised a hard error, return it
    if (nativeResult.hasError) return nativeResult;

    // 3. If text found, return it
    if (nativeResult.hasText) return nativeResult;

    // 4. No text → scanned PDF: try OCR via Cloud Functions
    _log('No selectable text → switching to Cloud Function OCR');
    return await _runCloudFunctionOcr(filePath, nativeResult.pageCount);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // File validation
  // ──────────────────────────────────────────────────────────────────────────

  String? _validateFile(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return 'File not found.';
    }

    final ext = filePath.split('.').last.toLowerCase();
    if (ext != 'pdf') {
      return 'Unsupported file type "$ext". Only PDF files are supported.';
    }

    final sizeBytes = file.lengthSync();
    final sizeMb = sizeBytes / (1024 * 1024);
    if (sizeMb > _maxFileSizeMb) {
      return 'File is too large '
          '(${sizeMb.toStringAsFixed(1)} MB). '
          'Maximum is $_maxFileSizeMb MB.';
    }

    if (sizeBytes < 64) {
      return 'File appears to be corrupted or empty.';
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OCR via Cloud Functions (for scanned / image-only PDFs)
  // ──────────────────────────────────────────────────────────────────────────

  Future<PdfExtractionResult> _runCloudFunctionOcr(
    String filePath,
    int pageCount,
  ) async {
    _log('Cloud Function OCR: reading file bytes');
    try {
      final bytes = File(filePath).readAsBytesSync();
      final base64Pdf = base64Encode(bytes);

      _log(
          'Cloud Function OCR: sending ${(bytes.length / 1024).toStringAsFixed(1)} KB');

      final cloudService = CloudFunctionService();
      final extracted = await cloudService.extractPdfText(
        pdfBase64: base64Pdf,
        fileName: filePath.split(Platform.pathSeparator).last,
      );

      _log('Cloud Function OCR: got ${extracted.length} chars');

      if (extracted.isEmpty) {
        return PdfExtractionResult(
          text: '',
          pageCount: pageCount,
          usedOcr: true,
          error:
              'OCR returned no text. The PDF may be encrypted or contain unsupported content.',
        );
      }
      return PdfExtractionResult(
        text: extracted,
        pageCount: pageCount,
        usedOcr: true,
      );
    } catch (e) {
      _log('Cloud Function OCR exception: $e');
      return PdfExtractionResult(
        text: '',
        pageCount: pageCount,
        usedOcr: true,
        error: 'OCR failed: ${_friendlyError(e)}',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('password') || msg.contains('encrypt')) {
      return 'This PDF is password-protected and cannot be read.';
    }
    if (msg.contains('corrupt') || msg.contains('invalid')) {
      return 'The PDF file appears to be corrupted.';
    }
    return e.toString();
  }

  void _log(String message) {
    if (kDebugMode) {
      dev.log(message, name: 'PdfService');
      // ignore: avoid_print
      print('[PdfService] $message');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Isolate-safe text extraction
// Runs on a background thread via compute() so the UI never freezes.
// ──────────────────────────────────────────────────────────────────────────

PdfExtractionResult _extractTextIsolate(String filePath) {
  try {
    final bytes = File(filePath).readAsBytesSync();

    // Quick magic-byte check for PDF header (%PDF)
    if (bytes.length < 5) {
      return const PdfExtractionResult(
        text: '',
        pageCount: 0,
        error: 'File is too small to be a valid PDF.',
      );
    }
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    if (header != '%PDF') {
      return const PdfExtractionResult(
        text: '',
        pageCount: 0,
        error: 'File is not a valid PDF (incorrect header).',
      );
    }

    final document = PdfDocument(inputBytes: bytes);
    final pageCount = document.pages.count;
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();

    for (int i = 0; i < pageCount; i++) {
      try {
        final pageText =
            extractor.extractText(startPageIndex: i, endPageIndex: i).trim();
        if (pageText.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write('\n\n');
          // Only add page marker for multi-page docs
          if (pageCount > 1) {
            buffer.write('--- Page ${i + 1} ---\n');
          }
          buffer.write(pageText);
        }
      } catch (_) {
        // Skip individual pages that fail; continue with the rest
      }
    }

    document.dispose();

    return PdfExtractionResult(
      text: buffer.toString(),
      pageCount: pageCount,
    );
  } catch (e) {
    final msg = e.toString().toLowerCase();
    String friendlyMsg;
    if (msg.contains('password') || msg.contains('encrypt')) {
      friendlyMsg = 'This PDF is password-protected and cannot be read.';
    } else if (msg.contains('corrupt') || msg.contains('invalid')) {
      friendlyMsg = 'The PDF file appears to be corrupted.';
    } else {
      friendlyMsg = 'Could not open PDF: $e';
    }
    return PdfExtractionResult(text: '', pageCount: 0, error: friendlyMsg);
  }
}
