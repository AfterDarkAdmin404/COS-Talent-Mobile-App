import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../models/job_application.dart';
import '../../models/job_posting.dart';
import '../../models/talent_category.dart';
import '../../services/job_application_service.dart';
import '../../services/job_posting_service.dart';
import '../../services/talent_category_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/pill_chip.dart';
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';

/// Published, staff-approved roles a candidate can apply to. Unlike the
/// employer_app Jobs tab (the employer's own postings), this is every
/// employer's live postings — the actual job board.
///
/// Search + filters are all client-side over the one `fetchPublished()`
/// list, same posture as employer_app's `BrowseScreen` (candidate pool):
/// Phase-1 volumes, no `.ilike`/pagination on the query itself.
class JobsBrowseScreen extends StatefulWidget {
  const JobsBrowseScreen({super.key});

  @override
  State<JobsBrowseScreen> createState() => _JobsBrowseScreenState();
}

class _JobsBrowseScreenState extends State<JobsBrowseScreen> {
  late Future<(List<JobPosting>, Map<int, JobApplication>, List<TalentCategory>)> _future;

  String _query = '';
  String? _category;
  Set<String> _engagementTypes = {};
  double? _minBudget;
  double? _maxBudget;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(List<JobPosting>, Map<int, JobApplication>, List<TalentCategory>)> _load() async {
    final talentProfileId = context.read<ProfileBloc>().state.profile?.id;
    final postingsFuture = JobPostingService.fetchPublished();
    final categoriesFuture = TalentCategoryService.fetchActive();
    final appliedFuture = talentProfileId == null
        ? Future.value(<int, JobApplication>{})
        : JobApplicationService.fetchMineByPosting(talentProfileId);
    final postings = await postingsFuture;
    final applied = await appliedFuture;
    final categories = await categoriesFuture;
    return (postings, applied, categories);
  }

  void _reload() => setState(() => _future = _load());

  bool get _hasBottomSheetFilters => _engagementTypes.isNotEmpty || _minBudget != null || _maxBudget != null;

  bool _matchesBudget(JobPosting p) {
    if (_minBudget == null && _maxBudget == null) return true;
    final postingMin = p.budgetMinAmount ?? p.budgetMaxAmount;
    final postingMax = p.budgetMaxAmount ?? p.budgetMinAmount;
    if (postingMin == null && postingMax == null) return false;
    if (_minBudget != null && (postingMax ?? postingMin!) < _minBudget!) return false;
    if (_maxBudget != null && (postingMin ?? postingMax!) > _maxBudget!) return false;
    return true;
  }

