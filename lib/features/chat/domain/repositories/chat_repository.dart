import 'dart:async';

import '../entities/chat_completion_result.dart';
import '../entities/chat_message.dart';
import '../entities/chat_thread.dart';
import '../entities/classification_result.dart';

abstract class ChatRepository {
  Future<ChatCompletionResult> sendMessage({
    required List<ChatMessage> messages,
  });

  Stream<String> sendMessageStreaming({
    required List<ChatMessage> messages,
  });

  Future<ChatCompletionResult> checkGrammar({
    required ChatMessage message,
  });

  Future<PlagiarismAnalysisResult> analyzePlagiarism({
    required ChatMessage message,
    required String sourceText,
  });

  Future<ClassificationResult> classifyMessage({
    required String message,
    required List<ChatMessage> history,
  });

  Future<String> generateImage({
    required String prompt,
    String? size,
    List<Map<String, dynamic>>? chatHistory,
    String? imageUrl,
  });

  Future<String> generateImageEdit({
    required String prompt,
    String? imageBase64,
    String? referenceImageBase64,
    String? imageUrl,
    String mimeType = 'image/jpeg',
    String? referenceMimeType,
    List<Map<String, dynamic>>? chatHistory,
  });

  /// Uploads a user-attached image file to Firebase Storage.
  /// Returns the permanent download URL, or empty string on failure.
  Future<String> uploadAttachmentToStorage({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  });

  Future<Map<String, dynamic>> generateMeme({
    required String prompt,
    String? imageBase64,
    String? mimeType,
    String format = 'video',
    List<Map<String, dynamic>>? chatHistory,
  });

  Future<List<ChatThread>> getChatThreads();

  Future<ChatThread?> getChatThread(String conversationId);

  Future<void> saveChatThread(ChatThread thread);

  Future<void> deleteChatThread(String threadId);

  void cancelActiveRequest();
}
