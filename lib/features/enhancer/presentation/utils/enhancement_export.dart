import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/media_failure.dart';
import '../../data/enhancer_debug_log.dart';
import '../../../premium/presentation/controllers/premium_controller.dart';
import '../../../premium/presentation/widgets/premium_dialog.dart';
import '../widgets/enhancer_error_notice.dart';

Future<void> saveEnhancement(
  BuildContext context, {
  required String url,
  required bool isVideo,
  ValueChanged<String>? onStage,
  bool allowRewardedSave = false,
}) async {
  if (!allowRewardedSave &&
      !Get.find<PremiumController>().canExportEnhancement(isVideo: isVideo)) {
    if (context.mounted) {
      showPremiumDialog(
        context,
        initialPlanId: isVideo ? 'pro_monthly' : 'lite_monthly',
      );
    }
    return;
  }
  if (!context.mounted) return;
  File? temporary;
  try {
    if (!await Gal.hasAccess()) {
      if (!await Gal.requestAccess()) {
        throw StateError('Gallery access is required to save this result.');
      }
    }
    final directory = await getTemporaryDirectory();
    final resultPath = Uri.decodeComponent(Uri.parse(url).path).toLowerCase();
    final extension = isVideo
        ? 'mp4'
        : resultPath.endsWith('.png')
            ? 'png'
            : 'jpg';
    temporary = File('${directory.path}/enhancement_'
        '${DateTime.now().millisecondsSinceEpoch}.$extension');
    final request = http.Request('GET', Uri.parse(url));
    final client = http.Client();
    try {
      onStage?.call('Downloading result…');
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw StateError('Unable to download the enhanced result.');
      }
      await response.stream.pipe(temporary.openWrite());
    } finally {
      client.close();
    }
    onStage?.call('Saving to gallery…');
    if (isVideo) {
      await Gal.putVideo(temporary.path, album: 'Slipe AI');
    } else {
      await Gal.putImage(temporary.path, album: 'Slipe AI');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to gallery')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      EnhancerDebugLog.failure('save enhancement', error);
      EnhancerErrorNotice.show(
          context,
          MediaFailure.message(error,
              media: isVideo ? 'video' : 'photo', action: 'save'));
    }
  } finally {
    if (temporary != null && await temporary.exists()) {
      await temporary.delete();
    }
  }
}
