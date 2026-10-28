import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../services/pdf_service.dart';
import '../../domain/entities/document_extraction_result.dart';

class DocumentDataSource {
  DocumentDataSource({PdfService? pdfService})
      : _pdfService = pdfService ?? PdfService();

  final PdfService _pdfService;

  Future<DocumentExtractionResult> extractText(
    String filePath,
  ) async {
    final result = await _pdfService.extractText(filePath);
    return DocumentExtractionResult(
      text: result.text,
      pageCount: result.pageCount,
      usedOcr: result.usedOcr,
      error: result.error,
    );
  }

  Future<String> readTextFile(String filePath) async {
    try {
      final extension = filePath.split('.').last.toLowerCase();
      if (extension == 'docx') {
        return compute(_extractDocxText, filePath);
      }
      if (extension == 'zip') {
        return compute(_summarizeZipFile, filePath);
      }
      final buffer = StringBuffer();
      await for (final chunk
          in File(filePath).openRead().transform(utf8.decoder)) {
        buffer.write(chunk);
      }
      return buffer.toString();
    } catch (error) {
      throw AppException('Could not read file: $error');
    }
  }
}

String _extractDocxText(String filePath) {
  final inputStream = InputFileStream(filePath);
  final archive = ZipDecoder().decodeStream(inputStream);
  final documentFile = archive.findFile('word/document.xml');
  if (documentFile == null) {
    throw const FormatException('DOCX document text was not found.');
  }
  final xml =
      utf8.decode(documentFile.content as List<int>, allowMalformed: true);
  final paragraphs =
      RegExp(r'<w:p[\s\S]*?</w:p>').allMatches(xml).map((paragraph) {
    final text = RegExp(r'<w:t[^>]*>([\s\S]*?)</w:t>')
        .allMatches(paragraph.group(0) ?? '')
        .map((match) => _decodeXmlText(match.group(1) ?? ''))
        .join();
    return text.trim();
  }).where((text) => text.isNotEmpty);
  return paragraphs.join('\n\n');
}

String _summarizeZipFile(String filePath) {
  final inputStream = InputFileStream(filePath);
  final archive = ZipDecoder().decodeStream(inputStream);
  final entries = archive.files
      .where((file) => file.isFile)
      .take(200)
      .map((file) => '- ${file.name} (${file.size} bytes)')
      .join('\n');
  return entries.isEmpty
      ? 'ZIP archive contains no readable file entries.'
      : 'ZIP archive contents:\n$entries';
}

String _decodeXmlText(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}
