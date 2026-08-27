/// A candidate's chat is always with COS staff, never with an employer
/// directly — every employer contact is brokered
/// (threat-model.md:245: Tier 3 data "never reachable by any employer
/// path"). This is the in-app surface for that brokering, not a
/// peer-to-peer thread. Real message tables are Phase 3
/// (data-model.md:608); this runs on local mock state.
class ChatMessage {
  final String text;
  final bool fromMe;
  final DateTime time;

  const ChatMessage({required this.text, required this.fromMe, required this.time});
}
