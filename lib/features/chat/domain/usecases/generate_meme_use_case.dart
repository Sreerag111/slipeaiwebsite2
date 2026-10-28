import '../repositories/chat_repository.dart';

class GenerateMemeUseCase {
  final ChatRepository repository;

  GenerateMemeUseCase({required this.repository});

  Future<Map<String, dynamic>> call({
    required String prompt,
    String? imageBase64,
    String? mimeType,
    String format = 'video',
    List<Map<String, dynamic>>? chatHistory,
  }) {
    return repository.generateMeme(
      prompt: prompt,
      imageBase64: imageBase64,
      mimeType: mimeType,
      format: format,
      chatHistory: chatHistory,
    );
  }
}
