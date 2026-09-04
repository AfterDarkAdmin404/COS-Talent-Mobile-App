/// A single message bubble's worth of display data — real, DB-backed
/// conversations now (`message_threads`/`messages`, migration 041), scoped
/// to one job application. [ChatBubble] renders [text], [attachment], or
/// (048) a "message deleted" tombstone when [deletedAt] is set — a message
/// is exactly one of those three, never a combination;
/// [MessageThreadSummary] carries the thread-level fields (company name,
/// job title) a list view needs instead.
library;

enum ChatAttachmentKind { image, file }

class ChatAttachment {
  final String storagePath;
  final ChatAttachmentKind kind;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  const ChatAttachment({
    required this.storagePath,
    required this.kind,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });
}

class ChatMessage {
  /// `messages.id`/`direct_messages.id` — needed as a stable `ValueKey` in
  /// the thread screens' `ListView.builder`: `streamMessages` re-emits the
  /// *whole* list on every new message, and without a stable key each
  /// bubble (including any image already loaded) would remount and
  /// re-fetch its signed URL every time. Also what edit/delete act on.
  final int id;
  final String? text;
  final ChatAttachment? attachment;
  final bool fromMe;
  final DateTime time;
  /// Server-stamped (048's `set_messages_edited_at`/
  /// `set_direct_messages_edited_at` trigger) whenever [text] was changed
  /// after the message was first sent -- never client-set, so it can't be
  /// hidden by whoever edited it.
  final DateTime? editedAt;
  /// A tombstone: the sender deleted this message. [text] and [attachment]
  /// are both null when this is set -- render "This message was deleted."
  /// instead of their content.
  final DateTime? deletedAt;

  const ChatMessage({
    required this.id,
    this.text,
    this.attachment,
    required this.fromMe,
    required this.time,
    this.editedAt,
    this.deletedAt,
  }) : assert(
         deletedAt != null || text != null || attachment != null,
         'a live message needs text or an attachment',
       );

  bool get isDeleted => deletedAt != null;
}
