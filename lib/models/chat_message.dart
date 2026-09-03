/// A single message bubble's worth of display data — real, DB-backed
/// conversations now (`message_threads`/`messages`, migration 041), scoped
/// to one job application. Kept intentionally minimal (no thread/sender
/// metadata) since [ChatBubble] only ever needs text/fromMe/time to render
/// one bubble; [MessageThreadSummary] carries the thread-level fields
/// (company name, job title) a list view needs instead.
class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;

  const ChatMessage({required this.text, required this.fromMe, required this.time});
}
