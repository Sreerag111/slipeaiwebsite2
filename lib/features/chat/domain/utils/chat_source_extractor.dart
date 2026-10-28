import '../entities/chat_source.dart';

class ExtractedChatContent {
  const ExtractedChatContent({
    required this.cleanedText,
    required this.sources,
  });

  final String cleanedText;
  final List<ChatSource> sources;
}

abstract final class ChatSourceExtractor {
  /// Regex matching markdown links: [Title](https://...)
  static final RegExp _markdownLinkRegex = RegExp(
    r'\[([^\]]+)\]\((https?:\/\/[^\s\)]+)\)',
    caseSensitive: false,
  );

  /// Regex matching trailing Sources/References section
  static final RegExp _sourcesSectionRegex = RegExp(
    r'(?:\r?\n)+(?:#{1,4}\s*)?(?:Sources|References|Citations|External Links)\s*:?\s*\n+([\s\S]+)$',
    caseSensitive: false,
  );

  /// Regex matching raw URLs
  static final RegExp _rawUrlRegex = RegExp(
    r'(?<!\()(https?:\/\/[a-zA-Z0-9\-._~:/?#\[\]@!$&()*+,;=%]+[a-zA-Z0-9/])',
    caseSensitive: false,
  );

  /// Extracts structured [ChatSource]s from raw AI text and returns both the
  /// parsed sources and a cleaned version of the text.
  static ExtractedChatContent extract(String rawText, {List<ChatSource>? existingSources}) {
    if (rawText.isEmpty) {
      return ExtractedChatContent(
        cleanedText: rawText,
        sources: existingSources ?? const [],
      );
    }

    final sourcesMap = <String, ChatSource>{};

    // 1. Add any explicitly provided sources first
    if (existingSources != null) {
      for (final s in existingSources) {
        final cleanUrl = _normalizeUrl(s.url);
        if (cleanUrl.isNotEmpty) {
          sourcesMap[cleanUrl] = s;
        }
      }
    }

    String cleanedText = rawText;

    // 2. Check for a dedicated "Sources" / "References" section at the end
    final sourcesSectionMatch = _sourcesSectionRegex.firstMatch(rawText);
    if (sourcesSectionMatch != null) {
      final sectionBody = sourcesSectionMatch.group(1) ?? '';
      
      // Extract markdown links from the section
      for (final match in _markdownLinkRegex.allMatches(sectionBody)) {
        final title = match.group(1)?.trim() ?? '';
        final url = match.group(2)?.trim() ?? '';
        _addSource(sourcesMap, title: title, url: url);
      }

      // Extract raw URLs from the section
      for (final match in _rawUrlRegex.allMatches(sectionBody)) {
        final url = match.group(1)?.trim() ?? '';
        _addSource(sourcesMap, title: _titleFromUrl(url), url: url);
      }

      // If we extracted at least one source from the section, trim the section from text
      if (sourcesMap.isNotEmpty) {
        cleanedText = rawText.substring(0, sourcesSectionMatch.start).trimRight();
      }
    }

    // 3. Also scan the full text for markdown links (e.g. [BBC News](https://bbc.com))
    for (final match in _markdownLinkRegex.allMatches(rawText)) {
      final title = match.group(1)?.trim() ?? '';
      final url = match.group(2)?.trim() ?? '';
      // Exclude inline anchors or image markdown
      if (!title.startsWith('!') && _isValidHttpUrl(url)) {
        _addSource(sourcesMap, title: title, url: url);
      }
    }

    return ExtractedChatContent(
      cleanedText: cleanedText,
      sources: sourcesMap.values.toList(growable: false),
    );
  }

  static void _addSource(
    Map<String, ChatSource> map, {
    required String title,
    required String url,
    String? snippet,
  }) {
    final cleanUrl = _normalizeUrl(url);
    if (cleanUrl.isEmpty || !_isValidHttpUrl(cleanUrl)) return;

    // Filter out common non-research or internal anchors
    if (cleanUrl.contains('localhost') || cleanUrl.contains('127.0.0.1')) return;

    final existing = map[cleanUrl];
    if (existing == null) {
      map[cleanUrl] = ChatSource(
        title: title.isNotEmpty ? title : _titleFromUrl(cleanUrl),
        url: cleanUrl,
        snippet: snippet,
      );
    } else if (existing.title.length < title.length && title.isNotEmpty) {
      // Prefer longer, more descriptive titles
      map[cleanUrl] = ChatSource(
        title: title,
        url: cleanUrl,
        snippet: snippet ?? existing.snippet,
      );
    }
  }

  static String _normalizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('.') || trimmed.endsWith(',') || trimmed.endsWith(';')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool _isValidHttpUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String _titleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase().replaceFirst('www.', '');
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        final last = segments.last
            .replaceAll(RegExp(r'[-_]'), ' ')
            .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
        if (last.trim().length > 3) {
          return '$last · $host';
        }
      }
      return host.isNotEmpty ? host : 'Web Source';
    } catch (_) {
      return 'Web Source';
    }
  }
}
