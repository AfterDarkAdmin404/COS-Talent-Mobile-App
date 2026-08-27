/// Mirrors `public.skills`. Joined onto a profile through
/// `talent_profile_skills(talent_profile_id, skill_id)`.
class Skill {
  final int id;
  final String slug;
  final String name;

  const Skill({required this.id, required this.slug, required this.name});

  factory Skill.fromRow(Map<String, dynamic> row) => Skill(
    id: row['id'] as int,
    slug: row['slug'] as String,
    name: row['name'] as String,
  );

  @override
  bool operator ==(Object other) => other is Skill && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
