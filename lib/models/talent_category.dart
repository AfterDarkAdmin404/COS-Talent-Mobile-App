/// Mirrors `public.talent_categories`. Joined onto a profile through
/// `talent_profile_categories(talent_profile_id, category_id, is_primary)`.
class TalentCategory {
  final int id;
  final String slug;
  final String name;

  const TalentCategory({required this.id, required this.slug, required this.name});

  factory TalentCategory.fromRow(Map<String, dynamic> row) => TalentCategory(
    id: row['id'] as int,
    slug: row['slug'] as String,
    name: row['name'] as String,
  );

  @override
  bool operator ==(Object other) => other is TalentCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
