import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/app_exception.dart';
import '../../../../core/version/app_version_service.dart';
import '../../../../core/version/app_update_screen.dart';

/// Centralized service for all AI operations routed through Firebase Cloud Functions.
/// API keys are stored in Firebase Secret Manager and never exposed to the client.
class CloudFunctionService {
  CloudFunctionService({
    FirebaseFunctions? functions,
    http.Client? client,
    String region = 'us-central1',
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _client = client ?? http.Client(),
        _region = region;

  final FirebaseFunctions _functions;
  final http.Client _client;
  final String _region;

  // ---------------------------------------------------------------------------
  // Chat (non-streaming) — via httpsCallable
  // ---------------------------------------------------------------------------

  Future<String> generateChat({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
    String model = 'gpt-5.6-luna',
  }) async {
    try {
      final callable = _functions.httpsCallable('generateChat');
      final result = await callable.call<Map<String, dynamic>>({
        'messages': messages,
        'systemPrompt': systemPrompt,
        'model': model,
      });

      final data = result.data;
      if (data['success'] == true) {
        return (data['content'] as String?) ?? '';
      }
      throw const AppException('Chat generation failed.');
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'Chat generation failed.');
    }
  }

  // ---------------------------------------------------------------------------
  // Chat (streaming) — via HTTP to onRequest Cloud Function (SSE)
  // ---------------------------------------------------------------------------

  Stream<String> generateChatStreaming({
    required List<Map<String, dynamic>> messages,
    required String systemPrompt,
    String model = 'gpt-5.6-luna',
  }) async* {
    final token = await _getAuthToken();
    if (token == null) {
      throw const AppException('You must be signed in to use chat.');
    }

    final projectId = Firebase.app().options.projectId;
    final url = Uri.parse(
      'https://$_region-$projectId.cloudfunctions.net/generateChatStream',
    );

    http.StreamedResponse streamedResponse;
    try {
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode({
        'messages': messages,
        'systemPrompt': systemPrompt,
        'model': model,
      });
      streamedResponse = await _client.send(request).timeout(
            const Duration(seconds: 60),
          );
    } on TimeoutException {
      throw const AppException(
        'The AI request timed out. Please try again with a shorter request.',
      );
    }

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw AppException(_readErrorMessage(body));
    }

    final lineSplitter = LineSplitter();
    try {
      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(lineSplitter)
          .timeout(const Duration(seconds: 15))) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') break;
        if (data.isEmpty) continue;

        Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } on FormatException {
          continue;
        }

        final streamError = json['error'] as String?;
        if (streamError != null && streamError.isNotEmpty) {
          throw AppException(streamError);
        }

