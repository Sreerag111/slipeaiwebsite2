enum ChatAttachmentType { image, file }

class ChatAttachment {
  const ChatAttachment({
    required this.path,
    required this.name,
    required this.type,
    this.extension,
  });

  final String path;
  final String name;
  final ChatAttachmentType type;
  final String? extension;

  bool get isImage => type == ChatAttachmentType.image;
  bool get isFile => type == ChatAttachmentType.file;
}

