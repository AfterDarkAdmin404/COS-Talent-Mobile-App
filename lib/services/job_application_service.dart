import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_application.dart';

/// Reads and writes `public.job_applications` and appends to
/// `public.job_application_events` (038). talent_app only ever inserts —
/// `status` moves through the ATS pipeline on the employer/staff side, this
/// app never updates a submitted application.
class JobApplicationService {
  JobApplicationService._();
  static final _client = Supabase.instance.client;

  /// One application per (job_posting_id, talent_profile_id) — the unique
  /// index in 038 rejects a second submission outright rather than this
  /// service checking first and racing.
  static Future<JobApplication> apply({
    required int jobPostingId,
    required int talentProfileId,
    String? coverNote,
  }) async {
    final row = await _client
        .from('job_applications')
        .insert({
          'job_posting_id': jobPostingId,
          'talent_profile_id': talentProfileId,
          if (coverNote != null && coverNote.trim().isNotEmpty) 'cover_note': coverNote.trim(),
        })
        .select()
        .single();
    final application = JobApplication.fromRow(row);

    // Best-effort audit entry — PLAN.md:363 named this table explicitly.
    // Not awaited-and-rethrown on failure: a missing event row is a gap in
    // the audit trail, not a reason to tell the candidate her application
    // didn't go through when it did.
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client.from('job_application_events').insert({
          'job_application_id': application.id,
          'actor_kind': 'candidate',
          'actor_marketplace_user_id': userId,
          'event_type': 'application_submitted',
          'summary': 'Application submitted.',
        });
      } catch (_) {
        // See comment above.
      }
    }

    return application;
  }

  /// This candidate's applications, most recent first. The embedded
  /// job_postings/employer_companies fields come back null if the posting
  /// was unpublished after she applied — job_postings_select_published only
  /// covers the currently-live case, not "a job I once applied to." Shown
  /// as a generic fallback in the UI rather than fixed with a wider policy,
  /// since this is a genuinely rare edge case, not the common path.
  static Future<List<JobApplication>> fetchMine(int talentProfileId) async {
    final rows = await _client
        .from('job_applications')
        .select('*, job_postings(title, employer_companies(company_name))')
        .eq('talent_profile_id', talentProfileId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => JobApplication.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// job_posting_id -> application for everything already applied to —
  /// cheaper than [fetchMine] for the Browse list (no job_postings /
  /// employer_companies join, since Browse already has the posting), and
  /// carries both the application id JobDetailScreen needs to open "Message
  /// employer" and the live status so Browse's badge doesn't freeze at
  /// "Applied" once the employer moves it along the pipeline.
  static Future<Map<int, JobApplication>> fetchMineByPosting(int talentProfileId) async {
    final rows = await _client
        .from('job_applications')
        .select('id, job_posting_id, status')
        .eq('talent_profile_id', talentProfileId);
    return {
      for (final r in (rows as List))
        (r as Map<String, dynamic>)['job_posting_id'] as int: JobApplication.fromRow(r),
    };
  }
}
