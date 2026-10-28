/// API keys are now managed server-side via Firebase Cloud Functions.
/// This use case is retained for backwards compatibility but always returns empty.
class GetOpenAiApiKeyUseCase {
  const GetOpenAiApiKeyUseCase();

  String call() => '';
}
