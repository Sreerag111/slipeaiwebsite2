import '../../domain/entities/chat_source.dart';

class ChatSourceModel extends ChatSource {
  const ChatSourceModel({
    required super.title,
    required super.url,
    super.domain,
    super.snippet,
    super.iconUrl,
  });

  factory ChatSourceModel.fromEntity(ChatSource entity) {
    return ChatSourceModel(
      title: entity.title,
      url: entity.url,
      domain: entity.domain,
      snippet: entity.snippet,
      iconUrl: entity.iconUrl,
    );
  }

  factory ChatSourceModel.fromJson(Map<String, dynamic> json) {
    return ChatSourceModel(
      title: json['title'] as String? ?? 'Source',
      url: json['url'] as String? ?? '',
      domain: json['domain'] as String?,
      snippet: json['snippet'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'domain': domain ?? displayDomain,
      'snippet': snippet,
      'icon_url': iconUrl ?? faviconUrl,
    };
  }
}
