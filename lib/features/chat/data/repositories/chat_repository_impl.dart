import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/error/app_exception.dart';
import '../../domain/entities/chat_completion_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/classification_result.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/chat_storage_data_source.dart';
import '../datasources/document_data_source.dart';
import '../models/chat_thread_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required ChatStorageDataSource storageDataSource,
    required DocumentDataSource documentDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _storageDataSource = storageDataSource,
        _documentDataSource = documentDataSource;

  final ChatRemoteDataSource _remoteDataSource;
  final ChatStorageDataSource _storageDataSource;
  final DocumentDataSource _documentDataSource;
  static const int _maxApiHistoryMessages = 28;
  static const int _maxApiHistoryCharacters = 42000;
  static const int _maxSingleTextCharacters = 32000;
  static const int _largeTextIsolateThreshold = 50000;
  static const int _maxStoredPromptCharacters = 2500;

  @override
  Future<ChatCompletionResult> sendMessage({
    required List<ChatMessage> messages,
  }) async {
    final apiMessages = await _buildConversationHistory(messages: messages);
    final response = await _remoteDataSource.sendChat(
      messages: apiMessages,
    );
    return ChatCompletionResult(
      prompt: _storageSafePrompt(messages.last),
      response: response.trim(),
    );
  }

  @override
  Stream<String> sendMessageStreaming({
    required List<ChatMessage> messages,
  }) async* {
    final apiMessages = await _buildConversationHistory(messages: messages);
    yield* _remoteDataSource.sendChatStreaming(
      messages: apiMessages,
    );
  }

  @override
  Future<ChatCompletionResult> checkGrammar({
    required ChatMessage message,
  }) async {
    final preparedText = await _composeMessageText(message: message);
    final response = await _remoteDataSource.sendRawMessage(
      systemPrompt:
          'You are an expert grammar checker and writing coach. Respond in markdown with this exact structure: ## Overall Summary, ## Issues Found, ## Corrected Version, ## Grammar Score (0-100). Keep it concise and actionable.',
      userMessage: 'Check grammar:\n\n"""\n$preparedText\n"""',
    );
    return ChatCompletionResult(
      prompt: _storageSafePrompt(message),
      response: response.trim(),
    );
  }

  @override
  Future<PlagiarismAnalysisResult> analyzePlagiarism({
    required ChatMessage message,
    required String sourceText,
  }) async {
    final preparedText = await _composeMessageText(message: message);
    final wordCount = preparedText.trim().isEmpty
        ? 0
        : preparedText.trim().split(RegExp(r'\s+')).length;
    if (wordCount < 20) {
      throw const ValidationException('Please enter at least 20 words');
    }
    final result = await _remoteDataSource.analyzePlagiarism(
      text: preparedText,
      sourceText: await _limitTextForApi(sourceText),
    );
    return PlagiarismAnalysisResult(
      analyzedText: preparedText,
      result: result,
    );
  }

  @override
  Future<List<ChatThread>> getChatThreads() =>
      _storageDataSource.getChatThreads();

  @override
  Future<ChatThread?> getChatThread(String conversationId) =>
      _storageDataSource.getChatThread(conversationId);

  @override
  Future<void> saveChatThread(ChatThread thread) {
    return _storageDataSource.saveOrUpdateChatThread(
      ChatThreadModel.fromEntity(thread),
    );
  }

  @override
  Future<void> deleteChatThread(String threadId) {
    return _storageDataSource.deleteChatThread(threadId);
  }

  @override
  void cancelActiveRequest() {
    _remoteDataSource.cancelActiveRequest();
  }

  @override
  Future<ClassificationResult> classifyMessage({
    required String message,
    required List<ChatMessage> history,
  }) async {
    final historyMaps = history
        .where((m) => !m.isError)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList(growable: false);
    return _remoteDataSource.classifyMessage(
      message: message,
      history: historyMaps,
    );
  }

  @override
  Future<String> generateImage({
    required String prompt,
    String? size,
    List<Map<String, dynamic>>? chatHistory,
    String? imageUrl,
  }) async {
    final result = await _remoteDataSource.generateImage(
      prompt: prompt,
      size: size,
      chatHistory: chatHistory,
      imageUrl: imageUrl,
    );
    if (!result.startsWith('data:image/')) return result;

    // Firestore cannot store a full base64 image in a chat thread. Persist
    // fallback image responses as a URL so they appear in Created images.
    try {
      final header = result.substring(0, result.indexOf(','));
      final mimeType = header.substring(5).split(';').first;
      final extension = mimeType == 'image/jpeg' ? 'jpg' : 'png';
      final bytes = base64Decode(result.split(',').last);
      final uploadedUrl = await uploadAttachmentToStorage(
        bytes: bytes,
        filename: 'created_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: mimeType,
      );
      if (uploadedUrl.isNotEmpty) return uploadedUrl;
    } catch (error) {
      debugPrint('[ChatRepositoryImpl] generated image upload failed: $error');
    }
    return result;
  }

  @override
  Future<String> generateImageEdit({
    required String prompt,
    String? imageBase64,
    String? referenceImageBase64,
    String? imageUrl,
    String mimeType = 'image/jpeg',
    String? referenceMimeType,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    return _remoteDataSource.generateImageEdit(
      prompt: prompt,
      imageBase64: imageBase64,
      referenceImageBase64: referenceImageBase64,
      imageUrl: imageUrl,
      mimeType: mimeType,
      referenceMimeType: referenceMimeType,
      chatHistory: chatHistory,
    );
  }

  @override
  Future<String> uploadAttachmentToStorage({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    try {
      return await _remoteDataSource.uploadAttachmentToStorage(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
    } catch (e) {
      debugPrint('[ChatRepositoryImpl] uploadAttachmentToStorage failed: $e');
      return '';
    }
  }

  @override
  Future<Map<String, dynamic>> generateMeme({
    required String prompt,
    String? imageBase64,
    String? mimeType,
    String format = 'video',
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    return _remoteDataSource.generateMeme(
      prompt: prompt,
      imageBase64: imageBase64,
      mimeType: mimeType,
      format: format,
      chatHistory: chatHistory,
    );
  }

  Future<String> _composeMessageText({
    required ChatMessage message,
  }) async {
    String combinedText = message.text;
    final fileAttachments = message.attachments.where((item) => item.isFile);

    for (final file in fileAttachments) {
      final path = file.path;
      final extension = (file.extension ?? '').toLowerCase();
      if (path.isEmpty) {
        continue;
      }
      if (extension == 'pdf') {
        final extraction = await _documentDataSource.extractText(path);
        if (extraction.hasError) {
          throw AppException('PDF Error: ${extraction.error}');
        }
        if (!extraction.hasText) {
          throw AppException(
            'No readable text found in "${file.name}". The PDF may be scanned or encrypted.',
          );
        }
        final label = combinedText.trim().isEmpty
            ? 'Please analyze the following PDF document and respond to the user:'
            : combinedText.trim();
        combinedText = '$label\n\n--- PDF: ${file.name} ';
        if (extraction.usedOcr) {
          combinedText += '(OCR) ';
        }
        combinedText += '---\n${extraction.text}';
      } else if (extension == 'txt' ||
          extension == 'docx' ||
          extension == 'zip') {
        final content = await _documentDataSource.readTextFile(path);
        if (combinedText.isNotEmpty) {
          combinedText += '\n\n';
        }
        combinedText += '--- ${file.name} ---\n$content';
      }
    }
    return _limitTextForApi(combinedText);
  }

  Future<List<Map<String, dynamic>>> _buildConversationHistory({
    required List<ChatMessage> messages,
  }) async {
    final history = <Map<String, dynamic>>[];
    final sourceMessages = _selectMessagesForApi(
      messages.where((item) => !item.isError).toList(growable: false),
    );
    for (final message in sourceMessages) {
      final preparedText = message.isUser
          ? await _composeMessageText(message: message)
          : await _limitTextForApi(message.text);
      final imageAttachments =
          message.attachments.where((item) => item.isImage);

      if (imageAttachments.isNotEmpty) {
        final contentList = <Map<String, dynamic>>[];
        if (preparedText.isNotEmpty) {
          contentList.add({'type': 'text', 'text': preparedText});
        }
        for (final image in imageAttachments) {
          try {
            final base64Str = await compute(_readFileAsBase64, image.path);
            contentList.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Str'},
            });
          } catch (_) {
            // Skip images we can no longer read.
          }
        }
        history.add({
          'role': message.isUser ? 'user' : 'assistant',
          'content': contentList,
        });
      } else {
        history.add({
          'role': message.isUser ? 'user' : 'assistant',
          'content': preparedText,
        });
      }
    }
    return _trimHistoryToBudget(history);
  }

  List<ChatMessage> _selectMessagesForApi(List<ChatMessage> messages) {
    if (messages.length <= _maxApiHistoryMessages) {
      return messages;
    }

    final keep = messages.skip(messages.length - _maxApiHistoryMessages);
    return keep.toList(growable: false);
  }

  Future<String> _limitTextForApi(String text) async {
    if (text.length <= _maxSingleTextCharacters) {
      return text;
    }
    if (text.length >= _largeTextIsolateThreshold) {
      return compute(
        _buildLargeContentPayload,
        LargeContentPayloadInput(
          text: text,
          maxCharacters: _maxSingleTextCharacters,
        ),
      );
    }
    return _buildLargeContentPayload(
      LargeContentPayloadInput(
        text: text,
        maxCharacters: _maxSingleTextCharacters,
      ),
    );
  }

  int _estimateContentCharacters(dynamic content) {
    if (content is String) {
      return content.length;
    }
    if (content is List) {
      var total = 0;
      for (final item in content) {
        if (item is Map<String, dynamic>) {
          final text = item['text'];
          if (text is String) {
            total += text.length;
          }
          if (item.containsKey('image_url')) {
            total += 1500;
          }
        }
      }
      return total;
    }
    return 0;
  }

  List<Map<String, dynamic>> _trimHistoryToBudget(
    List<Map<String, dynamic>> history,
  ) {
    var remaining = _maxApiHistoryCharacters;
    final selected = <Map<String, dynamic>>[];

    for (final message in history.reversed) {
      final size = _estimateContentCharacters(message['content']);
      if (selected.isNotEmpty && size > remaining) {
        continue;
      }
      selected.add(message);
      remaining -= size;
      if (remaining <= 0) {
        break;
      }
    }

    return selected.reversed.toList(growable: false);
  }

  String _storageSafePrompt(ChatMessage message) {
    final text = message.text.trim();
    final attachmentNames = message.attachments
        .map((item) => item.name)
        .where((name) => name.trim().isNotEmpty)
        .join(', ');
    final suffix =
        attachmentNames.isEmpty ? '' : '\n\nAttachments: $attachmentNames';
    if (text.length <= _maxStoredPromptCharacters) {
      return '$text$suffix'.trim();
    }
    final omitted = text.length - _maxStoredPromptCharacters;
    return '${text.substring(0, _maxStoredPromptCharacters)}\n\n[$omitted more characters processed]$suffix';
  }
}

Future<String> _readFileAsBase64(String path) async {
  final bytes = await File(path).readAsBytes();
  return base64Encode(bytes);
}

@immutable
class LargeContentPayloadInput {
  const LargeContentPayloadInput({
    required this.text,
    required this.maxCharacters,
  });

  final String text;
  final int maxCharacters;
}

String _buildLargeContentPayload(LargeContentPayloadInput input) {
  final text = input.text.trim();
  final maxCharacters = input.maxCharacters;
  if (text.length <= maxCharacters) {
    return text;
  }

  final chunkBudget = ((maxCharacters - 900) / 5).floor().clamp(1800, 7000);
  final totalLength = text.length;
  final ranges = <({String label, int start})>[
    (label: 'Opening excerpt', start: 0),
    (label: 'Early-middle excerpt', start: (totalLength * 0.25).floor()),
    (label: 'Middle excerpt', start: (totalLength * 0.50).floor()),
    (label: 'Late-middle excerpt', start: (totalLength * 0.75).floor()),
    (label: 'Closing excerpt', start: totalLength - chunkBudget),
  ];

  final buffer = StringBuffer()
    ..writeln('Large input optimized for model context.')
    ..writeln('Original character count: $totalLength.')
    ..writeln(
      'The app sampled representative sections so the request remains responsive. '
      'If the user asks for an exact section, ask them to narrow the page/range.',
    );

  var used = buffer.length;
  for (final range in ranges) {
    if (used >= maxCharacters) {
      break;
    }
    final start = range.start.clamp(0, totalLength - 1);
    final remaining = maxCharacters - used - 80;
    if (remaining <= 0) {
      break;
    }
    final length = chunkBudget.clamp(0, remaining);
    final end = (start + length).clamp(start, totalLength);
    final excerpt = text.substring(start, end).trim();
    if (excerpt.isEmpty) {
      continue;
    }
    final section = '\n\n--- ${range.label} (${start + 1}-$end) ---\n$excerpt';
    buffer.write(section);
    used += section.length;
  }

  return buffer.toString();
}
