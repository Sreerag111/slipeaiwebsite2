class DocumentExtractionResult {
  const DocumentExtractionResult({
    required this.text,
    required this.pageCount,
    this.usedOcr = false,
    this.error,
  });

  final String text;
  final int pageCount;
  final bool usedOcr;
  final String? error;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasError => error != null;
}

