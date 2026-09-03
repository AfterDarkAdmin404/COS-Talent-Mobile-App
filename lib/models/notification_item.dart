/// One row of `public.notifications` (044), joined with just enough of the
/// counterpart employer's name to render a feed row — same "just enough
/// joined in" posture as [MessageThreadSummary]/[DirectMessageThreadSummary].
class NotificationItem {
  final int id;
  final String threadKind; // 'application' | 'direct'
  final String bodyPreview;
  final bool isRead;
  final DateTime createdAt;
  final String companyName;
  /// Set when [threadKind] is 'application' — what [ApplicationThreadScreen]
  /// needs to open the right conversation.
  final int? jobApplicationId;
  /// Set when [threadKind] is 'direct' — what [DirectMessageThreadScreen]
  /// needs to open the right conversation.
  final int? employerCompanyId;

  const NotificationItem({
    required this.id,
    required this.threadKind,
    required this.bodyPreview,
    required this.isRead,
    required this.createdAt,
    required this.companyName,
    this.jobApplicationId,
    this.employerCompanyId,
  });

  /// Expects
  /// `.select('id, thread_kind, body_preview, is_read, created_at,
  ///   message_threads(job_application_id, job_applications(job_postings(employer_companies(company_name)))),
  ///   direct_message_threads(employer_company_id, employer_companies(company_name))')`.
  factory NotificationItem.fromRow(Map<String, dynamic> row) {
    final threadKind = row['thread_kind'] as String;
    String companyName = 'A COS-vetted employer';
    int? jobApplicationId;
    int? employerCompanyId;

    Map<String, dynamic>? companyRow;
    if (threadKind == 'application') {
      final thread = row['message_threads'] as Map<String, dynamic>?;
      jobApplicationId = thread?['job_application_id'] as int?;
      final application = thread?['job_applications'] as Map<String, dynamic>?;
      final posting = application?['job_postings'] as Map<String, dynamic>?;
      companyRow = posting?['employer_companies'] as Map<String, dynamic>?;
    } else {
      final thread = row['direct_message_threads'] as Map<String, dynamic>?;
      employerCompanyId = thread?['employer_company_id'] as int?;
      companyRow = thread?['employer_companies'] as Map<String, dynamic>?;
    }
    final name = companyRow?['company_name'] as String?;
    if (name != null) companyName = name;

    return NotificationItem(
      id: row['id'] as int,
      threadKind: threadKind,
      bodyPreview: row['body_preview'] as String,
      isRead: row['is_read'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
      companyName: companyName,
      jobApplicationId: jobApplicationId,
      employerCompanyId: employerCompanyId,
    );
  }
}
