import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// Short, non-sensitive messages for media operations. Never show raw API errors.
class MediaFailure {
  static String message(
    Object error, {
    required String media,
    String action = 'enhance',
  }) {
    if (error is FormatException) {
      final detail = error.message;
      if (detail.startsWith('Choose a photo') ||
          detail.startsWith('Choose a JPEG') ||
          detail.startsWith('Choose an MP4')) {
        return detail;
      }
      return 'This $media format could not be used. Choose another file.';
    }
    if (error is FirebaseFunctionsException) {
      final details = error.details;
      if (error.code == 'internal' &&
          details is Map &&
          details['reason'] == 'PROVIDER_HTTP_ERROR') {
        return 'The enhancement service could not process this request. '
            'Try another enhancement or try again later.';
      }
      switch (error.code) {
        case 'failed-precondition':
          return 'An update is required to continue. Please update Slipe AI from Google Play.';
        case 'unauthenticated':
          return 'Sign in to continue.';
        case 'permission-denied':
          return 'You do not have access to this $media.';
        case 'invalid-argument':
          return 'This $media could not be processed. Choose another file.';
        case 'resource-exhausted':
          return 'The enhancement service is unavailable right now. Try again later.';
        case 'deadline-exceeded':
        case 'cancelled':
          return 'The request took too long. Please try again.';
        case 'unavailable':
          return 'Could not connect. Check your internet and try again.';
        case 'not-found':
          return 'This enhancement is no longer available. Start a new one.';
      }
    }
    if (error is SocketException || error is http.ClientException) {
      return 'Could not connect. Check your internet and try again.';
    }
    if (error is TimeoutException) {
      return 'The request took too long. Please try again.';
    }
    if (error is FileSystemException) {
      return 'Could not read the $media. Choose another file.';
    }
    if (error is StateError &&
        media == 'photo' &&
        error.message ==
            'Background removal is taking too long at Topaz. Please try again.') {
      return error.message.toString();
    }
    if (error is StateError &&
        media == 'video' &&
        error.message.toString().startsWith('Video upload failed')) {
      return 'Video upload did not complete. Check your connection and try again.';
    }
    if (error is StateError &&
        action == 'save' &&
        error.message.toString().startsWith('Gallery access')) {
      return 'Allow gallery access in Settings to save this $media.';
    }
    if (error is PlatformException) {
      return 'This $media could not be opened on your device.';
    }
    return 'Could not $action the $media. Please try again.';
  }
}
