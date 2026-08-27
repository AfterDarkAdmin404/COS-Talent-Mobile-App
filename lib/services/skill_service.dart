import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill.dart';

class SkillService {
  SkillService._();
  static final _client = Supabase.instance.client;

  static Future<List<Skill>> fetchActive() async {
    final rows = await _client
        .from('skills')
        .select()
        .eq('is_active', true)
        .order('name');
    return (rows as List).map((r) => Skill.fromRow(r as Map<String, dynamic>)).toList();
  }
}
