import '../repositories/chat_repository.dart';

class GenerateImageUseCase {
  const GenerateImageUseCase({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  final ChatRepository _chatRepository;

  Future<String> call({
    required String prompt,
    String? size,
    List<Map<String, dynamic>>? chatHistory,
    String? imageUrl,
  }) =>
      _chatRepository.generateImage(
        prompt: prompt,
        size: size,
        chatHistory: chatHistory,
        imageUrl: imageUrl,
      );
}
