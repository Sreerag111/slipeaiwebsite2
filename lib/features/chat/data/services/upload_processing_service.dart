import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class UploadCancelledException implements Exception {
  const UploadCancelledException();
}

class UploadProcessingException implements Exception {
  const UploadProcessingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UploadProgress {
  const UploadProgress({
    required this.label,
    required this.progress,
  });

  final String label;
  final double progress;
}

class UploadCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const UploadCancelledException();
    }
  }
}

class ProcessedUpload {
  const ProcessedUpload({
    required this.path,
    required this.name,
    required this.extension,
    required this.isImage,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final String extension;
  final bool isImage;
  final int sizeBytes;
}

class UploadProcessingService {
  static const int maxFileBytes = 50 * 1024 * 1024;
  static const int maxInlineTextCharacters = 12000;

  static const Set<String> supportedExtensions = <String>{
    'png',
    'jpg',
    'jpeg',
    'pdf',
    'docx',
    'txt',
    'zip',
  };

  Future<ProcessedUpload> preparePickedFile({
    required String path,
    required String name,
    String? extension,
    required bool isImage,
    required UploadCancellationToken token,
    required ValueChanged<UploadProgress> onProgress,
  }) async {
    token.throwIfCancelled();
    final normalizedExtension = _extensionFor(path, name, extension);
    if (!supportedExtensions.contains(normalizedExtension)) {
      throw UploadProcessingException(
        'Unsupported file type .$normalizedExtension. Supported: PNG, JPG, PDF, DOCX, TXT, ZIP.',
      );
    }

    final file = File(path);
    final sizeBytes = await file.length();
    if (sizeBytes > maxFileBytes) {
      throw UploadProcessingException(
        'File is too large (${_formatBytes(sizeBytes)}). Maximum is ${_formatBytes(maxFileBytes)}.',
      );
    }

    onProgress(const UploadProgress(label: 'Preparing upload', progress: 0.18));

    final shouldCompressImage = isImage ||
        normalizedExtension == 'png' ||
        normalizedExtension == 'jpg' ||
        normalizedExtension == 'jpeg';
    if (shouldCompressImage) {
      final outputPath = await compute(
        _compressImageForUpload,
        ImageCompressionInput(
          path: path,
          quality: 82,
          maxDimension: 1800,
        ),
      );
      token.throwIfCancelled();
      final outputFile = File(outputPath);
      onProgress(const UploadProgress(label: 'Optimized image', progress: 1));
      return ProcessedUpload(
        path: outputPath,
        name: _replaceExtension(name, 'jpg'),
        extension: 'jpg',
        isImage: true,
        sizeBytes: await outputFile.length(),
      );
    }

    onProgress(const UploadProgress(label: 'Attached file', progress: 1));
    return ProcessedUpload(
      path: path,
      name: name,
      extension: normalizedExtension,
      isImage: false,
      sizeBytes: sizeBytes,
    );
  }

  Future<String?> readTextPreview({
    required String path,
    required UploadCancellationToken token,
    int maxCharacters = maxInlineTextCharacters,
  }) async {
    final extension = _extensionFor(path, path, null);
    if (extension != 'txt') {
      return null;
    }

    final buffer = StringBuffer();
    final stream = File(path).openRead().transform(utf8.decoder);
    await for (final chunk in stream) {
      token.throwIfCancelled();
      final remaining = maxCharacters - buffer.length;
      if (remaining <= 0) {
        break;
      }
      buffer.write(
          chunk.length > remaining ? chunk.substring(0, remaining) : chunk);
    }
    return buffer.toString();
  }

  String _extensionFor(String path, String name, String? extension) {
    final candidate = extension?.trim().toLowerCase();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate == 'jpeg' ? 'jpg' : candidate;
    }
    final source = name.contains('.') ? name : path;
    final raw = source.split('.').last.toLowerCase();
    return raw == 'jpeg' ? 'jpg' : raw;
  }

  String _replaceExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    if (dot <= 0) {
      return '$name.$extension';
    }
    return '${name.substring(0, dot)}.$extension';
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

@immutable
class ImageCompressionInput {
  const ImageCompressionInput({
    required this.path,
    required this.quality,
    required this.maxDimension,
  });

  final String path;
  final int quality;
  final int maxDimension;
}

Future<String> _compressImageForUpload(ImageCompressionInput input) async {
  final source = File(input.path);
  final bytes = await source.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return input.path;
  }

  final longestSide =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longestSide > input.maxDimension
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? input.maxDimension : null,
          height: decoded.height > decoded.width ? input.maxDimension : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;

  final outputBytes = Uint8List.fromList(
    img.encodeJpg(resized, quality: input.quality),
  );
  final outputPath =
      '${Directory.systemTemp.path}${Platform.pathSeparator}pace_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
  await File(outputPath).writeAsBytes(outputBytes, flush: true);
  return outputPath;
}
