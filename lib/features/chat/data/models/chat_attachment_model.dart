import '../../domain/entities/chat_attachment.dart';

class ChatAttachmentModel extends ChatAttachment {
  const ChatAttachmentModel({
    required super.path,
    required super.name,
    required super.type,
    super.extension,
  });

  factory ChatAttachmentModel.fromEntity(ChatAttachment attachment) {
    return ChatAttachmentModel(
      path: attachment.path,
      name: attachment.name,
      type: attachment.type,
      extension: attachment.extension,
    );
  }

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentModel(
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] == 'image'
          ? ChatAttachmentType.image
          : ChatAttachmentType.file,
      extension: json['extension'],
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'type': type == ChatAttachmentType.image ? 'image' : 'file',
        'extension': extension,
      };
}

