/// Mirrors `public.job_applications`
/// (`bookkeeping/database/migrations/038_create_job_postings_and_applications.sql`).
library;

enum ApplicationStatus { submitted, underReview, interviewing, offerExtended, hired, rejected, withdrawn }

extension ApplicationStatusLabel on ApplicationStatus {
  String get label => switch (this) {
    ApplicationStatus.submitted => 'Submitted',
    ApplicationStatus.underReview => 'Under review',
    ApplicationStatus.interviewing => 'Interviewing',
    ApplicationStatus.offerExtended => 'Offer extended',
    ApplicationStatus.hired => 'Hired',
    ApplicationStatus.rejected => 'Not selected',
    ApplicationStatus.withdrawn => 'Withdrawn',
  };
}

extension ApplicationStatusDb on ApplicationStatus {
  String get dbValue => switch (this) {
    ApplicationStatus.submitted => 'submitted',
    ApplicationStatus.underReview => 'under_review',
    ApplicationStatus.interviewing => 'interviewing',
    ApplicationStatus.offerExtended => 'offer_extended',
    ApplicationStatus.hired => 'hired',
    ApplicationStatus.rejected => 'rejected',
    ApplicationStatus.withdrawn => 'withdrawn',
  };

  static ApplicationStatus fromDb(String value) => switch (value) {
    'under_review' => ApplicationStatus.underReview,
    'interviewing' => ApplicationStatus.interviewing,
    'offer_extended' => ApplicationStatus.offerExtended,
    'hired' => ApplicationStatus.hired,
    'rejected' => ApplicationStatus.rejected,
    'withdrawn' => ApplicationStatus.withdrawn,
    _ => ApplicationStatus.submitted,
  };
}

class JobApplication {
  final int id;
  final int jobPostingId;
  final ApplicationStatus status;
  final String? jobTitle;
  final String? companyName;
  final DateTime? createdAt;

  const JobApplication({
    required this.id,
    required this.jobPostingId,
    required this.status,
    this.jobTitle,
    this.companyName,
    this.createdAt,
  });

  /// Expects `.select('*, job_postings(title, employer_companies(company_name))')`.
  factory JobApplication.fromRow(Map<String, dynamic> row) {
    final postingRow = row['job_postings'] as Map<String, dynamic>?;
    final companyRow = postingRow?['employer_companies'] as Map<String, dynamic>?;
    return JobApplication(
      id: row['id'] as int,
      jobPostingId: row['job_posting_id'] as int,
      status: ApplicationStatusDb.fromDb(row['status'] as String? ?? 'submitted'),
      jobTitle: postingRow?['title'] as String?,
      companyName: companyRow?['company_name'] as String?,
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : null,
    );
  }
}
