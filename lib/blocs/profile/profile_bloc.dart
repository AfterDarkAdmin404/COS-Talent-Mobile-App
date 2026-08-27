import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/talent_profile.dart';
import '../../services/marketplace_user_service.dart';
import '../../services/skill_service.dart';
import '../../services/storage_service.dart';
import '../../services/talent_category_service.dart';
import '../../services/talent_profile_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileEditStarted>(_onEditStarted);
    on<ProfileLoadCurrentRequested>(_onLoadCurrent);
    on<ProfileReferenceDataRequested>(_onReferenceData);
    on<ProfileBasicsChanged>(_onBasicsChanged);
    on<ProfilePhotoUploadRequested>(_onPhotoUpload);
    on<ProfileCategoryToggled>(_onCategoryToggled);
    on<ProfileSkillToggled>(_onSkillToggled);
    on<ProfileExperienceChanged>(_onExperienceChanged);
    on<ProfileRateChanged>(_onRateChanged);
    on<ProfileEngagementTypeToggled>(_onEngagementTypeToggled);
    on<ProfileAvailabilityChanged>(_onAvailabilityChanged);
    on<ProfileSummaryChanged>(_onSummaryChanged);
    on<ProfileResumeUploadRequested>(_onResumeUpload);
    on<ProfileCertificationAdded>(_onCertificationAdded);
    on<ProfileCertificationRemoved>(_onCertificationRemoved);
    on<ProfileLinkAdded>(_onLinkAdded);
    on<ProfileLinkRemoved>(_onLinkRemoved);
    on<ProfileEducationAdded>(_onEducationAdded);
    on<ProfileEducationRemoved>(_onEducationRemoved);
    on<ProfileVisibilityChanged>(_onVisibilityChanged);
    on<ProfileConsentToggled>(_onConsentToggled);
    on<ProfileSubmitRequested>(_onSubmit);
    on<ProfileUpdateRequested>(_onUpdate);
    on<ProfileReset>(_onReset);
  }

  /// Onboarding starts by confirming (and self-healing, if missing) the
  /// `marketplace_users` row for the signed-in account — `id == auth.uid()`.
  /// `talent_profiles.marketplace_user_id` has a hard FK to that table, so
  /// nothing here can proceed without it.
  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileBlocStatus.loading));
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Not signed in.');
      var marketplaceUser = await MarketplaceUserService.fetchCurrent();
      marketplaceUser ??= await MarketplaceUserService.ensureRow(id: user.id, email: user.email!);
      emit(
        state.copyWith(
          status: ProfileBlocStatus.loaded,
          profile: TalentProfile(marketplaceUserId: marketplaceUser.id),
          isEditing: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ProfileBlocStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onEditStarted(ProfileEditStarted event, Emitter<ProfileState> emit) {
    emit(
      state.copyWith(status: ProfileBlocStatus.loaded, profile: event.profile, isEditing: true),
    );
  }

  /// Idempotent — covers both "never had a marketplace_users row yet" and
  /// "had one already," since there's no DB trigger creating it. Called
  /// right after sign-in, same as the old `sign_in_screen.dart` did inline.
  Future<void> _onLoadCurrent(ProfileLoadCurrentRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileBlocStatus.loading));
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Not signed in.');
      await MarketplaceUserService.ensureRow(id: user.id, email: user.email!);
      final profile = await TalentProfileService.fetchCurrent();
      emit(state.copyWith(status: ProfileBlocStatus.loaded, profile: profile));
    } catch (e) {
      emit(state.copyWith(status: ProfileBlocStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onReferenceData(
    ProfileReferenceDataRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(loadingReferenceData: true));
    try {
      final results = await Future.wait([SkillService.fetchActive(), TalentCategoryService.fetchActive()]);
      emit(
        state.copyWith(
          availableSkills: results[0].cast(),
          availableCategories: results[1].cast(),
          loadingReferenceData: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loadingReferenceData: false, errorMessage: e.toString()));
    }
  }

  void _onBasicsChanged(ProfileBasicsChanged event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(
      state.copyWith(
        profile: p.copyWith(
          firstName: event.firstName,
          lastName: event.lastName,
          showFullName: event.showFullName,
          professionalTitle: event.professionalTitle,
          countryId: event.countryId,
          city: event.city,
          preferredHoursStart: event.clearPreferredHours ? null : event.preferredHoursStart,
          preferredHoursEnd: event.clearPreferredHours ? null : event.preferredHoursEnd,
          utcOffset: event.utcOffset,
        ),
      ),
    );
  }

  Future<void> _onPhotoUpload(ProfilePhotoUploadRequested event, Emitter<ProfileState> emit) async {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(uploadingPhoto: true, photoError: null));
    try {
      final path = await StorageService.uploadPhoto(event.file);
      emit(state.copyWith(profile: p.copyWith(photoPath: path), uploadingPhoto: false));
    } catch (e) {
      emit(state.copyWith(uploadingPhoto: false, photoError: 'Couldn\'t upload that photo.'));
    }
  }

  void _onCategoryToggled(ProfileCategoryToggled event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    final categories = List.of(p.categories);
    if (categories.contains(event.category)) {
      categories.remove(event.category);
    } else {
      categories.add(event.category);
    }
    emit(state.copyWith(profile: p.copyWith(categories: categories)));
  }

  void _onSkillToggled(ProfileSkillToggled event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    final skills = List.of(p.skills);
    if (skills.contains(event.skill)) {
      skills.remove(event.skill);
    } else {
      skills.add(event.skill);
    }
    emit(state.copyWith(profile: p.copyWith(skills: skills)));
  }

  void _onExperienceChanged(ProfileExperienceChanged event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(
      state.copyWith(
        profile: p.copyWith(
          yearsExperience: event.yearsExperience,
          englishLevel: event.englishLevel,
        ),
      ),
    );
  }

  void _onRateChanged(ProfileRateChanged event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(
      state.copyWith(
        profile: p.copyWith(desiredAmount: event.desiredAmount, desiredPeriod: event.desiredPeriod),
      ),
    );
  }

  void _onEngagementTypeToggled(ProfileEngagementTypeToggled event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    final types = List.of(p.engagementTypes);
    if (types.contains(event.type)) {
      types.remove(event.type);
    } else if (types.length < 4) {
      types.add(event.type);
    }
    emit(state.copyWith(profile: p.copyWith(engagementTypes: types)));
  }

  void _onAvailabilityChanged(ProfileAvailabilityChanged event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(profile: p.copyWith(availability: event.availability)));
  }

  void _onSummaryChanged(ProfileSummaryChanged event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(profile: p.copyWith(summary: event.summary)));
  }

  Future<void> _onResumeUpload(ProfileResumeUploadRequested event, Emitter<ProfileState> emit) async {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(uploadingResume: true, resumeError: null));
    try {
      final path = await StorageService.uploadResume(event.file);
      emit(
        state.copyWith(
          profile: p.copyWith(resumeStoragePath: path, hasResume: true),
          uploadingResume: false,
          resumeFileName: event.fileName,
        ),
      );
    } catch (e) {
      emit(state.copyWith(uploadingResume: false, resumeError: 'Couldn\'t upload that resume.'));
    }
  }

  void _onCertificationAdded(ProfileCertificationAdded event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(profile: p.copyWith(certifications: [...p.certifications, event.certification])));
  }

  void _onCertificationRemoved(ProfileCertificationRemoved event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    final list = List.of(p.certifications)..removeAt(event.index);
    emit(state.copyWith(profile: p.copyWith(certifications: list)));
  }

  void _onLinkAdded(ProfileLinkAdded event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(profile: p.copyWith(links: [...p.links, event.link])));
  }

  void _onLinkRemoved(ProfileLinkRemoved event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    final list = List.of(p.links)..removeAt(event.index);
    emit(state.copyWith(profile: p.copyWith(links: list)));
  }

  void _onEducationAdded(ProfileEducationAdded event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(profile: p.copyWith(education: [...p.education, event.education])));
  }

  void _onEducationRemoved(ProfileEducationRemoved event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    final list = List.of(p.education)..removeAt(event.index);
    emit(state.copyWith(profile: p.copyWith(education: list)));
  }

  void _onVisibilityChanged(ProfileVisibilityChanged event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(
      state.copyWith(
        profile: p.copyWith(
          showExactRate: event.showExactRate,
          showResumePublicly: event.showResumePublicly,
        ),
      ),
    );
  }

  void _onConsentToggled(ProfileConsentToggled event, Emitter<ProfileState> emit) {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(profile: p.copyWith(consentToPublish: event.value)));
  }

  Future<void> _onSubmit(ProfileSubmitRequested event, Emitter<ProfileState> emit) async {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(status: ProfileBlocStatus.submitting, errorMessage: null));
    try {
      final saved = await TalentProfileService.submitForReview(
        p.copyWith(status: ProfileStatus.pendingReview),
      );
      emit(state.copyWith(status: ProfileBlocStatus.success, profile: saved));
    } catch (e) {
      emit(state.copyWith(status: ProfileBlocStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdate(ProfileUpdateRequested event, Emitter<ProfileState> emit) async {
    final p = state.profile;
    if (p == null) return;
    emit(state.copyWith(status: ProfileBlocStatus.submitting, errorMessage: null));
    try {
      final saved = await TalentProfileService.updateProfile(p);
      emit(state.copyWith(status: ProfileBlocStatus.success, profile: saved));
    } catch (e) {
      emit(state.copyWith(status: ProfileBlocStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onReset(ProfileReset event, Emitter<ProfileState> emit) {
    emit(const ProfileState());
  }
}
