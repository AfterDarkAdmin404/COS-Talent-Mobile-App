import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Uploads to the `talent-photos` and `talent-documents` buckets.
///
/// Paths are random UUIDs, never the candidate's row id or user id — the
/// photo bucket is public, so an id-derived path would make the whole
/// table enumerable through storage even for unpublished profiles
/// (`024_create_talent_profiles.sql:91-93`).
class StorageService {
  StorageService._();
  static final _client = Supabase.instance.client;
  static const _uuid = Uuid();

  static Future<String> uploadPhoto(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '${_uuid.v4()}.$ext';
    await _client.storage.from('talent-photos').upload(path, file);
    return path;
  }

  static Future<String> uploadResume(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final path = '${_uuid.v4()}.$ext';
    await _client.storage.from('talent-documents').upload(path, file);
    return path;
  }

  static String photoPublicUrl(String path) =>
      _client.storage.from('talent-photos').getPublicUrl(path);
}
