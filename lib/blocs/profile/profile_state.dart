import 'package:equatable/equatable.dart';
import '../../models/skill.dart';
import '../../models/talent_category.dart';
import '../../models/talent_profile.dart';

enum ProfileBlocStatus { initial, loading, loaded, submitting, success, failure }

class ProfileState extends Equatable {
  final ProfileBlocStatus status;
  final TalentProfile? profile;

  /// True when the wizard is editing an existing profile (final step
  /// updates instead of inserts, and skips the publish-consent gate).
  final bool isEditing;

  final List<Skill> availableSkills;
  final List<TalentCategory> availableCategories;
  final bool loadingReferenceData;

  final bool uploadingPhoto;
  final bool uploadingResume;
  final String? photoError;
  final String? resumeError;
  final String? resumeFileName;

  final String? errorMessage;

  const ProfileState({
    this.status = ProfileBlocStatus.initial,
    this.profile,
    this.isEditing = false,
    this.availableSkills = const [],
    this.availableCategories = const [],
    this.loadingReferenceData = false,
    this.uploadingPhoto = false,
    this.uploadingResume = false,
    this.photoError,
    this.resumeError,
    this.resumeFileName,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileBlocStatus? status,
    TalentProfile? profile,
    bool? isEditing,
    List<Skill>? availableSkills,
    List<TalentCategory>? availableCategories,
    bool? loadingReferenceData,
    bool? uploadingPhoto,
    bool? uploadingResume,
    String? photoError,
    String? resumeError,
    String? resumeFileName,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isEditing: isEditing ?? this.isEditing,
      availableSkills: availableSkills ?? this.availableSkills,
      availableCategories: availableCategories ?? this.availableCategories,
      loadingReferenceData: loadingReferenceData ?? this.loadingReferenceData,
      uploadingPhoto: uploadingPhoto ?? this.uploadingPhoto,
      uploadingResume: uploadingResume ?? this.uploadingResume,
      photoError: photoError,
      resumeError: resumeError,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile?.id,
    profile?.firstName,
    profile?.lastName,
    profile?.showFullName,
    profile?.professionalTitle,
    profile?.summary,
    profile?.city,
    profile?.yearsExperience,
    profile?.englishLevel,
    profile?.desiredAmount,
    profile?.desiredPeriod,
    profile?.showExactRate,
    profile?.engagementTypes,
    profile?.availability,
    profile?.preferredHoursStart,
    profile?.preferredHoursEnd,
    profile?.photoPath,
    profile?.categories,
    profile?.skills,
    profile?.workHistory,
    profile?.certifications,
    profile?.links,
    profile?.education,
    profile?.hasResume,
    profile?.resumeStoragePath,
    profile?.showResumePublicly,
    profile?.status,
    profile?.isPublic,
    profile?.consentToPublish,
    isEditing,
    availableSkills,
    availableCategories,
    loadingReferenceData,
    uploadingPhoto,
    uploadingResume,
    photoError,
    resumeError,
    resumeFileName,
    errorMessage,
  ];
}
