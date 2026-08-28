import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/skill.dart';
import '../../models/talent_category.dart';
import '../../models/talent_profile.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

/// Begin the onboarding wizard fresh. Ensures the `marketplace_users` row
/// exists (mirrors what `ProfileSetupFlow._loadMarketplaceUser` used to
/// do) and seeds a blank [TalentProfile] with `marketplaceUserId` set.
class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

/// Begin editing an already-loaded profile — same wizard, but the final
/// step updates instead of inserts.
class ProfileEditStarted extends ProfileEvent {
  final TalentProfile profile;
  const ProfileEditStarted(this.profile);
  @override
  List<Object?> get props => [profile];
}

/// Fetches the signed-in account's `talent_profiles` row, if any. Null
/// result means the account has never finished onboarding.
class ProfileLoadCurrentRequested extends ProfileEvent {
  const ProfileLoadCurrentRequested();
}

/// Loads the pickable options for the categories/skills step.
class ProfileReferenceDataRequested extends ProfileEvent {
  const ProfileReferenceDataRequested();
}

class ProfileBasicsChanged extends ProfileEvent {
  final String? firstName;
  final String? lastName;
  final bool? showFullName;
  final String? professionalTitle;
  final int? countryId;
  final String? city;
  final int? preferredHoursStart;
  final int? preferredHoursEnd;
  final bool clearPreferredHours;
  final int? utcOffset;

  const ProfileBasicsChanged({
    this.firstName,
    this.lastName,
    this.showFullName,
    this.professionalTitle,
    this.countryId,
    this.city,
    this.preferredHoursStart,
    this.preferredHoursEnd,
    this.clearPreferredHours = false,
    this.utcOffset,
  });

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    showFullName,
    professionalTitle,
    countryId,
    city,
    preferredHoursStart,
    preferredHoursEnd,
    clearPreferredHours,
    utcOffset,
  ];
}

class ProfilePhotoUploadRequested extends ProfileEvent {
  final File file;
  const ProfilePhotoUploadRequested(this.file);
  @override
  List<Object?> get props => [file.path];
}

class ProfileCategoryToggled extends ProfileEvent {
  final TalentCategory category;
  const ProfileCategoryToggled(this.category);
  @override
  List<Object?> get props => [category];
}

class ProfileSkillToggled extends ProfileEvent {
  final Skill skill;
  const ProfileSkillToggled(this.skill);
  @override
  List<Object?> get props => [skill];
}

class ProfileExperienceChanged extends ProfileEvent {
  final int? yearsExperience;
  final EnglishLevel? englishLevel;
  const ProfileExperienceChanged({this.yearsExperience, this.englishLevel});
  @override
  List<Object?> get props => [yearsExperience, englishLevel];
}

class ProfileRateChanged extends ProfileEvent {
  final double? desiredAmount;
  final DesiredPeriod? desiredPeriod;
  const ProfileRateChanged({this.desiredAmount, this.desiredPeriod});
  @override
  List<Object?> get props => [desiredAmount, desiredPeriod];
}

class ProfileEngagementTypeToggled extends ProfileEvent {
  final String type;
  const ProfileEngagementTypeToggled(this.type);
  @override
  List<Object?> get props => [type];
}

class ProfileAvailabilityChanged extends ProfileEvent {
  final Availability availability;
  const ProfileAvailabilityChanged(this.availability);
  @override
  List<Object?> get props => [availability];
}

class ProfileSummaryChanged extends ProfileEvent {
  final String summary;
  const ProfileSummaryChanged(this.summary);
  @override
  List<Object?> get props => [summary];
}

class ProfileResumeUploadRequested extends ProfileEvent {
  final File file;
  final String fileName;
  const ProfileResumeUploadRequested(this.file, this.fileName);
  @override
  List<Object?> get props => [file.path, fileName];
}

class ProfileCertificationAdded extends ProfileEvent {
  final CertificationEntry certification;
  const ProfileCertificationAdded(this.certification);
  @override
  List<Object?> get props => [certification];
}

class ProfileCertificationRemoved extends ProfileEvent {
  final int index;
  const ProfileCertificationRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class ProfileLinkAdded extends ProfileEvent {
  final TalentProfileLink link;
  const ProfileLinkAdded(this.link);
  @override
  List<Object?> get props => [link];
}

class ProfileLinkRemoved extends ProfileEvent {
  final int index;
  const ProfileLinkRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class ProfileEducationAdded extends ProfileEvent {
  final TalentEducationEntry education;
  const ProfileEducationAdded(this.education);
  @override
  List<Object?> get props => [education];
}

class ProfileEducationRemoved extends ProfileEvent {
  final int index;
  const ProfileEducationRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class ProfileWorkHistoryAdded extends ProfileEvent {
  final WorkHistoryEntry entry;
  const ProfileWorkHistoryAdded(this.entry);
  @override
  List<Object?> get props => [entry];
}

class ProfileWorkHistoryRemoved extends ProfileEvent {
  final int index;
  const ProfileWorkHistoryRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class ProfileVisibilityChanged extends ProfileEvent {
  final bool? showExactRate;
  final bool? showResumePublicly;
  const ProfileVisibilityChanged({this.showExactRate, this.showResumePublicly});
  @override
  List<Object?> get props => [showExactRate, showResumePublicly];
}

class ProfileConsentToggled extends ProfileEvent {
  final bool value;
  const ProfileConsentToggled(this.value);
  @override
  List<Object?> get props => [value];
}

class ProfileSubmitRequested extends ProfileEvent {
  const ProfileSubmitRequested();
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested();
}

/// Clears all profile state — dispatched on sign-out so the next signed-in
/// account never sees a stale draft.
class ProfileReset extends ProfileEvent {
  const ProfileReset();
}
