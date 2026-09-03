import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/job_application.dart';
import '../../services/job_application_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/pill_chip.dart';

/// Every role this candidate has applied to, with where it stands in the
/// employer's pipeline. Status is set by the employer (or staff) side only
/// — see JobApplicationService's header comment — so this screen only ever
/// reads `job_applications.status`, it never offers a way to change it.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late Future<List<JobApplication>> _future;

  @override
  void initState() {
    super.initState();
    final talentProfileId = context.read<ProfileBloc>().state.profile?.id;
    _future = talentProfileId == null
        ? Future.value(const [])
        : JobApplicationService.fetchMine(talentProfileId);
  }

  Color _statusColor(ApplicationStatus status) => switch (status) {
    ApplicationStatus.hired || ApplicationStatus.offerExtended => AppColors.teal,
    ApplicationStatus.rejected || ApplicationStatus.withdrawn => AppColors.muted,
    ApplicationStatus.interviewing || ApplicationStatus.underReview => AppColors.navyLight,
    ApplicationStatus.submitted => AppColors.statusPending,
  };

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(title: const Text('My applications')),
      body: SafeArea(
        child: FutureBuilder<List<JobApplication>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Couldn\'t load your applications. ${snapshot.error}',
                    style: const TextStyle(color: AppColors.statusRejected),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final applications = snapshot.data ?? const [];
            if (applications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_outlined, size: 32, color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      Text('No applications yet', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text(
                        'Apply to a role from the Jobs tab and it\'ll show up here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              itemCount: applications.length,
              itemBuilder: (context, i) {
                final a = applications[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BrandCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(color: AppColors.offWhite, shape: BoxShape.circle),
                          child: const Icon(Icons.apartment_outlined, color: AppColors.muted),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.companyName ?? 'A COS-vetted employer',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                  ),
                                  StatusBadge(label: a.status.label, color: _statusColor(a.status)),
                                ],
                              ),
                              if (a.jobTitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Re: ${a.jobTitle}',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                                ),
                              ],
                              if (a.createdAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Applied ${_relativeTime(a.createdAt!)}',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