        final content = json['content'] as String?;
        if (content != null && content.isNotEmpty) {
          yield content;
        }
      }
    } on TimeoutException {
      throw const AppException('The AI response stream timed out.');
    }
  }

  // ---------------------------------------------------------------------------
  // Image Generation — via httpsCallable
  // ---------------------------------------------------------------------------

  Future<String> generateImage({
    required String prompt,
    String model = 'gpt-image-2',
    String size = '1024x1792',
    String quality = 'high',
    List<Map<String, dynamic>>? chatHistory,
    String? imageUrl,
  }) async {
    try {
      final buildNumber =
          await AppVersionService.instance.getEffectiveBuildNumber();
      final callable = _functions.httpsCallable(
        'generateImage',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'prompt': prompt,
        'model': model,
        'size': size,
        'quality': quality,
        if (chatHistory != null && chatHistory.isNotEmpty)
          'chatHistory': chatHistory,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'buildNumber': buildNumber,
      });

      final data = result.data;
      if (data['success'] != true) {
        throw const AppException('Image generation failed.');
      }

      final generatedUrl = data['imageUrl'] as String?;
      if (generatedUrl != null && generatedUrl.isNotEmpty) {
        return generatedUrl;
      }
      final b64 = data['b64Json'] as String?;
      if (b64 != null && b64.isNotEmpty) {
        return 'data:image/png;base64,$b64';
      }
      throw const AppException('Image generation returned no data.');
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' ||
          (e.message?.contains('APP_UPDATE_REQUIRED') ?? false)) {
        if (Get.context != null) {
          unawaited(showAppUpdateDialog(Get.context!, isMandatory: true));
        }
        throw const AppException(
          'An update is required to continue. Please update Slipe AI from Google Play.',
        );
      }
      if (e.message?.contains('free image limit') == true) {
        throw const AppException('IMAGE_LIMIT_REACHED');
      }
      throw const AppException('Image generation failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Image Edit — edit/transform a user-uploaded photo via OpenAI
  // ---------------------------------------------------------------------------

  Future<String> generateImageEdit({
    required String prompt,
    String? imageBase64,
    String? referenceImageBase64,
    String? imageUrl,
    String mimeType = 'image/jpeg',
    String? referenceMimeType,
    String size = 'auto',
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    if (kDebugMode)
      debugPrint(
        '[ImageEdit][CloudFunctionService] starting '
        'hasBase64=${imageBase64 != null} hasRefBase64=${referenceImageBase64 != null} hasImageUrl=${imageUrl != null}',
      );
    try {
      final buildNumber =
          await AppVersionService.instance.getEffectiveBuildNumber();
      final callable = _functions.httpsCallable(
        'generateImageEdit',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'prompt': prompt,
        if (imageBase64 != null && imageBase64.isNotEmpty)
          'imageBase64': imageBase64,
        if (referenceImageBase64 != null && referenceImageBase64.isNotEmpty)
          'referenceImageBase64': referenceImageBase64,
        if (referenceMimeType != null && referenceMimeType.isNotEmpty)
          'referenceMimeType': referenceMimeType,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        'mimeType': mimeType,
        'size': size,
        if (chatHistory != null && chatHistory.isNotEmpty)
          'chatHistory': chatHistory,
        'buildNumber': buildNumber,
      });

      final data = result.data;
      if (data['success'] != true) {
        throw const AppException('Image edit failed.');
      }

      final resultUrl = data['imageUrl'] as String?;
      if (resultUrl == null || resultUrl.isEmpty) {
        throw const AppException('Image edit returned no URL.');
      }
      return resultUrl;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode)
        debugPrint(
          '[ImageEdit][CloudFunctionService] failed code=${e.code}',
        );
      if (e.code == 'failed-precondition' ||
          (e.message?.contains('APP_UPDATE_REQUIRED') ?? false)) {
        if (Get.context != null) {
          unawaited(showAppUpdateDialog(Get.context!, isMandatory: true));
        }
        throw const AppException(
          'An update is required to continue. Please update Slipe AI from Google Play.',
        );
      }
      if (e.message?.contains('free image limit') == true) {
        throw const AppException('IMAGE_LIMIT_REACHED');
      }
      throw const AppException('Image editing failed. Please try again.');
    } catch (e) {
      if (kDebugMode)
        debugPrint(
            '[ImageEdit][CloudFunctionService] failed type=${e.runtimeType}');
      if (e is AppException) rethrow;
      throw const AppException('Image editing failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Upload user attachment to Firebase Storage for persistence
  // ---------------------------------------------------------------------------

  Future<String> uploadAttachmentToStorage({
    required String uid,
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'uploadUserAttachment',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 1)),
      );
      final base64Data = base64Encode(bytes);
      final result = await callable.call<Map<String, dynamic>>({
        'imageBase64': base64Data,
        'filename': filename,
        'contentType': contentType,
      });
      final data = result.data;
      if (data['success'] == true) {
        return (data['url'] as String?) ?? '';
      }
      return '';
    } catch (e) {
      if (kDebugMode)
        debugPrint(
            '[CloudFunctionService] uploadAttachment failed type=${e.runtimeType}');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Meme Generation — via httpsCallable (MEME_API_KEY + Veo 3.1 & GIF)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> generateMeme({
    required String prompt,
    String? imageBase64,
    String? mimeType,
    String format = 'video',
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    if (kDebugMode)
      debugPrint(
        '[MemeCreation][CloudFunctionService] starting '
        'hasImage=${imageBase64 != null && imageBase64.isNotEmpty} format=$format',
      );
    try {
      final callable = _functions.httpsCallable(
        'generateMeme',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'prompt': prompt,
        if (imageBase64 != null && imageBase64.isNotEmpty)
          'imageBase64': imageBase64,
        if (mimeType != null && mimeType.isNotEmpty) 'mimeType': mimeType,
        'format': format,
        if (chatHistory != null && chatHistory.isNotEmpty)
          'chatHistory': chatHistory,
      });

      final data = Map<String, dynamic>.from(result.data);
      if (kDebugMode)
        debugPrint(
          '[MemeCreation][CloudFunctionService] response success=${data['success']}',
        );

      if (data['success'] != true) {
        throw const AppException('Meme generation failed.');
      }

      return data;
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode)
        debugPrint(
          '[MemeCreation][CloudFunctionService] failed code=${e.code}',
        );
      throw const AppException('Meme generation failed. Please try again.');
    } catch (e) {
      if (kDebugMode)
        debugPrint(
          '[MemeCreation][CloudFunctionService] failed type=${e.runtimeType}',
        );
      if (e is AppException) rethrow;
      throw const AppException('Meme generation failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Classification — via generateChat Cloud Function
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> classifyMessage({
    required String message,
    required List<Map<String, dynamic>> history,
    required String systemPrompt,
  }) async {
    final allMessages = <Map<String, dynamic>>[
      ...history,
      {'role': 'user', 'content': message},
    ];

    final response = await generateChat(
      messages: allMessages,
      systemPrompt: systemPrompt,
      model: 'gpt-4o-mini',
    );

    final clean = response
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final jsonStart = clean.indexOf('{');
    final jsonEnd = clean.lastIndexOf('}') + 1;
    if (jsonStart == -1 || jsonEnd == 0) {
      return {'type': 'text', 'text': response, 'image_prompt': ''};
    }

    return jsonDecode(clean.substring(jsonStart, jsonEnd))
        as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Plagiarism Analysis — via generateChat Cloud Function
  // ---------------------------------------------------------------------------

  Future<String> analyzePlagiarism({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    return generateChat(
      messages: [
        {'role': 'user', 'content': userPrompt},
      ],
      systemPrompt: systemPrompt,
      model: 'gpt-5.6-luna',
    );
  }

  // ---------------------------------------------------------------------------
  // Raw Message (grammar check, etc.) — via generateChat Cloud Function
  // ---------------------------------------------------------------------------

  Future<String> sendRawMessage({
    required String systemPrompt,
    required String userMessage,
  }) async {
    return generateChat(
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      systemPrompt: systemPrompt,
      model: 'gpt-5.6-luna',
    );
  }

  // ---------------------------------------------------------------------------
  // PDF OCR — via generateChat Cloud Function with file content
  // ---------------------------------------------------------------------------

  Future<String> extractPdfText({
    required String pdfBase64,
    required String fileName,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateChat');
      final result = await callable.call<Map<String, dynamic>>({
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'This is a scanned PDF document. Extract ALL the text from it. '
                    'Preserve paragraphs, headings, bullet points, and tables as best you can. '
                    'Return ONLY the extracted text — no comments, no explanations.',
              },
              {
                'type': 'file',
                'file': {
                  'filename': fileName,
                  'file_data': 'data:application/pdf;base64,$pdfBase64',
                },
              },
            ],
          },
        ],
        'systemPrompt': 'You are a document text extraction assistant.',
        'model': 'gpt-5.6-luna',
      });

      final data = result.data;
      if (data['success'] == true) {
        return (data['content'] as String?)?.trim() ?? '';
      }
      throw const AppException('PDF text extraction failed.');
    } on FirebaseFunctionsException catch (e) {
      throw AppException(e.message ?? 'PDF text extraction failed.');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  String _readErrorMessage(String rawBody) {
    try {
      final body = jsonDecode(rawBody) as Map<String, dynamic>;
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        return 'API error: ${error['message'] ?? 'Unknown error'}';
      }
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } catch (_) {}
    return 'API error';
  }

  void cancelActiveRequest() {
    _client.close();
  }
}
