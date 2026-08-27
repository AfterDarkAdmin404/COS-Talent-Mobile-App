import '../models/skill.dart';
import '../models/talent_category.dart';
import '../models/talent_profile.dart';

const kEngagementTypeLabels = <String, String>{
  'full_time': 'Full-time',
  'part_time': 'Part-time',
  'contract': 'Contract',
  'project': 'Project-based',
};

TalentProfile buildDemoProfile() {
  final profile = TalentProfile(
    firstName: 'Camila',
    lastName: 'Restrepo',
    showFullName: false,
    professionalTitle: 'Senior Virtual Assistant & Bookkeeper',
    summary:
        'Five years supporting US-based small businesses with inbox '
        'management, scheduling, and light bookkeeping in QuickBooks. '
        'I like turning a messy backlog into a system that runs itself.',
    countryId: kColombiaCountryId,
    city: 'Medellín',
    yearsExperience: 5,
    englishLevel: EnglishLevel.fluent,
    desiredAmount: 12,
    desiredPeriod: DesiredPeriod.hourly,
    showExactRate: false,
    engagementTypes: ['full_time', 'part_time'],
    availability: Availability.within2Weeks,
    categories: const [
      TalentCategory(id: 1, slug: 'virtual-assistants', name: 'Virtual Assistants'),
      TalentCategory(id: 2, slug: 'bookkeepers', name: 'Bookkeepers'),
    ],
    skills: const [
      Skill(id: 1, slug: 'quickbooks', name: 'QuickBooks'),
      Skill(id: 2, slug: 'excel-google-sheets', name: 'Excel / Google Sheets'),
      Skill(id: 3, slug: 'calendar-management', name: 'Calendar Management'),
      Skill(id: 4, slug: 'notion', name: 'Notion'),
    ],
    workHistory: const [
      WorkHistoryEntry(
        jobTitle: 'Virtual Assistant',
        companyName: 'Bright Loop Consulting (remote, US client)',
        started: '2023',
        isCurrent: true,
      ),
      WorkHistoryEntry(
        jobTitle: 'Bookkeeping Assistant',
        companyName: 'Contadores Medellín',
        started: '2021',
        ended: '2023',
      ),
    ],
    certifications: [
      CertificationEntry(name: 'QuickBooks Online ProAdvisor', issuer: 'Intuit'),
    ],
    hasResume: true,
    showResumePublicly: false,
    status: ProfileStatus.pendingReview,
    isPublic: false,
    profileCompleteness: 82,
  );
  return profile;
}

/// Illustrative post-publish numbers. Shown only once `isPublic` is true —
/// see the dashboard screen's zero-state for the pre-publish case, which
/// matches reality: zero talent tables exist today, so this is a preview
/// of the intended UI, not a claim about current traffic.
const kDemoActivity = AccessEventSummary(
  profileViews30d: 14,
  resumeDownloads30d: 2,
  searchAppearances30d: 41,
);
