import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/version/app_update_screen.dart';
import '../../../../core/version/app_version_service.dart';
import 'enhancer_debug_log.dart';

class TopazEnhancementService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final timer = Stopwatch()..start();
    EnhancerDebugLog.event('$name started');
    try {
      final buildNumber =
          await AppVersionService.instance.getEffectiveBuildNumber();
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call<Map<Object?, Object?>>({
        ...payload,
        'buildNumber': buildNumber,
        'debug': kDebugMode,
      });
      EnhancerDebugLog.event('$name completed',
          detail: 'durationMs=${timer.elapsedMilliseconds}');
      final data =
          result.data.map((key, value) => MapEntry(key.toString(), value));
      if (data['status'] != null) {
        EnhancerDebugLog.event('$name status',
            detail:
                'state=${data['status']} progress=${data['progress'] ?? '-'}'
                '${data['model'] == null ? '' : ' model=${data['model']}'}');
        if (data['status'] == 'Failed' || data['status'] == 'Cancelled') {
          EnhancerDebugLog.providerJobFailure(name, data['debugFailure']);
        }
      }
      return data;
    } catch (error) {
      if (error is FirebaseFunctionsException &&
          (error.code == 'failed-precondition' ||
              (error.message?.contains('APP_UPDATE_REQUIRED') ?? false))) {
        final context = Get.context;
        if (context != null) {
          unawaited(showAppUpdateDialog(context, isMandatory: true));
        }
      }
      EnhancerDebugLog.failure(name, error);
      rethrow;
    }
  }

  Future<String> startPhoto(File file, String category) async {
    final size = await file.length();
    if (size == 0 || size > 10 * 1024 * 1024) {
      throw const FormatException('Choose a photo under 10 MB.');
    }
    final extension = file.path.split('.').last.toLowerCase();
    String mimeType;
    List<int> bytes;
    if (extension == 'webp') {
      try {
        final rawBytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(rawBytes);
        final frame = await codec.getNextFrame();
        final byteData =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw const FormatException('Could not process WebP image.');
        }
        bytes = byteData.buffer.asUint8List();
        mimeType = 'image/png';
        EnhancerDebugLog.event('webp converted to png for processing',
            detail: 'originalSize=$size convertedSize=${bytes.length}');
      } catch (e) {
        EnhancerDebugLog.failure('webp conversion, falling back to raw webp', e);
        bytes = await file.readAsBytes();
        mimeType = 'image/webp';
      }
    } else {
      mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'tif' || 'tiff' => 'image/tiff',
        _ => throw const FormatException('Choose a JPEG, PNG, WEBP, or TIFF photo.'),
      };
      bytes = await file.readAsBytes();
    }
    EnhancerDebugLog.event('photo selected',
        detail: 'bytes=${bytes.length} category=$category mimeType=$mimeType');
    final result = await _call(
        'startPhotoEnhancement',
        {
          'imageBase64': bytes.toBase64(),
          'mimeType': mimeType,
          'category': category,
        },
        timeout: category == 'remove_background'
            ? const Duration(minutes: 5)
            : const Duration(minutes: 2));
    final jobId = result['jobId'] as String;
    EnhancerDebugLog.event('photo job queued', detail: 'jobId=$jobId');
    return jobId;
  }

  Future<Map<String, dynamic>> photoStatus(String jobId) =>
      _call('getPhotoEnhancementStatus', {'jobId': jobId});

  Future<String> uploadVideo(File file) async {
    final size = await file.length();
    EnhancerDebugLog.event('video selected', detail: 'bytes=$size');
    if (size == 0 ||
        size > 75 * 1024 * 1024 ||
        file.path.split('.').last.toLowerCase() != 'mp4') {
      throw const FormatException('Choose an MP4 video under 75 MB.');
    }
    final prepared =
        await _call('prepareVideoEnhancementUpload', {'size': size});
    final uploadUrl = prepared['uploadUrl'] as String;
    final timer = Stopwatch()..start();
    EnhancerDebugLog.event('firebase video PUT started', detail: 'bytes=$size');
    try {
      final response = await http
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': 'video/mp4'},
            body: await file.readAsBytes(),
          )
          .timeout(const Duration(minutes: 10));
      EnhancerDebugLog.event('firebase video PUT completed',
          detail:
              'status=${response.statusCode} durationMs=${timer.elapsedMilliseconds}');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Video upload failed (${response.statusCode}).');
      }
    } catch (error) {
      EnhancerDebugLog.failure('firebase video PUT', error);
      rethrow;
    }
    return prepared['uploadId'] as String;
  }

  Future<Map<String, dynamic>> createVideo(String uploadId, String category) =>
      _call('createVideoEnhancement', {
        'uploadId': uploadId,
        'category': category,
      });

  Future<void> discardVideo(String jobId) async {
    await _call('discardVideoEnhancement', {'jobId': jobId});
  }

  Future<Map<String, dynamic>> cancelVideo(String jobId) async {
    return _call('cancelVideoEnhancement', {'jobId': jobId},
        timeout: const Duration(minutes: 2));
  }

  Future<void> acceptVideo(String jobId) async {
    await _call('acceptVideoEnhancement', {'jobId': jobId},
        timeout: const Duration(minutes: 9));
  }

  Future<Map<String, dynamic>> videoStatus(String jobId) =>
      _call('getVideoEnhancementStatus', {'jobId': jobId},
          timeout: const Duration(minutes: 9));
}

extension on List<int> {
  String toBase64() => base64Encode(this);
}
