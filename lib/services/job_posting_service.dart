import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job_posting.dart';

/// Read-only: talent_app never writes to `job_postings`. Relies on
/// `job_postings_select_published` (038) for row visibility and
/// `employer_companies_select_via_published_posting` (039) for the
/// embedded company name — without 039, `employer_companies` would come
/// back null for every row here, since its only other SELECT policy is
/// owner-scoped.
class JobPostingService {
  JobPostingService._();
  static final _client = Supabase.instance.client;

  static Future<List<JobPosting>> fetchPublished() async {
    final rows = await _client
        .from('job_postings')
        .select('*, talent_categories(name), employer_companies(company_name)')
        .eq('is_public', true)
        .eq('status', 'approved')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => JobPosting.fromRow(r as Map<String, dynamic>)).toList();
  }
}
