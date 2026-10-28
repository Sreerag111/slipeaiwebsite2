import 'plagiarism_result.dart';

class ChatCompletionResult {
  const ChatCompletionResult({
    required this.prompt,
    required this.response,
  });

  final String prompt;
  final String response;
}

class PlagiarismAnalysisResult {
  const PlagiarismAnalysisResult({
    required this.analyzedText,
    required this.result,
  });

  final String analyzedText;
  final PlagiarismResult result;
}

