import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

enum _MessageAction { edit, delete }

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  /// Non-null only for the sender's own, non-deleted messages -- see the
  /// thread screens' `itemBuilder` for where that's decided. `null` means
  /// long-press does nothing (048).
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const ChatBubble({super.key, required this.message, this.onEdit, this.onDelete});

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  Future<void> _showActions(BuildContext context) async {
    if (onEdit == null && onDelete == null) return;
    // Return which action was picked and invoke the callback only after
    // showModalBottomSheet's own await resolves -- i.e. once the sheet's
    // route has actually finished closing. Popping the sheet and invoking
    // onEdit/onDelete synchronously in the same tap (onEdit opens another
    // route, showDialog) raced the sheet's own closing transition and
    // could crash with a "not attached"/"_dependents.isEmpty" element-tree
    // assertion -- two overlapping Navigator route transitions, not
    // anything specific to edit vs delete.
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.of(sheetContext).pop(_MessageAction.edit),
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                title: const Text('Delete', style: TextStyle(color: AppColors.statusRejected)),
                onTap: () => Navigator.of(sheetContext).pop(_MessageAction.delete),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _MessageAction.edit:
        onEdit?.call();
      case _MessageAction.delete:
        onDelete?.call();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    final attachment = message.attachment;
    Widget bubble;
    if (message.isDeleted) {
      bubble = Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy.withValues(alpha: 0.5) : AppColors.offWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          'This message was deleted',
          style: TextStyle(
            color: mine ? AppColors.white.withValues(alpha: 0.8) : AppColors.muted,
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    } else if (attachment != null) {
      bubble = _AttachmentBubble(attachment: attachment, mine: mine);
    } else {
      bubble = Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          message.text!,
          style: TextStyle(
            color: mine ? AppColors.white : AppColors.ink,
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(onLongPress: () => _showActions(context), child: bubble),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              message.editedAt != null ? '${_time(message.time)} · edited' : _time(message.time),
              style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens a signed URL externally (browser / photo viewer / Office app) —
/// same `launchUrl(..., mode: LaunchMode.externalApplication)` call and
/// SnackBar-on-failure idiom as `candidate_detail_screen.dart`'s
/// `_viewResume` in employer_app, just for the `message-attachments`
/// bucket instead of `talent-documents`.
Future<void> _openAttachment(BuildContext context, ChatAttachment attachment) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final url = await StorageService.messageAttachmentSignedUrl(attachment.storagePath);
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Couldn\'t open that attachment.')));
    }
  } catch (e) {
    debugPrint('messageAttachmentSignedUrl(${attachment.storagePath}) failed: $e');
    if (!context.mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Couldn\'t load that attachment — try again shortly.')));
  }
}

class _AttachmentBubble extends StatelessWidget {
  final ChatAttachment attachment;
  final bool mine;
  const _AttachmentBubble({required this.attachment, required this.mine});

  @override
  Widget build(BuildContext context) {
    if (attachment.kind == ChatAttachmentKind.image) {
      return _ImageThumbnail(attachment: attachment);
    }
    return GestureDetector(
      onTap: () => _openAttachment(context, attachment),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 20, color: mine ? AppColors.white : AppColors.navyLight),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                attachment.fileName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: mine ? AppColors.white : AppColors.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fetches its signed URL once, in [initState] — not a bare `FutureBuilder`
/// inline in a stateless bubble — so a re-emitted message list (every
/// `streamMessages` update re-emits the *whole* thread) doesn't re-sign an
/// already-loaded image. `ChatBubble`'s `ValueKey(message.id)` in the
/// thread screens' `ListView.builder` is what keeps this widget's state
/// across those rebuilds in the first place.
class _ImageThumbnail extends StatefulWidget {
  final ChatAttachment attachment;
  const _ImageThumbnail({required this.attachment});

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  late final Future<String> _urlFuture = StorageService.messageAttachmentSignedUrl(widget.attachment.storagePath);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        onTap: () => _openAttachment(context, widget.attachment),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220, minWidth: 140, minHeight: 140),
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.offWhite,
          child: FutureBuilder<String>(
            future: _urlFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              return Image.network(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined, color: AppColors.muted),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
