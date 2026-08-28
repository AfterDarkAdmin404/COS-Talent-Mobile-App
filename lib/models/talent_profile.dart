/// Mirrors the live `public.talent_profiles` table exactly (columns,
/// types, nullability, check constraints) — verified against the actual
/// deployed schema, not just `docs/04-talent-marketplace/data-model.md`'s
/// prose spec. Fields are trimmed to what the candidate-facing app
/// actually reads or writes — staff-only columns (`review_notes`,
/// `reviewed_by_user_id`, `reviewed_at`, `deleted_at`) are left out on
/// purpose; the app never sets them.
///
/// Every class here is immutable (`copyWith`, no setters) — this is bloc
/// state, and bloc's whole model depends on a *new* object going into
/// `emit()` on every change, not an existing one being mutated in place.
library;

import 'dart:math';

import 'skill.dart';
import 'talent_category.dart';

/// Sentinel used by nullable `copyWith` params so "not passed, keep the
/// current value" can be told apart from "passed as null, clear it".
class _Unset {
  const _Unset();
}

const _unset = _Unset();

enum EnglishLevel { basic, conversational, fluent, native }

enum DesiredPeriod { hourly, monthly }

enum Availability { immediately, within2Weeks, withinAMonth, notAvailable }

enum ProfileStatus { draft, pendingReview, approved, rejected, suspended }

enum VerificationStatus { unverified, verified }

extension EnglishLevelLabel on EnglishLevel {
  String get label => switch (this) {
    EnglishLevel.basic => 'Basic',
    EnglishLevel.conversational => 'Conversational',
    EnglishLevel.fluent => 'Fluent',
    EnglishLevel.native => 'Native',
  };
  // talent_profiles_english_check
  String get dbValue => name;
}

extension AvailabilityLabel on Availability {
  String get label => switch (this) {
    Availability.immediately => 'Available immediately',
    Availability.within2Weeks => 'Within 2 weeks',
    Availability.withinAMonth => 'Within a month',
    Availability.notAvailable => 'Not available',
  };
  // talent_profiles_availability_check
  String get dbValue => switch (this) {
    Availability.immediately => 'immediately',
    Availability.within2Weeks => 'within_2_weeks',
    Availability.withinAMonth => 'within_a_month',
    Availability.notAvailable => 'not_available',
  };
}

extension ProfileStatusMeta on ProfileStatus {
  String get label => switch (this) {
    ProfileStatus.draft => 'Draft',
    ProfileStatus.pendingReview => 'Pending review',
    ProfileStatus.approved => 'Approved',
    ProfileStatus.rejected => 'Changes requested',
    ProfileStatus.suspended => 'Suspended',
  };
  // talent_profiles_status_check
  String get dbValue => switch (this) {
    ProfileStatus.draft => 'draft',
    ProfileStatus.pendingReview => 'pending_review',
    ProfileStatus.approved => 'approved',
    ProfileStatus.rejected => 'rejected',
    ProfileStatus.suspended => 'suspended',
  };
}

/// Colombia's `countries.id` in the seed data — Phase 1 is Colombia-only
/// (PLAN.md Table A #9). **Placeholder: confirm this against the real
/// seeded row** (`select id from countries where iso2 = 'CO'`) before
/// this ships against production; a wrong id fails the profile insert on
/// the `talent_profiles_country_id_fkey` constraint, not silently.
const int kColombiaCountryId = 1;

/// Colombia does not observe DST — a fixed offset is safe here. A
/// second launch country would need this computed per-country instead
/// of hardcoded.
const int kColombiaUtcOffsetHours = -5;

/// Row shape for `talent_work_history`. Two DB checks to mirror
/// client-side before either ever reaches a request:
/// `talent_work_history_current_check` (`isCurrent` and `endedOn` are
/// mutually exclusive) and `talent_work_history_dates_check`
/// (`endedOn >= startedOn` when present).
class WorkHistoryEntry {
  final int? id;
  final String jobTitle;
  final String companyName;
  final DateTime startedOn;
  final DateTime? endedOn;
  final bool isCurrent;
  final String? description;

