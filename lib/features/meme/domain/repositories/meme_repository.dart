import '../../data/models/meme_response.dart';

abstract class MemeRepository {
  Future<MemeResponse> generateMeme(
    String prompt, {
    String? imageBase64,
    String? mimeType,
    String format = 'video',
  });
}
