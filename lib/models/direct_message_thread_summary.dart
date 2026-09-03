import 'chat_message.dart';

/// One row of the candidate's direct-message inbox — a
/// `direct_message_threads` row (042) keyed by (employer_company_id,
/// talent_profile_id), not a job application. Same shape as
/// [MessageThreadSummary], reused for the merged inbox list in
/// MessagesScreen rather than shared with it — the two are backed by
/// different tables with different join paths.
class DirectMessageThreadSummary {
  final int employerCompanyId;
  final String companyName;
  final ChatMessage? lastMessage;

  const DirectMessageThreadSummary({
    required this.employerCompanyId,
    required this.companyName,
    this.lastMessage,
  });

  /// Expects
  /// `.select('employer_company_id, employer_companies(company_name), direct_messages(body, sender_kind, created_at)')`
  /// with the `direct_messages` embed ordered/limited to the single latest row.
  factory DirectMessageThreadSummary.fromRow(Map<String, dynamic> row) {
    final company = row['employer_companies'] as Map<String, dynamic>?;
    final messages = row['direct_messages'] as List?;
    final lastRow = messages != null && messages.isNotEmpty ? messages.first as Map<String, dynamic> : null;
    return DirectMessageThreadSummary(
      employerCompanyId: row['employer_company_id'] as int,
      companyName: company?['company_name'] as String? ?? 'A COS-vetted employer',
      lastMessage: lastRow == null
          ? null
          : ChatMessage(
              text: lastRow['body'] as String,
              fromMe: lastRow['sender_kind'] == 'candidate',
              time: DateTime.parse(lastRow['created_at'] as String),
            ),
    );
  }
}