  const WorkHistoryEntry({
    this.id,
    required this.jobTitle,
    required this.companyName,
    required this.startedOn,
    this.endedOn,
    this.isCurrent = false,
    this.description,
  });

  factory WorkHistoryEntry.fromRow(Map<String, dynamic> row) => WorkHistoryEntry(
    id: row['id'] as int,
    jobTitle: row['job_title'] as String,
    companyName: row['company_name'] as String,
    startedOn: DateTime.parse(row['started_on'] as String),
    endedOn: row['ended_on'] == null ? null : DateTime.parse(row['ended_on'] as String),
    isCurrent: row['is_current'] as bool? ?? false,
    description: row['description'] as String?,
  );

  WorkHistoryEntry copyWith({
    int? id,
    String? jobTitle,
    String? companyName,
    DateTime? startedOn,
    DateTime? endedOn,
    bool? isCurrent,
    String? description,
  }) => WorkHistoryEntry(
    id: id ?? this.id,
    jobTitle: jobTitle ?? this.jobTitle,
    companyName: companyName ?? this.companyName,
    startedOn: startedOn ?? this.startedOn,
    endedOn: endedOn ?? this.endedOn,
    isCurrent: isCurrent ?? this.isCurrent,
    description: description ?? this.description,
  );
}

/// "Jan 2023" — no `intl` dependency for one label.
String formatMonthYear(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

/// Row shape for `talent_certifications`. `credentialUrl`, when present,
/// is checked `^https?://` by the DB (`talent_certifications_url_check`)
/// — validate the same thing client-side before it reaches a request.
class CertificationEntry {
  final int? id;
  final String name;
  final String? issuer;
  final DateTime? issuedOn;
  final String? credentialUrl;

  const CertificationEntry({
    this.id,
    required this.name,
    this.issuer,
    this.issuedOn,
    this.credentialUrl,
  });

  factory CertificationEntry.fromRow(Map<String, dynamic> row) => CertificationEntry(
    id: row['id'] as int,
    name: row['name'] as String,
    issuer: row['issuer'] as String?,
    issuedOn: row['issued_on'] == null ? null : DateTime.parse(row['issued_on'] as String),
    credentialUrl: row['credential_url'] as String?,
  );

  CertificationEntry copyWith({
    int? id,
    String? name,
    String? issuer,
    DateTime? issuedOn,
    String? credentialUrl,
  }) => CertificationEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    issuer: issuer ?? this.issuer,
    issuedOn: issuedOn ?? this.issuedOn,
    credentialUrl: credentialUrl ?? this.credentialUrl,
  );
}

enum LinkKind { portfolio, linkedin, website, github, behance }

extension LinkKindLabel on LinkKind {
  String get label => switch (this) {
    LinkKind.portfolio => 'Portfolio',
    LinkKind.linkedin => 'LinkedIn',
    LinkKind.website => 'Website',
    LinkKind.github => 'GitHub',
    LinkKind.behance => 'Behance',
  };
  // talent_profile_links_kind_check
  String get dbValue => name;
}

/// Row shape for `talent_profile_links`. `id` is null until the row has
/// actually been written — see [TalentProfileService]'s replace-the-set
/// sync, same pattern as skills and categories.
class TalentProfileLink {
  final int? id;
  final LinkKind kind;
  final String url;
  final bool isPublic;

  const TalentProfileLink({this.id, required this.kind, required this.url, this.isPublic = false});

  factory TalentProfileLink.fromRow(Map<String, dynamic> row) => TalentProfileLink(
    id: row['id'] as int,
    kind: LinkKind.values.byName(row['kind'] as String),
    url: row['url'] as String,
    isPublic: row['is_public'] as bool? ?? false,
  );

  TalentProfileLink copyWith({int? id, LinkKind? kind, String? url, bool? isPublic}) =>
      TalentProfileLink(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        url: url ?? this.url,
        isPublic: isPublic ?? this.isPublic,
      );
}

enum EducationLevel { secondary, technical, bachelors, masters, doctorate }

