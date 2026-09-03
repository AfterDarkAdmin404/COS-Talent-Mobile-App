/// Mirrors `public.job_postings`
/// (`bookkeeping/database/migrations/038_create_job_postings_and_applications.sql`),
/// read-only from this app — talent_app never writes to this table.
library;

const engagementTypeLabels = <String, String>{
  'full_time': 'Full-time',
  'part_time': 'Part-time',
  'contract': 'Contract',
  'project': 'Project-based',
};

class JobPosting {
  final int id;
  final String title;
  final String description;
  final String? categoryName;
  final String companyName;
  final List<String> engagementTypes;
  final double? budgetMinAmount;
  final double? budgetMaxAmount;
  final String? budgetPeriod;
  final DateTime? createdAt;

  const JobPosting({
    required this.id,
    required this.title,
    required this.description,
    this.categoryName,
    required this.companyName,
    this.engagementTypes = const [],
    this.budgetMinAmount,
    this.budgetMaxAmount,
    this.budgetPeriod,
    this.createdAt,
  });

  /// Expects `.select('*, talent_categories(name), employer_companies(company_name)')`.
  factory JobPosting.fromRow(Map<String, dynamic> row) {
    final categoryRow = row['talent_categories'] as Map<String, dynamic>?;
    final companyRow = row['employer_companies'] as Map<String, dynamic>?;
    return JobPosting(
      id: row['id'] as int,
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      categoryName: categoryRow?['name'] as String?,
      companyName: companyRow?['company_name'] as String? ?? 'A COS-vetted employer',
      engagementTypes: (row['engagement_types'] as List?)?.cast<String>() ?? const [],
      budgetMinAmount: (row['budget_min_amount'] as num?)?.toDouble(),
      budgetMaxAmount: (row['budget_max_amount'] as num?)?.toDouble(),
      budgetPeriod: row['budget_period'] as String?,
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : null,
    );
  }

  String get budgetLabel {
    if (budgetMinAmount == null && budgetMaxAmount == null) return 'Rate not set';
    final unit = budgetPeriod == 'hourly' ? '/hr' : '/mo';
    final min = budgetMinAmount?.toStringAsFixed(0);
    final max = budgetMaxAmount?.toStringAsFixed(0);
    if (min != null && max != null) return '\$$min–\$$max$unit';
    return '\$${min ?? max}$unit';
  }
}
