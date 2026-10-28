import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/meme_repository.dart';
import '../models/meme_response.dart';

class MemeRepositoryException implements Exception {
  final String message;
  final String code;

  MemeRepositoryException(this.message, {this.code = 'unknown'});

  @override
  String toString() => message;
}

class MemeRepositoryImpl implements MemeRepository {
  final FirebaseFunctions _functions;

  MemeRepositoryImpl({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<MemeResponse> generateMeme(
    String prompt, {
    String? imageBase64,
    String? mimeType,
    String format = 'video',
  }) async {
    debugPrint(
      '[MemeCreation][MemeRepositoryImpl] Calling generateMeme with prompt: '
      '"$prompt", hasImage: ${imageBase64 != null && imageBase64.isNotEmpty}, '
      'format: $format',
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
      });

      final data = Map<String, dynamic>.from(result.data);
      debugPrint('[MemeCreation][MemeRepositoryImpl] Result: $data');
      return MemeResponse.fromMap(data);
    } on FirebaseFunctionsException catch (e, stack) {
      debugPrint(
        '[MemeCreation][MemeRepositoryImpl] FirebaseFunctionsException: '
        'code=${e.code}, message="${e.message}", details=${e.details}\n$stack',
      );
      throw MemeRepositoryException(
        e.message ?? 'An error occurred during meme generation.',
        code: e.code,
      );
    } catch (e, stack) {
      debugPrint(
        '[MemeCreation][MemeRepositoryImpl] Unexpected exception: $e\n$stack',
      );
      throw MemeRepositoryException(
        'Failed to connect to meme generation service: ${e.toString()}',
      );
    }
  }
}
