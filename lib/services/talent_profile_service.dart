import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill.dart';
import '../models/talent_category.dart';
import '../models/talent_profile.dart';

/// Writes the completed wizard into the real `talent_profiles` table.
///
/// **Unverified assumption, flagged rather than silently baked in:** this
/// assumes `marketplace_users.id` equals the signed-in Supabase Auth
/// user's id (`auth.uid()`) — the common pattern where a trigger on
/// `auth.users` mirrors a row into `public.marketplace_users` on signup.
/// `talent_profiles.marketplace_user_id` has a hard FK to
/// `marketplace_users(id)`, so if that mirror table works differently
/// (a separately generated id, or no row created automatically), this
/// insert fails on `talent_profiles_marketplace_user_id_fkey` — not
/// silently, but it will fail. Confirm the `marketplace_users` schema
/// before relying on this in front of a real user.
///
/// Every method here takes an immutable [TalentProfile] and *returns* the
/// updated one — nothing is mutated in place, since these profiles are
/// bloc state now.
class TalentProfileService {
  TalentProfileService._();
  static final _client = Supabase.instance.client;

  static Future<TalentProfile> submitForReview(TalentProfile profile) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Must be signed in to submit a profile.');
    }
    var next = profile.copyWith(
      marketplaceUserId: userId,
      publicSlug: profile.publicSlug ?? generatePublicSlug(profile.firstName, profile.lastName),
    );
    next = next.copyWith(profileCompleteness: next.computedCompleteness);

    final row = await _client
        .from('talent_profiles')
        .insert(next.toInsertRow())
        .select()
        .single();
    next = next.copyWith(id: row['id'] as int);
    await _syncSkills(next.id!, next.skills);
    await _syncCategories(next.id!, next.categories);
    await _syncLinks(next.id!, next.links);
    await _syncEducation(next.id!, next.education);
    await _syncCertifications(next.id!, next.certifications);
    return next;
  }

  static Future<TalentProfile> updateProfile(TalentProfile profile) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Must be signed in to update a profile.');
    }
    assert(profile.id != null, 'profile.id must be set before updating — it comes from submitForReview or fetchCurrent');
    final next = profile.copyWith(profileCompleteness: profile.computedCompleteness);
    await _client
        .from('talent_profiles')
        .update(next.toUpdateRow())
        .eq('marketplace_user_id', userId);
    await _syncSkills(next.id!, next.skills);
    await _syncCategories(next.id!, next.categories);
    await _syncLinks(next.id!, next.links);
    await _syncEducation(next.id!, next.education);
    await _syncCertifications(next.id!, next.certifications);
    return next;
  }

  /// Replaces the full skill selection rather than diffing it — simpler
  /// and just as correct for a plain join table with no extra columns.
  static Future<void> _syncSkills(int talentProfileId, List<Skill> skills) async {
    await _client.from('talent_profile_skills').delete().eq('talent_profile_id', talentProfileId);
    if (skills.isEmpty) return;
    await _client
        .from('talent_profile_skills')
        .insert(skills.map((s) => {'talent_profile_id': talentProfileId, 'skill_id': s.id}).toList());
  }

  /// Same replace-the-whole-set approach as [_syncSkills]. `is_primary`
  /// is left at its DB default (false) — there's no "pick a primary
  /// category" UI yet.
  static Future<void> _syncCategories(int talentProfileId, List<TalentCategory> categories) async {
    await _client.from('talent_profile_categories').delete().eq('talent_profile_id', talentProfileId);
    if (categories.isEmpty) return;
    await _client
        .from('talent_profile_categories')
        .insert(categories.map((c) => {'talent_profile_id': talentProfileId, 'category_id': c.id}).toList());
  }

  /// Same replace-the-whole-set approach, but this table isn't a lookup
  /// join — `kind`/`url`/`is_public` are the candidate's own data, not a
  /// reference to another table, so there's no id to preserve on write.
  static Future<void> _syncLinks(int talentProfileId, List<TalentProfileLink> links) async {
    await _client.from('talent_profile_links').delete().eq('talent_profile_id', talentProfileId);
    if (links.isEmpty) return;
    await _client.from('talent_profile_links').insert(
      links
          .map(
            (l) => {
              'talent_profile_id': talentProfileId,
              'kind': l.kind.dbValue,
              'url': l.url,
              'is_public': l.isPublic,
            },
          )
          .toList(),
    );
  }

  static Future<List<TalentProfileLink>> _fetchLinks(int talentProfileId) async {
    final rows = await _client
        .from('talent_profile_links')
        .select()
        .eq('talent_profile_id', talentProfileId);
    return (rows as List)
        .map((r) => TalentProfileLink.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Same replace-the-whole-set approach as [_syncLinks].
  static Future<void> _syncEducation(int talentProfileId, List<TalentEducationEntry> education) async {
    await _client.from('talent_education').delete().eq('talent_profile_id', talentProfileId);
    if (education.isEmpty) return;
    await _client.from('talent_education').insert(
      education
          .map(
            (e) => {
              'talent_profile_id': talentProfileId,
              'level': e.level.dbValue,
              'institution': e.institution,
              'field_of_study': e.fieldOfStudy,
              'started_year': e.startedYear,
              'completed_year': e.completedYear,
            },
          )
          .toList(),
    );
  }

  static Future<List<TalentEducationEntry>> _fetchEducation(int talentProfileId) async {
    final rows = await _client
        .from('talent_education')
        .select()
        .eq('talent_profile_id', talentProfileId);
    return (rows as List)
        .map((r) => TalentEducationEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Same replace-the-whole-set approach as [_syncLinks]. `issuedOn` is
  /// sent as `YYYY-MM-DD` — the DB column is `date`, not `timestamptz`.
  static Future<void> _syncCertifications(
    int talentProfileId,
    List<CertificationEntry> certifications,
  ) async {
    await _client.from('talent_certifications').delete().eq('talent_profile_id', talentProfileId);
    if (certifications.isEmpty) return;
    await _client.from('talent_certifications').insert(
      certifications
          .map(
            (c) => {
              'talent_profile_id': talentProfileId,
              'name': c.name,
              'issuer': c.issuer,
              'issued_on': c.issuedOn == null ? null : _dateOnly(c.issuedOn!),
              'credential_url': c.credentialUrl,
            },
          )
          .toList(),
    );
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<CertificationEntry>> _fetchCertifications(int talentProfileId) async {
    final rows = await _client
        .from('talent_certifications')
        .select()
        .eq('talent_profile_id', talentProfileId);
    return (rows as List)
        .map((r) => CertificationEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Null when the signed-in account has never completed the onboarding
  /// wizard. Callers should send them into [ProfileSetupFlow] in that
  /// case, and straight to `HomeShell` otherwise.
  static Future<TalentProfile?> fetchCurrent() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('talent_profiles')
        .select()
        .eq('marketplace_user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    final base = TalentProfile.fromRow(row);
    final results = await Future.wait([
      _fetchSkills(base.id!),
      _fetchCategories(base.id!),
      _fetchLinks(base.id!),
      _fetchEducation(base.id!),
      _fetchCertifications(base.id!),
    ]);
    return base.copyWith(
      skills: results[0] as List<Skill>,
      categories: results[1] as List<TalentCategory>,
      links: results[2] as List<TalentProfileLink>,
      education: results[3] as List<TalentEducationEntry>,
      certifications: results[4] as List<CertificationEntry>,
    );
  }

  static Future<List<Skill>> _fetchSkills(int talentProfileId) async {
    final rows = await _client
        .from('talent_profile_skills')
        .select('skills(id, slug, name)')
        .eq('talent_profile_id', talentProfileId);
    return (rows as List)
        .map((r) => Skill.fromRow((r as Map<String, dynamic>)['skills'] as Map<String, dynamic>))
        .toList();
  }

  static Future<List<TalentCategory>> _fetchCategories(int talentProfileId) async {
    final rows = await _client
        .from('talent_profile_categories')
        .select('talent_categories(id, slug, name)')
        .eq('talent_profile_id', talentProfileId);
    return (rows as List)
        .map(
          (r) => TalentCategory.fromRow(
            (r as Map<String, dynamic>)['talent_categories'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
