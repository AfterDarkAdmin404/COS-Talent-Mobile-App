import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';

/// One thread, always with COS staff — see the model file for why
/// there's no employer contact here. Framed as coordination about the
/// candidate's own profile (review notes, interview requests), which is
/// exactly the kind of message PLAN.md's open-questions.md #4 describes
/// shipping as a message type in Phase 1, ahead of full messaging.
///
/// No own Scaffold/AppBar — this is one tab's content inside
/// [HomeShell]'s Scaffold, so the composer bar sits directly above the
/// bottom NavigationBar rather than fighting a second Scaffold for that
/// space.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hi! Thanks for submitting your profile 🎉 One of our team will '
          'review it within 1–2 business days.',
      fromMe: false,
      time: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    ChatMessage(
      text: 'Quick question — is your QuickBooks certification still current?',
      fromMe: false,
      time: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    ),
    ChatMessage(
      text: 'Yes, renewed it back in March!',
      fromMe: true,
      time: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 40)),
    ),
    ChatMessage(
      text: 'Perfect, noted. We have a US company interested in your profile — '
          'reviewing the fit now, will follow up here either way.',
      fromMe: false,
      time: DateTime.now().subtract(const Duration(hours: 20)),
    ),
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, fromMe: true, time: DateTime.now()));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          decoration: const BoxDecoration(
            color: AppColors.offWhite,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset('assets/images/logo_mark.png'),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Office Solutions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                  Text(
                    'Usually replies within a business day',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _messages.length,
            itemBuilder: (context, i) => ChatBubble(message: _messages[i]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Message the COS team…',
                      fillColor: AppColors.offWhite,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward, color: AppColors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
