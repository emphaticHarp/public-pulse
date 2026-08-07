import 'dart:io';
import '../compression/image_compressor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/profile_model.dart';

/// Singleton repository for all profile-related Supabase operations.
///
/// running expensive COUNT(*) aggregates.
class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  // ── Bucket names ──────────────────────────────────────────────────────────
  static const _avatarBucket = 'avatars';
  static const _coverBucket = 'covers';

  // ── Supabase shortcuts ────────────────────────────────────────────────────
  final _db = Supabase.instance.client.from('profiles');
  final _follows = Supabase.instance.client.from('user_follows');
  final _storage = Supabase.instance.client.storage;
  final _auth = Supabase.instance.client.auth;

  String get _uid => _auth.currentUser!.id;

  // ── Profile CRUD ──────────────────────────────────────────────────────────

  /// Fetches the currently authenticated user's profile.
  Future<ProfileModel> getProfile() async {
    final data = await _db.select().eq('user_id', _uid).single();
    return ProfileModel.fromJson(data);
  }

  /// Returns `true` when [username] is not already taken by another account.
  Future<bool> isUsernameAvailable(String username) async {
    final data = await _db
        .select('user_id')
        .eq('username', username)
        .neq('user_id', _uid)
        .maybeSingle();
    return data == null;
  }

  Future<ProfileModel> updateProfile({
    String? username,
    String? bio,
    File? avatarFile,
    File? coverFile,
  }) async {
    final avatarPath = avatarFile != null
        ? await _uploadCompressed(avatarFile, bucket: _avatarBucket)
        : null;
    final coverPath = coverFile != null
        ? await _uploadCompressed(coverFile, bucket: _coverBucket)
        : null;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (username != null) updates['username'] = username;
    updates['bio'] = (bio?.trim().isEmpty ?? true) ? null : bio!.trim();
    if (avatarPath != null) updates['avatar_path'] = avatarPath;
    if (coverPath != null) updates['cover_path'] = coverPath;

    final data = await _db
        .update(updates)
        .eq('user_id', _uid)
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }

  // ── Storage helpers ───────────────────────────────────────────────────────

  /// Compresses [file] and uploads it to [bucket], returning the storage path.
  Future<String> _uploadCompressed(File file, {required String bucket}) async {
    final compressed = await ImageCompressor().compressImage(
      file.absolute.path,
    );
    final bytes = await (compressed ?? file).readAsBytes();

    final path = '$_uid/${DateTime.now().microsecondsSinceEpoch}.webp';
    await _storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: false,
            contentType: 'image/webp',
          ),
        );
    return path;
  }

  final _urlCache = <String, String>{};

  /// Resolves a storage [path] to a public URL, memoising the result.
  ///
  /// Already-absolute URLs (http/https) are returned unchanged so that
  /// OAuth avatar URLs work without modification.
  String resolveUrl(String path, {String bucket = _avatarBucket}) {
    // Return absolute URLs (Google OAuth, CDN, etc.) unchanged.
    // Checks 'http' prefix to handle both:
    //   • https://  (normal)
    //   • https:/   (single-slash edge case seen in Google OAuth avatar paths)
    if (path.startsWith('http')) return path;
    final key = '$bucket/$path';
    return _urlCache[key] ??=
        '${_storage.from(bucket).getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Evicts [path] from the URL cache so the next [resolveUrl] call produces
  /// a fresh URL (call this after uploading a new avatar or cover image).
  void invalidateUrl(String path, {String bucket = _avatarBucket}) =>
      _urlCache.remove('$bucket/$path');

  // ── Followers / Following ─────────────────────────────────────────────────

  Future<List<FollowerModel>> getFollowers(
    String userId, {
    int limit = 10,
    String? afterCursor,
  }) async {
    // Filter modifiers must come before ordering/limiting (Supabase SDK rule).
    var q = _follows
        .select(
          'follower_profile_id,'
          'profiles!user_follows_follower_profile_id_fkey'
          '(user_id, username, display_name, avatar_path)',
        )
        .eq('following_profile_id', userId);

    if (afterCursor != null) q = q.gt('follower_profile_id', afterCursor);

    final data = await q
        .order('follower_profile_id', ascending: true)
        .limit(limit);
    return (data as List)
        .map((e) => FollowerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns a cursor-paginated list of accounts that [userId] is following.
  ///
  /// Pass [afterCursor] to advance; omit for page one.
  Future<List<FollowerModel>> getFollowing(
    String userId, {
    int limit = 10,
    String? afterCursor,
  }) async {
    var q = _follows
        .select(
          'following_profile_id,'
          'profiles!user_follows_following_profile_id_fkey'
          '(user_id, username, display_name, avatar_path)',
        )
        .eq('follower_profile_id', userId);

    if (afterCursor != null) q = q.gt('following_profile_id', afterCursor);

    final data = await q
        .order('following_profile_id', ascending: true)
        .limit(limit);
    return (data as List)
        .map((e) => FollowerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({int followers, int following})> getFollowCounts(
    String userId,
  ) async {
    final data = await _db
        .select('follower_count, following_count')
        .eq('user_id', userId)
        .single();
    return (
      followers: (data['follower_count'] as num?)?.toInt() ?? 0,
      following: (data['following_count'] as num?)?.toInt() ?? 0,
    );
  }
}