extension EducationLevelLabel on EducationLevel {
  String get label => switch (this) {
    EducationLevel.secondary => 'Secondary school',
    EducationLevel.technical => 'Technical / vocational',
    EducationLevel.bachelors => 'Bachelor\'s degree',
    EducationLevel.masters => 'Master\'s degree',
    EducationLevel.doctorate => 'Doctorate',
  };
  // talent_education_level_check
  String get dbValue => name;
}

/// Row shape for `talent_education`. `startedYear`/`completedYear` are
/// checked 1950–2100 by the DB (`talent_education_started_year_check` /
/// `_completed_year_check`) — validate the same range client-side before
/// it ever reaches a request.
class TalentEducationEntry {
  final int? id;
  final EducationLevel level;
  final String institution;
  final String? fieldOfStudy;
  final int? startedYear;
  final int? completedYear;

  const TalentEducationEntry({
    this.id,
    required this.level,
    required this.institution,
    this.fieldOfStudy,
    this.startedYear,
    this.completedYear,
  });

  factory TalentEducationEntry.fromRow(Map<String, dynamic> row) => TalentEducationEntry(
    id: row['id'] as int,
    level: EducationLevel.values.byName(row['level'] as String),
    institution: row['institution'] as String,
    fieldOfStudy: row['field_of_study'] as String?,
    startedYear: row['started_year'] as int?,
    completedYear: row['completed_year'] as int?,
  );

  TalentEducationEntry copyWith({
    int? id,
    EducationLevel? level,
    String? institution,
    String? fieldOfStudy,
    int? startedYear,
    int? completedYear,
  }) => TalentEducationEntry(
    id: id ?? this.id,
    level: level ?? this.level,
    institution: institution ?? this.institution,
    fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
    startedYear: startedYear ?? this.startedYear,
    completedYear: completedYear ?? this.completedYear,
  );
}

/// `talent_access_events`, aggregated for the candidate-facing activity view.
class AccessEventSummary {
  final int profileViews30d;
  final int resumeDownloads30d;
  final int searchAppearances30d;

  const AccessEventSummary({
    required this.profileViews30d,
    required this.resumeDownloads30d,
    required this.searchAppearances30d,
  });
}

/// `firstname-lastinitial-<8 random lowercase alnum chars>` —
/// data-model.md:321: "Readable for her, unguessable for an id-walker.
/// Not a secret: published profiles are in the sitemap." Matches the
/// `talent_profiles_slug_idx` unique index; a collision means retry with
/// a fresh suffix, not a fixed value.
String generatePublicSlug(String firstName, String lastName) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();
  final suffix = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  final first = firstName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final lastInitial = lastName.trim().isEmpty ? '' : lastName.trim()[0].toLowerCase();
  return '$first-$lastInitial-$suffix';
}

class TalentProfile {
  // Identity — set once, at submit time, not editable in the wizard.
  final int? id; // talent_profiles.id — the serial PK, not known until the first insert
  final String? marketplaceUserId; // talent_profiles.marketplace_user_id
  final String? publicSlug; // talent_profiles.public_slug

  // Tier 1 — public once published.
  final String firstName;
  final String lastName; // NOT NULL in the DB — always required, even unshown
  final bool showFullName;
  final String professionalTitle;
  final String? summary;
  final int countryId;
  final String? city;
  final int yearsExperience;
  final EnglishLevel englishLevel;
  final double desiredAmount;
  final DesiredPeriod desiredPeriod;
  final String desiredCurrency; // pinned 'USD' — talent_profiles_currency_check
  final bool showExactRate;
  final List<String> engagementTypes; // full_time / part_time / contract / project
  final Availability availability;
  final int? preferredHoursStart; // 0-23, candidate local time
  final int? preferredHoursEnd; // 0-23
  final int utcOffset; // NOT NULL — seeded from country, candidate-editable
  final String? photoPath;
  /// Selected `talent_categories` rows — saved through
  /// `talent_profile_categories`, same pattern as [skills] below.
  final List<TalentCategory> categories;
  /// Selected `skills` rows — saved through `talent_profile_skills`, a
  /// join table, not a column on `talent_profiles` itself. See
  /// [TalentProfileService.submitForReview] / `.updateProfile` for the
  /// write, and `.fetchCurrent` for the read.
  final List<Skill> skills;

