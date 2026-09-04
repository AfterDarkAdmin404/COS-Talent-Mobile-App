import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/attachment_picker.dart';
import '../../widgets/chat_bubble.dart';

/// A real message thread with one employer, scoped to her application to
/// that employer's posting — see 041's header comment for why this is
/// allowed to be a direct line while the rest of this app stays
/// staff-brokered.
class ApplicationThreadScreen extends StatefulWidget {
  final int jobApplicationId;
  final String companyName;
  const ApplicationThreadScreen({super.key, required this.jobApplicationId, required this.companyName});

  @override
  State<ApplicationThreadScreen> createState() => _ApplicationThreadScreenState();
}

class _ApplicationThreadScreenState extends State<ApplicationThreadScreen> {
  final _controller = TextEditingController();
  int? _threadId;
  bool _loadingThreadId = true;
  late final Stream<List<ChatMessage>> _messagesStream;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    MessageService.findThreadId(widget.jobApplicationId).then((threadId) {
      if (!mounted) return;
      setState(() {
        _loadingThreadId = false;
        if (threadId != null) {
          _threadId = threadId;
          _messagesStream = MessageService.streamMessages(threadId);
          // Best-effort, not awaited -- known v1 gap: a message that
          // arrives later while this screen is still open won't re-clear
          // the badge, only what was already unread when it opened.
          NotificationService.markThreadRead(threadKind: 'application', threadId: threadId);
        }
      });
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final threadId = await MessageService.sendAsCandidate(jobApplicationId: widget.jobApplicationId, body: text);
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _sending = false;
        // Live stream already reflects the new row for an existing thread;
        // this only matters the first time, to leave the empty state.
        if (_threadId == null) {
          _threadId = threadId;
          _messagesStream = MessageService.streamMessages(threadId);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Couldn\'t send that. $e';
      });
    }
  }

  Future<void> _pickAndSendAttachment() async {
    if (_sending) return;
    final picked = await pickChatAttachment(context);
    if (picked == null || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final threadId = await MessageService.sendAttachmentAsCandidate(
        jobApplicationId: widget.jobApplicationId,
        file: picked.file,
        kind: picked.kind,
        fileName: picked.fileName,
        mimeType: picked.mimeType,
        sizeBytes: picked.sizeBytes,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        // Live stream already reflects the new row for an existing thread;
        // this only matters the first time, to leave the empty state.
        if (_threadId == null) {
          _threadId = threadId;
          _messagesStream = MessageService.streamMessages(threadId);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Couldn\'t send that. $e';
      });
    }
  }

  Future<void> _editMessage(ChatMessage message) async {
    final editController = TextEditingController(text: message.text);
    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(editController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Deferred, not immediate: the dialog's own closing transition can
    // still be rebuilding this TextField for a frame after showDialog's
    // Future resolves (Navigator.pop() doesn't wait for the exit
    // animation) -- disposing the controller right here raced that
    // rebuild and crashed with a "ChangeNotifier used after dispose"
    // element-tree assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) => editController.dispose());
    final trimmed = newText?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == message.text || !mounted) return;
    try {
      await MessageService.editMessage(messageId: message.id, body: trimmed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t save that edit. $e')));
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this message?'),
        content: const Text('The other person will see that a message was deleted, not its content.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await MessageService.deleteMessage(message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn\'t delete that message. $e')));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _messagesBody() {
    if (_loadingThreadId) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_threadId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Send a message to start the conversation with ${widget.companyName}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return StreamBuilder<List<ChatMessage>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Couldn\'t load this conversation. ${snapshot.error}',
                style: const TextStyle(color: AppColors.statusRejected),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final messages = snapshot.data!;
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Send a message to start the conversation with ${widget.companyName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final message = messages[messages.length - 1 - i];
            // Stable key: streamMessages re-emits the whole list on every
            // new message, and without this every bubble (including any
            // image already loaded) would remount and re-fetch its signed
            // URL each time.
            return ChatBubble(
              key: ValueKey(message.id),
              message: message,
              onEdit: message.fromMe && !message.isDeleted && message.attachment == null
                  ? () => _editMessage(message)
                  : null,
              onDelete: message.fromMe && !message.isDeleted ? () => _deleteMessage(message) : null,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: Text(widget.companyName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _messagesBody()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(_error!, style: const TextStyle(color: AppColors.statusRejected, fontSize: 12.5)),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Attach',
                    onPressed: _sending ? null : _pickAndSendAttachment,
                    icon: const Icon(Icons.attach_file, color: AppColors.navyLight),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message ${widget.companyName}…',
                        fillColor: AppColors.offWhite,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : const Icon(Icons.arrow_upward, color: AppColors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
