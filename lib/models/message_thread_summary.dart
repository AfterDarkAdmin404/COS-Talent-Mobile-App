import 'chat_message.dart';

/// One row of the candidate's real inbox — a `message_threads` row
/// (bookkeeping/database/migrations/041_create_application_messaging.sql)
/// scoped to one of her own job applications, with the employer's company
/// name, the job title, and the last message joined in for a list view.
class MessageThreadSummary {
  final int threadId;
  final int jobApplicationId;
  final String companyName;
  final String jobTitle;
  final ChatMessage? lastMessage;

  const MessageThreadSummary({
    required this.threadId,
    required this.jobApplicationId,
    required this.companyName,
    required this.jobTitle,
    this.lastMessage,
  });

  /// Expects
  /// `.select('id, job_application_id, job_applications(job_postings(title, employer_companies(company_name))), messages(body, sender_kind, created_at)')`
  /// with the `messages` embed ordered/limited to the single latest row.
  factory MessageThreadSummary.fromRow(Map<String, dynamic> row) {
    final application = row['job_applications'] as Map<String, dynamic>?;
    final posting = application?['job_postings'] as Map<String, dynamic>?;
    final company = posting?['employer_companies'] as Map<String, dynamic>?;
    final messages = row['messages'] as List?;
    final lastRow = messages != null && messages.isNotEmpty ? messages.first as Map<String, dynamic> : null;
    return MessageThreadSummary(
      threadId: row['id'] as int,
      jobApplicationId: row['job_application_id'] as int,
      companyName: company?['company_name'] as String? ?? 'A COS-vetted employer',
      jobTitle: posting?['title'] as String? ?? 'Untitled role',
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