  // Tier 2 — authenticated / brokered.
  final List<WorkHistoryEntry> workHistory;
  final List<CertificationEntry> certifications;
  /// Saved through `talent_profile_links`, same replace-the-set pattern
  /// as [skills] / [categories].
  final List<TalentProfileLink> links;
  /// Saved through `talent_education`, same replace-the-set pattern.
  final List<TalentEducationEntry> education;
  final bool hasResume;
  final String? resumeStoragePath;
  final bool showResumePublicly;

  // Internal / lifecycle.
  final ProfileStatus status;
  final bool isPublic; // DB CHECK: only true when status = 'approved'
  final VerificationStatus verificationStatus; // ships in Phase 1; workflow doesn't exist yet
  final int profileCompleteness;

  /// UI-only flag for the review step's `profile_publication` consent
  /// checkbox — a real build writes this as a `marketplace_consents` row,
  /// not a column on `talent_profiles` itself.
  final bool consentToPublish;

  const TalentProfile({
    this.id,
    this.marketplaceUserId,
    this.publicSlug,
    this.firstName = '',
    this.lastName = '',
    this.showFullName = false,
    this.professionalTitle = '',
    this.summary,
    this.countryId = kColombiaCountryId,
    this.city,
    this.yearsExperience = 0,
    this.englishLevel = EnglishLevel.conversational,
    this.desiredAmount = 0,
    this.desiredPeriod = DesiredPeriod.hourly,
    this.desiredCurrency = 'USD',
    this.showExactRate = false,
    this.engagementTypes = const [],
    this.availability = Availability.withinAMonth,
    this.preferredHoursStart,
    this.preferredHoursEnd,
    this.utcOffset = kColombiaUtcOffsetHours,
    this.photoPath,
    this.categories = const [],
    this.skills = const [],
    this.workHistory = const [],
    this.certifications = const [],
    this.links = const [],
    this.education = const [],
    this.hasResume = false,
    this.resumeStoragePath,
    this.showResumePublicly = false,
    this.status = ProfileStatus.draft,
    this.isPublic = false,
    this.verificationStatus = VerificationStatus.unverified,
    this.profileCompleteness = 0,
    this.consentToPublish = false,
  });

  /// Rebuilds a profile from a `talent_profiles` row, e.g. after signing
  /// back in. **`categories`, `skills`, `links`, `workHistory`, and
  /// `certifications` come back empty** — those live in separate join
  /// tables (`023_create_talent_taxonomy.sql`, `024:...`) that nothing in
  /// this app queries yet, so there's nothing to hydrate them from.
  factory TalentProfile.fromRow(Map<String, dynamic> row) {
    return TalentProfile(
      id: row['id'] as int,
      marketplaceUserId: row['marketplace_user_id'] as String,
      publicSlug: row['public_slug'] as String,
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      showFullName: row['show_full_name'] as bool? ?? false,
      professionalTitle: row['professional_title'] as String? ?? '',
      summary: row['summary'] as String?,
      countryId: row['country_id'] as int? ?? kColombiaCountryId,
      city: row['city'] as String?,
      yearsExperience: row['years_experience'] as int? ?? 0,
      englishLevel: EnglishLevel.values.byName(row['english_level'] as String),
      desiredAmount: (row['desired_amount'] as num?)?.toDouble() ?? 0,
      desiredPeriod: DesiredPeriod.values.byName(row['desired_period'] as String),
      desiredCurrency: row['desired_currency'] as String? ?? 'USD',
      showExactRate: row['show_exact_rate'] as bool? ?? false,
      engagementTypes: (row['engagement_types'] as List?)?.cast<String>() ?? const [],
      availability: Availability.values.firstWhere(
        (a) => a.dbValue == row['availability'],
        orElse: () => Availability.withinAMonth,
      ),
      preferredHoursStart: row['preferred_hours_start'] as int?,
      preferredHoursEnd: row['preferred_hours_end'] as int?,
      utcOffset: row['utc_offset'] as int? ?? kColombiaUtcOffsetHours,
      photoPath: row['photo_storage_path'] as String?,
      hasResume: row['resume_storage_path'] != null,
      resumeStoragePath: row['resume_storage_path'] as String?,
      showResumePublicly: row['show_resume_publicly'] as bool? ?? false,
      status: ProfileStatus.values.firstWhere(
        (s) => s.dbValue == row['status'],
        orElse: () => ProfileStatus.draft,
      ),
      isPublic: row['is_public'] as bool? ?? false,
      verificationStatus: VerificationStatus.values.byName(row['verification_status'] as String),
      profileCompleteness: row['profile_completeness'] as int? ?? 0,
    );
  }

