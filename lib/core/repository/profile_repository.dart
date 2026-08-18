import 'dart:io';
import '../compression/image_compressor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/profile_model.dart';
import 'package:flutter/foundation.dart';

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
  final _followChunks = Supabase.instance.client.from('user_follow2_chunked');
  final _storage = Supabase.instance.client.storage;
  final _auth = Supabase.instance.client.auth;

  String get _uid => _auth.currentUser!.id;

  // ── Profile CRUD ──────────────────────────────────────────────────────────

  /// Fetches the currently authenticated user's profile.
  Future<ProfileModel> getProfile() async {
    final data = await _db.select().eq('user_id', _uid).single();
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> getProfileByUserId(String userId) async {
    final data = await _db.select().eq('user_id', userId).single();

    final profile = ProfileModel.fromJson(data);

    final counts = await getFollowCounts(userId);

    return ProfileModel(
      id: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      bio: profile.bio,
      avatarPath: profile.avatarPath,
      coverPath: profile.coverPath,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      followerCount: counts.followers,
      followingCount: counts.following,
      postCount: profile.postCount,
      accountStatus: profile.accountStatus,
      referCode: profile.referCode,
    );
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
    String? displayName,
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

    if (displayName != null) {
      updates['display_name'] = displayName.trim().isEmpty
          ? null
          : displayName.trim();
    }

    if (username != null) {
      updates['username'] = username;
    }

    updates['bio'] = (bio?.trim().isEmpty ?? true)
        ? null
        : bio!.trim();
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
    return _urlCache[key] ??= _storage.from(bucket).getPublicUrl(path);
  }

  /// Evicts [path] from the URL cache so the next [resolveUrl] call produces
  /// a fresh URL (call this after uploading a new avatar or cover image).
  void invalidateUrl(String path, {String bucket = _avatarBucket}) =>
      _urlCache.remove('$bucket/$path');

  // ── Followers / Following ─────────────────────────────────────────────────

  Future<List<FollowerModel>> getFollowers(String userId) async {
    debugPrint('[FF_REPO] ===== GET FOLLOWERS =====');
    final profileId = await _getProfileIdFromUserId(userId);

    debugPrint('[FF_REPO] actual profile_id = $profileId');

    final data = await _followChunks
        .select('profile_id, chunk, follower_profile_ids')
        .eq('profile_id', profileId)
        .order('chunk', ascending: true);
    debugPrint('[FF_REPO] Chunk rows = $data');

    final Set<String> followerIds = {};

    for (final row in data) {
      debugPrint('[FF_REPO] Row = $row');

      final ids = row['follower_profile_ids'];

      if (ids is List) {
        debugPrint('[FF_REPO] follower_profile_ids = $ids');

        for (final id in ids) {
          if (id != null) {
            followerIds.add(id.toString());
          }
        }
      }
    }

    debugPrint('[FF_REPO] Total follower IDs = ${followerIds.length}');
    debugPrint('[FF_REPO] IDs = $followerIds');

    if (followerIds.isEmpty) {
      return [];
    }

    final profiles = await _db
        .select('user_id, username, display_name, avatar_path')
        .inFilter('id', followerIds.toList());

    debugPrint('[FF_REPO] Profiles returned = $profiles');

    return profiles.map<FollowerModel>((row) {
      return FollowerModel(
        userId: row['user_id'] as String,
        username: row['username'] as String? ?? '',
        displayName: row['display_name'] as String?,
        avatarPath: row['avatar_path'] as String?,
      );
    }).toList();
  }

  Future<String> _getProfileIdFromUserId(String userId) async {
    final data = await _db.select('id').eq('user_id', userId).single();

    return data['id'] as String;
  }

  Future<ProfileModel> getProfileByProfileId(String profileId) async {
    debugPrint(
      '[PROFILE_REPO] Loading profile by internal profile ID: $profileId',
    );

    final data = await _db.select().eq('id', profileId).single();

    final profile = ProfileModel.fromJson(data);

    final counts = await getFollowCountsByProfileId(profileId);

    return ProfileModel(
      id: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      bio: profile.bio,
      avatarPath: profile.avatarPath,
      coverPath: profile.coverPath,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      followerCount: counts.followers,
      followingCount: counts.following,
      postCount: profile.postCount,
      accountStatus: profile.accountStatus,
      referCode: profile.referCode,
    );
  }

  Future<({int followers, int following})> getFollowCountsByProfileId(
    String profileId,
  ) async {
    final data = await _db
        .select('follower_count, following_count')
        .eq('id', profileId)
        .single();

    return (
      followers: (data['follower_count'] as num?)?.toInt() ?? 0,
      following: (data['following_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<List<Map<String, dynamic>>> getUserPostsByProfileId(
    String profileId,
  ) async {
    debugPrint('[PROFILE POSTS] Getting posts for profileId: $profileId');

    // ----------------------------------------------------------
    // 1. Get profile information
    // ----------------------------------------------------------

    final profileData = await _db
        .select('id, user_id, username, display_name, avatar_path, is_private')
        .eq('id', profileId)
        .single();

    debugPrint('[PROFILE POSTS] Profile = ${profileData['username']}');

    // ----------------------------------------------------------
    // 2. Get posts + media
    // ----------------------------------------------------------

    final posts = await Supabase.instance.client
        .from('posts')
        .select('''
        id,
        profile_id,
        caption,
        latitude,
        longitude,
        location_name,
        visibility,
        status,
        like_count,
        comment_count,
        save_count,
        share_count,
        view_count,
        created_at,
        updated_at,
        deleted_at,
        post_media(
          id,
          post_id,
          media_order,
          media_type,
          storage_path,
          thumbnail_path,
          width,
          height,
          duration_seconds,
          file_size,
          created_at
        )
      ''')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    debugPrint('[PROFILE POSTS] Supabase returned ${posts.length} posts');

    // ----------------------------------------------------------
    // 3. Transform Supabase response
    // ----------------------------------------------------------

    final result = <Map<String, dynamic>>[];

    for (final post in posts) {
      final data = Map<String, dynamic>.from(post);

      // --------------------------------------------------------
      // Rename post_media -> media
      // --------------------------------------------------------

      final postMedia = data['post_media'];

      data['media'] = postMedia is List ? postMedia : [];

      // --------------------------------------------------------
      // Add profile information
      // --------------------------------------------------------

      data['profile'] = {
        'username': profileData['username'] ?? '',
        'display_name': profileData['display_name'] ?? '',
        'avatar_path': profileData['avatar_path'],
        'is_private': profileData['is_private'] ?? false,
      };

      // --------------------------------------------------------
      // User interaction
      // --------------------------------------------------------

      data['my_like'] = [];
      data['my_save'] = [];

      debugPrint(
        '[PROFILE POSTS] '
        'post=${data['id']} '
        'media=${(data['media'] as List).length}',
      );

      result.add(data);
    }

    debugPrint('[PROFILE POSTS] Returning ${result.length} transformed posts');

    return result;
  }

  /// Returns a cursor-paginated list of accounts that [userId] is following.
  ///
  /// Pass [afterCursor] to advance; omit for page one.
  Future<List<FollowerModel>> getFollowing(String userId) async {
    debugPrint('[FF_REPO] ===== GET FOLLOWING =====');
    final profileId = await _getProfileIdFromUserId(userId);

    debugPrint('[FF_REPO] actual profile_id = $profileId');

    final data = await _followChunks
        .select('profile_id, chunk, following_profile_ids')
        .eq('profile_id', profileId)
        .order('chunk', ascending: true);

    debugPrint('[FF_REPO] Chunk rows = $data');

    final Set<String> followingIds = {};

    for (final row in data) {
      debugPrint('[FF_REPO] Row = $row');

      final ids = row['following_profile_ids'];

      if (ids is List) {
        debugPrint('[FF_REPO] following_profile_ids = $ids');

        for (final id in ids) {
          if (id != null) {
            followingIds.add(id.toString());
          }
        }
      }
    }

    debugPrint('[FF_REPO] Total following IDs = ${followingIds.length}');
    debugPrint('[FF_REPO] IDs = $followingIds');

    if (followingIds.isEmpty) {
      return [];
    }

    final profiles = await _db
        .select('user_id, username, display_name, avatar_path')
        .inFilter('id', followingIds.toList());

    debugPrint('[FF_REPO] Profiles returned = $profiles');

    return profiles.map<FollowerModel>((row) {
      return FollowerModel(
        userId: row['user_id'] as String,
        username: row['username'] as String? ?? '',
        displayName: row['display_name'] as String?,
        avatarPath: row['avatar_path'] as String?,
      );
    }).toList();
  }

  /// Fetches both [follower_count] and [following_count] for [userId] in a
  /// single round-trip from the `profiles` table.
  ///
  /// Prefer this over calling [getFollowersCount] + [getFollowingCount]
  /// separately when you need both values at the same time (e.g. profile screen).
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

  // ─────────────────────────────────────────────────────────────
  // PROFILE POSTS
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    debugPrint('[PROFILE POSTS] Getting posts for user: $userId');

    // ----------------------------------------------------------
    // 1. Get target profile
    // ----------------------------------------------------------

    final profileData = await _db
        .select('''
        id,
        user_id,
        username,
        display_name,
        avatar_path,
        is_private
      ''')
        .eq('user_id', userId)
        .single();

    final profileId = profileData['id'] as String;

    debugPrint('[PROFILE POSTS] profileId = $profileId');

    // ----------------------------------------------------------
    // 2. Get posts + media
    // ----------------------------------------------------------

    final posts = await Supabase.instance.client
        .from('posts')
        .select('''
        id,
        profile_id,
        caption,
        latitude,
        longitude,
        location_name,
        visibility,
        status,
        like_count,
        comment_count,
        save_count,
        share_count,
        view_count,
        created_at,
        updated_at,
        deleted_at,
        post_media(
          id,
          post_id,
          media_order,
          media_type,
          storage_path,
          thumbnail_path,
          width,
          height,
          duration_seconds,
          file_size,
          created_at
        )
      ''')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    debugPrint('[PROFILE POSTS] Supabase returned ${posts.length} posts');

    for (final post in posts) {
      debugPrint(
        '[PROFILE RAW] '
        'id=${post['id']} '
        'post_media=${post['post_media']}',
      );
    }

    // ----------------------------------------------------------
    // 3. Convert to PostModel format
    // ----------------------------------------------------------

    final result = <Map<String, dynamic>>[];

    for (final post in posts) {
      final data = Map<String, dynamic>.from(post);

      // Profile information expected by PostModel
      data['profile'] = {
        'username': profileData['username'] ?? '',
        'display_name': profileData['display_name'] ?? '',
        'avatar_path': profileData['avatar_path'],
        'is_private': profileData['is_private'] ?? false,
      };

      // IMPORTANT:
      // PostModel expects "media", not "post_media".
      final postMedia = data['post_media'];

      if (postMedia is List) {
        data['media'] = postMedia;
      } else {
        data['media'] = [];
      }

      // Profile page doesn't need these.
      data['my_like'] = [];
      data['my_save'] = [];

      debugPrint(
        '[PROFILE POSTS] '
        'post=${data['id']} '
        'media=${(data['media'] as List).length}',
      );

      result.add(data);
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────
  // SAVED POSTS
  // ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSavedPosts(String userId) async {
    final profile = await _db.select('id').eq('user_id', userId).single();

    final profileId = profile['id'] as String;

    final saved = await Supabase.instance.client
        .from('saved_posts')
        .select('''
        id,
        profile_id,
        post_id,
        created_at,
        posts(
          id,
          profile_id,
          caption,
          latitude,
          longitude,
          location_name,
          visibility,
          status,
          like_count,
          comment_count,
          save_count,
          share_count,
          view_count,
          created_at,
          updated_at,
          deleted_at,
          post_media(
            id,
            post_id,
            media_order,
            media_type,
            storage_path,
            thumbnail_path,
            width,
            height,
            duration_seconds,
            file_size,
            created_at
          )
        )
      ''')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(saved);
  }

  Future<List<ProfileModel>> searchUsers(String query) async {
    final data = await _db
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .limit(20);

    return (data as List).map((e) => ProfileModel.fromJson(e)).toList();
  }
}
