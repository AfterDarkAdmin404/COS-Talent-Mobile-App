import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/talent_category.dart';

class TalentCategoryService {
  TalentCategoryService._();
  static final _client = Supabase.instance.client;

  static Future<List<TalentCategory>> fetchActive() async {
    final rows = await _client
        .from('talent_categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => TalentCategory.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