  /// 10 equally weighted checks, matching data-model.md's "recomputed on
  /// write" note for the column. Read by [TalentProfileService] right
  /// before submit/update — nothing recomputes this on every keystroke.
  int get computedCompleteness {
    final checks = <bool>[
      firstName.trim().isNotEmpty,
      lastName.trim().isNotEmpty,
      professionalTitle.trim().isNotEmpty,
      (summary ?? '').trim().isNotEmpty,
      (city ?? '').trim().isNotEmpty,
      yearsExperience > 0,
      categories.isNotEmpty,
      skills.isNotEmpty,
      hasResume,
      photoPath != null,
    ];
    final filled = checks.where((c) => c).length;
    return ((filled / checks.length) * 100).round();
  }

  /// The candidate's own rate, expressed monthly-USD for the /month
  /// comparison — mirrors the generated column `desired_monthly_usd`
  /// (hourly * 160). Computed client-side for display only; the DB
  /// computes and stores its own copy, this is never written on insert.
  double get desiredMonthlyUsd =>
      desiredPeriod == DesiredPeriod.hourly ? desiredAmount * 160 : desiredAmount;

  /// Phase 1 is Colombia-only, so this is a fixed lookup rather than a
  /// join against `countries` — extend this (and the country picker in
  /// StepBasics) the day a second country's `countries.id` is seeded.
  String get countryName => countryId == kColombiaCountryId ? 'Colombia' : 'Unknown';

  String get displayName =>
      showFullName && lastName.isNotEmpty ? '$firstName $lastName' : firstName;

  String get rateLabel {
    final unit = desiredPeriod == DesiredPeriod.hourly ? '/hr' : '/mo';
    if (showExactRate) {
      return '\$${desiredAmount.toStringAsFixed(0)}$unit';
    }
    // Public "band" view: round down to nearest bracket of 5/500.
    final bandWidth = desiredPeriod == DesiredPeriod.hourly ? 5 : 500;
    final low = (desiredAmount ~/ bandWidth) * bandWidth;
    return '\$$low–\$${low + bandWidth}$unit (band)';
  }

  /// Row shape for `talent_profiles.insert(...)` — omits `id` (serial),
  /// `desired_monthly_usd` (GENERATED ALWAYS, never written), and every
  /// staff/internal-only column. `marketplace_user_id` and `public_slug`
  /// must be set before calling this.
  Map<String, dynamic> toInsertRow() {
    assert(marketplaceUserId != null, 'marketplaceUserId must be set before insert');
    assert(publicSlug != null, 'publicSlug must be set before insert');
    return {
      'marketplace_user_id': marketplaceUserId,
      'public_slug': publicSlug,
      'first_name': firstName,
      'last_name': lastName,
      'show_full_name': showFullName,
      'professional_title': professionalTitle,
      'summary': summary,
      'country_id': countryId,
      'city': city,
      'years_experience': yearsExperience,
      'english_level': englishLevel.dbValue,
      'desired_amount': desiredAmount,
      'desired_period': desiredPeriod.name,
      'desired_currency': desiredCurrency,
      'show_exact_rate': showExactRate,
      'engagement_types': engagementTypes,
      'availability': availability.dbValue,
      'preferred_hours_start': preferredHoursStart,
      'preferred_hours_end': preferredHoursEnd,
      'utc_offset': utcOffset,
      'photo_storage_path': photoPath,
      'resume_storage_path': resumeStoragePath,
      'show_resume_publicly': showResumePublicly,
      'status': status.dbValue,
      'is_public': isPublic,
      'verification_status': verificationStatus.name,
      'profile_completeness': profileCompleteness,
    };
  }

