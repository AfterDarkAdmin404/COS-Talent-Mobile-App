import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
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
              message.text,
              style: TextStyle(
                color: mine ? AppColors.white : AppColors.ink,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _time(message.time),
              style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}
