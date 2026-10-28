class ChatSource {
  const ChatSource({
    required this.title,
    required this.url,
    this.domain,
    this.snippet,
    this.iconUrl,
  });

  final String title;
  final String url;
  final String? domain;
  final String? snippet;
  final String? iconUrl;

  /// Returns the display domain (e.g. "wikipedia.org", "techcrunch.com").
  String get displayDomain {
    if (domain != null && domain!.trim().isNotEmpty) {
      return domain!.trim();
    }
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      if (host.startsWith('www.')) {
        return host.substring(4);
      }
      return host.isNotEmpty ? host : 'web';
    } catch (_) {
      return 'web';
    }
  }

  /// Returns a favicon URL using Google's public favicon service.
  String get faviconUrl {
    if (iconUrl != null && iconUrl!.trim().isNotEmpty) {
      return iconUrl!.trim();
    }
    final d = displayDomain;
    return 'https://www.google.com/s2/favicons?domain=$d&sz=64';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSource &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          title == other.title;

  @override
  int get hashCode => url.hashCode ^ title.hashCode;
}