  /// Row shape for `talent_profiles.update(...)`. Same fields as
  /// [toInsertRow] minus the ones an edit must never touch: identity
  /// (`marketplace_user_id`, `public_slug` — changing the slug breaks
  /// links already shared) and the staff/system-controlled lifecycle
  /// columns (`status`, `is_public`, `verification_status`), which only
  /// change through their own dedicated actions, not a general profile
  /// edit.
  Map<String, dynamic> toUpdateRow() {
    return toInsertRow()
      ..remove('marketplace_user_id')
      ..remove('public_slug')
      ..remove('status')
      ..remove('is_public')
      ..remove('verification_status');
  }

  TalentProfile copyWith({
    int? id,
    String? marketplaceUserId,
    String? publicSlug,
    String? firstName,
    String? lastName,
    bool? showFullName,
    String? professionalTitle,
    Object? summary = _unset,
    int? countryId,
    Object? city = _unset,
    int? yearsExperience,
    EnglishLevel? englishLevel,
    double? desiredAmount,
    DesiredPeriod? desiredPeriod,
    bool? showExactRate,
    List<String>? engagementTypes,
    Availability? availability,
    Object? preferredHoursStart = _unset,
    Object? preferredHoursEnd = _unset,
    int? utcOffset,
    Object? photoPath = _unset,
    List<TalentCategory>? categories,
    List<Skill>? skills,
    List<WorkHistoryEntry>? workHistory,
    List<CertificationEntry>? certifications,
    List<TalentProfileLink>? links,
    List<TalentEducationEntry>? education,
    bool? hasResume,
    Object? resumeStoragePath = _unset,
    bool? showResumePublicly,
    ProfileStatus? status,
    bool? isPublic,
    VerificationStatus? verificationStatus,
    int? profileCompleteness,
    bool? consentToPublish,
  }) {
    return TalentProfile(
      id: id ?? this.id,
      marketplaceUserId: marketplaceUserId ?? this.marketplaceUserId,
      publicSlug: publicSlug ?? this.publicSlug,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      showFullName: showFullName ?? this.showFullName,
      professionalTitle: professionalTitle ?? this.professionalTitle,
      summary: identical(summary, _unset) ? this.summary : summary as String?,
      countryId: countryId ?? this.countryId,
      city: identical(city, _unset) ? this.city : city as String?,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      englishLevel: englishLevel ?? this.englishLevel,
      desiredAmount: desiredAmount ?? this.desiredAmount,
      desiredPeriod: desiredPeriod ?? this.desiredPeriod,
      desiredCurrency: desiredCurrency,
      showExactRate: showExactRate ?? this.showExactRate,
      engagementTypes: engagementTypes ?? this.engagementTypes,
      availability: availability ?? this.availability,
      preferredHoursStart: identical(preferredHoursStart, _unset)
          ? this.preferredHoursStart
          : preferredHoursStart as int?,
      preferredHoursEnd: identical(preferredHoursEnd, _unset)
          ? this.preferredHoursEnd
          : preferredHoursEnd as int?,
      utcOffset: utcOffset ?? this.utcOffset,
      photoPath: identical(photoPath, _unset) ? this.photoPath : photoPath as String?,
      categories: categories ?? this.categories,
      skills: skills ?? this.skills,
      workHistory: workHistory ?? this.workHistory,
      certifications: certifications ?? this.certifications,
      links: links ?? this.links,
      education: education ?? this.education,
      hasResume: hasResume ?? this.hasResume,
      resumeStoragePath: identical(resumeStoragePath, _unset)
          ? this.resumeStoragePath
          : resumeStoragePath as String?,
      showResumePublicly: showResumePublicly ?? this.showResumePublicly,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      profileCompleteness: profileCompleteness ?? this.profileCompleteness,
      consentToPublish: consentToPublish ?? this.consentToPublish,
    );
  }
}