  List<JobPosting> _filtered(List<JobPosting> postings) {
    return postings.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.title.toLowerCase().contains(_query.toLowerCase()) ||
          p.companyName.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = _category == null || p.categoryName == _category;
      final matchesEngagement = _engagementTypes.isEmpty || p.engagementTypes.any(_engagementTypes.contains);
      return matchesQuery && matchesCategory && matchesEngagement && _matchesBudget(p);
    }).toList();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<({Set<String> engagementTypes, double? min, double? max})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FiltersSheet(engagementTypes: _engagementTypes, minBudget: _minBudget, maxBudget: _maxBudget),
    );
    if (result == null || !mounted) return;
    setState(() {
      _engagementTypes = result.engagementTypes;
      _minBudget = result.min;
      _maxBudget = result.max;
    });
  }

  Color _statusColor(ApplicationStatus status) => switch (status) {
    ApplicationStatus.hired || ApplicationStatus.offerExtended => AppColors.teal,
    ApplicationStatus.rejected || ApplicationStatus.withdrawn => AppColors.muted,
    ApplicationStatus.interviewing || ApplicationStatus.underReview => AppColors.navyLight,
    ApplicationStatus.submitted => AppColors.statusPending,
  };

  Future<void> _openDetail(JobPosting posting, int? jobApplicationId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(posting: posting, existingApplicationId: jobApplicationId),
      ),
    );
    if (result == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<JobPosting>, Map<int, JobApplication>, List<TalentCategory>)>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final allPostings = snapshot.data?.$1 ?? const [];
        final applied = snapshot.data?.$2 ?? const <int, JobApplication>{};
        final categories = snapshot.data?.$3 ?? const <TalentCategory>[];
        final postings = _filtered(allPostings);
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.offWhite,
              surfaceTintColor: Colors.transparent,
              pinned: true,
              floating: true,
              title: const Text('Jobs'),
              actions: [
                IconButton(
                  tooltip: 'Filters',
                  icon: Badge(isLabelVisible: _hasBottomSheetFilters, smallSize: 8, child: const Icon(Icons.tune)),
                  onPressed: _openFilters,
                ),
                IconButton(
                  tooltip: 'My applications',
                  icon: const Icon(Icons.assignment_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(96),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search title or company…',
                          prefixIcon: Icon(Icons.search, color: AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            PillChip(
                              label: 'All categories',
                              selected: _category == null,
                              onTap: () => setState(() => _category = null),
                            ),
                            for (final c in categories)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: PillChip(
                                  label: c.name,
                                  selected: _category == c.name,
                                  onTap: () => setState(() => _category = _category == c.name ? null : c.name),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Couldn\'t load jobs. ${snapshot.error}',
                      style: const TextStyle(color: AppColors.statusRejected),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (postings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                          child: const Icon(Icons.work_outline, size: 32, color: AppColors.muted),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          allPostings.isEmpty ? 'No open roles yet' : 'No matches',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allPostings.isEmpty
                              ? 'Check back soon — new roles show up here as employers post them.'
                              : 'Try a different search term or filter.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final p = postings[i];
                    final application = applied[p.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BrandCard(
                        onTap: () => _openDetail(p, application?.id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                ),
                                if (application != null)
                                  StatusBadge(label: application.status.label, color: _statusColor(application.status))
                                else
                                  const Icon(Icons.chevron_right, color: AppColors.muted),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(p.companyName, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PillChip(icon: Icons.payments_outlined, label: p.budgetLabel),
                                if (p.categoryName != null) PillChip(label: p.categoryName!),
                                for (final type in p.engagementTypes)
                                  PillChip(label: engagementTypeLabels[type] ?? type),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: postings.length),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Engagement-type (multi-select) and budget min/max fields, applied
/// together via the sheet's own Apply button rather than live-filtering
/// as the candidate types -- avoids the list jumping under a half-typed
/// number.
class _FiltersSheet extends StatefulWidget {
  final Set<String> engagementTypes;
  final double? minBudget;
  final double? maxBudget;

  const _FiltersSheet({required this.engagementTypes, required this.minBudget, required this.maxBudget});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  final Set<String> _engagementTypes = {};
  late final _minController = TextEditingController(
    text: widget.minBudget == null ? '' : widget.minBudget!.toStringAsFixed(0),
  );
  late final _maxController = TextEditingController(
    text: widget.maxBudget == null ? '' : widget.maxBudget!.toStringAsFixed(0),
  );

  @override
  void initState() {
    super.initState();
    _engagementTypes.addAll(widget.engagementTypes);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _apply() {
    Navigator.of(context).pop((
      engagementTypes: _engagementTypes,
      min: double.tryParse(_minController.text.trim()),
      max: double.tryParse(_maxController.text.trim()),
    ));
  }

  void _clear() {
    Navigator.of(context).pop((engagementTypes: <String>{}, min: null, max: null));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 18),
            const Text('Engagement type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in engagementTypeLabels.entries)
                  PillChip(
                    label: entry.value,
                    selected: _engagementTypes.contains(entry.key),
                    onTap: () => setState(() {
                      if (!_engagementTypes.add(entry.key)) _engagementTypes.remove(entry.key);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Rate / budget', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    decoration: const InputDecoration(prefixText: '\$ ', hintText: 'Max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Matched against each role\'s posted range, whatever its pay period.',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _clear, child: const Text('Clear filters')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(onPressed: _apply, child: const Text('Apply')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
