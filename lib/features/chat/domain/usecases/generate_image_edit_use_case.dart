import '../repositories/chat_repository.dart';

class GenerateImageEditUseCase {
  final ChatRepository _chatRepository;

  GenerateImageEditUseCase({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  Future<String> call({
    required String prompt,
    String? imageBase64,
    String? referenceImageBase64,
    String? imageUrl,
    String mimeType = 'image/jpeg',
    String? referenceMimeType,
    List<Map<String, dynamic>>? chatHistory,
  }) {
    return _chatRepository.generateImageEdit(
      prompt: prompt,
      imageBase64: imageBase64,
      referenceImageBase64: referenceImageBase64,
      imageUrl: imageUrl,
      mimeType: mimeType,
      referenceMimeType: referenceMimeType,
      chatHistory: chatHistory,
    );
  }

  /// Uploads a user-attached image to Firebase Storage for persistence.
  /// Returns the permanent download URL or empty string on failure.
  Future<String> uploadAttachment({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    try {
      return await _chatRepository.uploadAttachmentToStorage(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
    } catch (e) {
      return '';
    }
  }
}
