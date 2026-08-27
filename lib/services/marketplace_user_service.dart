import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marketplace_user.dart';

/// `marketplace_users.id` is the same uuid as the signed-in Supabase Auth
/// user — there's no database trigger mirroring `auth.users` into it, so
/// the app is responsible for creating the row itself. [ensureRow] is
/// called right after both signup and sign-in (idempotent — safe to call
/// on every sign-in, not just the first one) so `talent_profiles`'
/// `marketplace_user_id` FK always has something to point at.
class MarketplaceUserService {
  MarketplaceUserService._();
  static final _client = Supabase.instance.client;

  static Future<MarketplaceUser> ensureRow({
    required String id,
    required String email,
  }) async {
    final row = await _client
        .from('marketplace_users')
        .upsert({
          'id': id,
          'email': email,
          'account_type': 'candidate', // the check constraint has no 'talent' value
        }, onConflict: 'id')
        .select()
        .single();
    return MarketplaceUser.fromRow(row);
  }

  static Future<MarketplaceUser?> fetchCurrent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('marketplace_users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : MarketplaceUser.fromRow(row);
  }
}
