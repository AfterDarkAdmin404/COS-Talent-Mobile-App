/// Mirrors `public.marketplace_users`. `id` is the same uuid as the
/// Supabase Auth user (`auth.uid()`) — there's no trigger populating this
/// row automatically, the app creates it itself right after signup/sign-in.
class MarketplaceUser {
  final String id;
  final String email;
  final String accountType; // 'candidate' | 'employer' — check constraint
  final String status; // 'unverified' | 'active' | 'suspended' | 'deleted'
  final String? displayName;
  final String preferredLocale; // 'en' | 'es' | 'pt'

  const MarketplaceUser({
    required this.id,
    required this.email,
    required this.accountType,
    required this.status,
    this.displayName,
    required this.preferredLocale,
  });

  factory MarketplaceUser.fromRow(Map<String, dynamic> row) => MarketplaceUser(
    id: row['id'] as String,
    email: row['email'] as String,
    accountType: row['account_type'] as String,
    status: row['status'] as String,
    displayName: row['display_name'] as String?,
    preferredLocale: row['preferred_locale'] as String,
  );
}
