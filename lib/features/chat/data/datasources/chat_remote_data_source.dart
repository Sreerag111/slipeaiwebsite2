import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../services/cloud_function_service.dart';
import '../../domain/entities/classification_result.dart';
import '../models/plagiarism_result_model.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource({CloudFunctionService? cloudFunctionService})
      : _cloudFunctionService = cloudFunctionService ?? CloudFunctionService();

  final CloudFunctionService _cloudFunctionService;

  static const String _classifierSystemPrompt = '''
Analyze the user's message and determine whether the request requires:
* TEXT: Conversation, explanations, coding help, questions, or advice.
* IMAGE: The user wants to create, draw, generate, design, visualize, illustrate, or render an image or picture.
* MEME: The user wants to create a meme, turn an image/photo into a funny meme, add funny facial expressions (smile, laugh, shocked, confused), or create a meme with funny captions.
* MIXED: The user wants both a textual response and an image.

Always return valid JSON in the following format:
{
  "type": "text" | "image" | "meme" | "mixed",
  "text": "",
  "image_prompt": "",
  "meme_prompt": ""
}

Rules:
1. TEXT: Use when the user only needs a conversational response. Populate only "text".
2. IMAGE: Use when the user wants a still image. Leave "text" empty. Generate a detailed "image_prompt".
3. MEME: Use when the user asks for a meme, wants to edit a photo into a meme, or requests funny facial expressions/reactions/captions (e.g. "make a meme", "make him smile", "turn this photo into a funny meme"). Populate "meme_prompt".
4. MIXED: Use when the user wants both an explanation and an image.

Do not return markdown. Do not return code blocks. Always return valid JSON only.''';
  static const String _chatSystemPrompt = '''
You are Slipe AI, a highly capable assistant integrated into a production chat application.

Core behavior:
- Be natural, warm, concise when possible, and precise when the task needs depth.
- Think carefully and reason step by step internally before answering. Do not reveal hidden reasoning unless the user explicitly asks for a brief explanation.
- Use the full provided conversation context and treat the latest user message as part of an ongoing conversation.
- Resolve references like "that", "it", "this code", or "the earlier answer" from the available history.
- If the request is ambiguous and a wrong assumption would be risky, ask a focused clarifying question.
- For coding, math, UI/UX, planning, writing, and analysis tasks, give logically structured answers with actionable next steps.
- Avoid repetitive openings, robotic disclaimers, and unnecessary restatement of the user's question.
- When you do not know something or the supplied context is insufficient, say so plainly and ask for what is needed.

Continuity rules:
- Do not claim you cannot see previous messages when prior messages are provided.
- Do not repeat the whole conversation history.
- Keep markdown readable, and use code blocks for code.
- When providing answers based on research, real-time facts, documentation, or external data, include authoritative sources at the end formatted as:
### Sources
- [Source Title](https://source-url.com)
''';

  static const String _plagiarismSystemPrompt = '''
You are an expert linguistic plagiarism detection AI. Your job is to analyze text for signs of plagiarism, paraphrasing, AI-generated content, and linguistic anomalies.

You MUST respond ONLY with a valid JSON object in this exact format, no other text:
{
  "plagiarism_score": <0-100 integer>,
  "originality_score": <0-100 integer>,
  "overall_assessment": "<detailed assessment string>",
  "detected_language": "<detected language>",
  "language_style": "<academic/casual/technical/journalistic/creative>",
  "word_count": <integer>,
  "suspicious_sections": [
    {
      "text": "<excerpt of suspicious text>",
      "reason": "<why this is suspicious>",
      "confidence_level": <0-100>,
      "suggestion": "<improvement suggestion>"
    }
  ],
  "key_findings": ["<finding1>", "<finding2>", "<finding3>"],
  "detailed_analysis": {
    "sentence_complexity": "<low/medium/high>",
    "vocabulary_diversity": <0-100>,
    "ai_generated_probability": <0-100>,
    "paraphrasing_detected": <true/false>,
    "style_consistency": <0-100>,
    "citation_needed_count": <integer>
  },
  "timestamp": "<ISO timestamp>"
}''';

  void cancelActiveRequest() {
    _cloudFunctionService.cancelActiveRequest();
  }

  // ---------------------------------------------------------------------------
  // Classification
  // ---------------------------------------------------------------------------

  Future<ClassificationResult> classifyMessage({
    required String message,
    required List<Map<String, dynamic>> history,
  }) async {
    final contextMessages =
        history.length > 6 ? history.sublist(history.length - 6) : history;

    try {
      final result = await _cloudFunctionService.classifyMessage(
        message: message,
        history: contextMessages,
        systemPrompt: _classifierSystemPrompt,
      );
      return ClassificationResult.fromJson(result);
    } catch (e) {
      debugPrint('ClassifyMessage error: $e');
      return ClassificationResult.fallbackText();
    }
  }

  // ---------------------------------------------------------------------------
  // Image Generation
  // ---------------------------------------------------------------------------

  Future<String> generateImage({
    required String prompt,
    String? size,
    List<Map<String, dynamic>>? chatHistory,
    String? imageUrl,
  }) async {
    try {
      return await _cloudFunctionService.generateImage(
        prompt: prompt,
        size: size ?? '1024x1792',
        model: 'gpt-image-2',
        quality: 'high',
        chatHistory: chatHistory,
        imageUrl: imageUrl,
      );
    } on AppException catch (e) {
      throw AppException('Image generation failed: ${e.message}');
    } on TimeoutException {
      throw const AppException('Image generation timed out. Please try again.');
    }
  }

  Future<String> generateImageEdit({
    required String prompt,
    String? imageBase64,
    String? referenceImageBase64,
    String? imageUrl,
    String mimeType = 'image/jpeg',
    String? referenceMimeType,
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    debugPrint(
        '[ImageEdit][RemoteDataSource] generateImageEdit requested for: "$prompt" (hasRef=${referenceImageBase64 != null})');
    try {
      return await _cloudFunctionService.generateImageEdit(
        prompt: prompt,
        imageBase64: imageBase64,
        referenceImageBase64: referenceImageBase64,
        imageUrl: imageUrl,
        mimeType: mimeType,
        referenceMimeType: referenceMimeType,
        chatHistory: chatHistory,
      );
    } on AppException catch (e) {
      debugPrint('[ImageEdit][RemoteDataSource] AppException: ${e.message}');
      throw AppException('Image edit failed: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint('[ImageEdit][RemoteDataSource] TimeoutException: $e');
      throw const AppException('Image edit timed out. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Upload user attachment to Firebase Storage for persistence
  // ---------------------------------------------------------------------------

  Future<String> uploadAttachmentToStorage({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    try {
      return await _cloudFunctionService.uploadAttachmentToStorage(
        uid: '', // uid is resolved server-side from auth
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
    } catch (e) {
      debugPrint('[RemoteDataSource] uploadAttachmentToStorage failed: $e');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Meme Generation (MEME_API_KEY + Veo 3.1 & GIF)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> generateMeme({
    required String prompt,
    String? imageBase64,
    String? mimeType,
    String format = 'video',
    List<Map<String, dynamic>>? chatHistory,
  }) async {
    debugPrint(
      '[MemeCreation][RemoteDataSource] generateMeme requested. '
      'prompt: "$prompt", hasImage: ${imageBase64 != null && imageBase64.isNotEmpty}, '
      'format: $format',
    );
    try {
      final res = await _cloudFunctionService.generateMeme(
        prompt: prompt,
        imageBase64: imageBase64,
        mimeType: mimeType,
        format: format,
        chatHistory: chatHistory,
      );
      debugPrint(
          '[MemeCreation][RemoteDataSource] generateMeme response: $res');
      return res;
    } on AppException catch (e) {
      debugPrint('[MemeCreation][RemoteDataSource] AppException: ${e.message}');
      throw AppException('Meme generation failed: ${e.message}');
    } on TimeoutException catch (e) {
      debugPrint('[MemeCreation][RemoteDataSource] TimeoutException: $e');
      throw const AppException('Meme generation timed out. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Plagiarism Analysis
  // ---------------------------------------------------------------------------

  Future<PlagiarismResultModel> analyzePlagiarism({
    required String text,
    required String sourceText,
  }) async {
    final wordCount = text.trim().split(RegExp(r'\s+')).length;
    final hasSource = sourceText.trim().isNotEmpty;
    final prompt = hasSource
        ? _buildComparisonPrompt(text, sourceText)
        : _buildSingleTextPrompt(text);

    final response = await _cloudFunctionService.analyzePlagiarism(
      systemPrompt: _plagiarismSystemPrompt,
      userPrompt: prompt,
    );

    final jsonStart = response.indexOf('{');
    final jsonEnd = response.lastIndexOf('}') + 1;
    if (jsonStart == -1 || jsonEnd == 0) {
      throw const AppException('Invalid response format from AI');
    }

    final jsonStr = response.substring(jsonStart, jsonEnd);
    final resultJson = jsonDecode(jsonStr) as Map<String, dynamic>;
    resultJson['word_count'] = wordCount;
    resultJson['timestamp'] = DateTime.now().toIso8601String();

    return PlagiarismResultModel.fromJson(resultJson);
  }

  // ---------------------------------------------------------------------------
  // Raw Message (grammar mode)
  // ---------------------------------------------------------------------------

  Future<String> sendRawMessage({
    required String systemPrompt,
    required String userMessage,
  }) async {
    return _cloudFunctionService.sendRawMessage(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
    );
  }

  // ---------------------------------------------------------------------------
  // Chat (non-streaming)
  // ---------------------------------------------------------------------------

  Future<String> sendChat({
    required List<Map<String, dynamic>> messages,
  }) async {
    return _cloudFunctionService.generateChat(
      messages: messages,
      systemPrompt: _chatSystemPrompt,
    );
  }

  // ---------------------------------------------------------------------------
  // Chat (streaming)
  // ---------------------------------------------------------------------------

  Stream<String> sendChatStreaming({
    required List<Map<String, dynamic>> messages,
  }) async* {
    yield* _cloudFunctionService.generateChatStreaming(
      messages: messages,
      systemPrompt: _chatSystemPrompt,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _buildSingleTextPrompt(String text) {
    return '''Analyze the following text for plagiarism, linguistic patterns, and originality.
Check for: copied content patterns, unusual phrasing that suggests copying, inconsistent writing style,
overly formal language mixed with casual, AI-generated content patterns, and lack of original voice.

TEXT TO ANALYZE:
"""
$text
"""

Provide a comprehensive plagiarism analysis in the required JSON format.''';
  }

  String _buildComparisonPrompt(String text, String sourceText) {
    return '''Compare the following TARGET TEXT against the SOURCE TEXT for plagiarism and paraphrasing.
Check for: direct copying, paraphrasing, semantic similarity, structural copying, and idea theft.

SOURCE TEXT:
"""
$sourceText
"""

TARGET TEXT (check this for plagiarism):
"""
$text
"""

Provide a detailed comparison-based plagiarism analysis in the required JSON format.''';
  }
}
