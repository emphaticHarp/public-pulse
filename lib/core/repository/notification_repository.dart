import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return [];
      }

      // ----------------------------------------------------------
      // CURRENT USER PROFILE
      // ----------------------------------------------------------

      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id'] as String;

      // ----------------------------------------------------------
      // NOTIFICATIONS
      // ----------------------------------------------------------

      final response = await _supabase
          .from('notifications')
          .select('''
            id,
            recipient_profile_id,
            actor_profile_id,
            notification_type,
            post_id,
            comment_id,
            is_read,
            created_at,

            actor:profiles!notifications_actor_profile_id_fkey(
              id,
              username,
              display_name,
              avatar_path
            ),

            post:posts(
              id,
              post_media(
                id,
                storage_path,
                thumbnail_path,
                media_type,
                media_order
              )
            ),

            comment:comments(
              id,
              content
            )
          ''')
          .eq('recipient_profile_id', profileId)
          .order('created_at', ascending: false);

      for (final _ in response) {}

      // ----------------------------------------------------------
      // TRANSFORM DATA FOR NotificationModel
      // ----------------------------------------------------------

      final notifications = <NotificationModel>[];

      for (final raw in response) {
        try {
          final json = Map<String, dynamic>.from(raw);

          // ------------------------------------------------------
          // post_media -> media
          // ------------------------------------------------------

          final post = json['post'];

          if (post is Map<String, dynamic>) {
            final postMedia = post['post_media'];

            json['post'] = {
              ...post,
              'media': postMedia is List ? postMedia : <dynamic>[],
            };
          }

          // ------------------------------------------------------
          // COMMENT
          // ------------------------------------------------------

          final comment = json['comment'];

          if (comment is Map<String, dynamic>) {
            json['comment_text'] = comment['content'];
          }

          notifications.add(NotificationModel.fromJson(json));
        } catch (_) {
          // Intentionally ignored.
        }
      }

      return notifications;
    } catch (_) {
      return [];
    }
  }

  Future<void> followBack(String actorProfileId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    // ----------------------------------------------------------
    // GET MY PROFILE ID
    // ----------------------------------------------------------

    final myProfile = await _supabase
        .from('profiles')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final myProfileId = myProfile['id'] as String;

    if (myProfileId == actorProfileId) {
      return;
    }

    // ----------------------------------------------------------
    // GET MY FOLLOWING CHUNKS
    // ----------------------------------------------------------

    final followingRows = await _supabase
        .from('user_follow2_chunked')
        .select('id, chunk, following_profile_ids')
        .eq('profile_id', myProfileId)
        .order('chunk', ascending: true);

    // ----------------------------------------------------------
    // CHECK IF ALREADY FOLLOWING
    // ----------------------------------------------------------

    for (final row in followingRows) {
      final ids = row['following_profile_ids'];

      if (ids is List &&
          ids.map((e) => e.toString()).contains(actorProfileId)) {
        return;
      }
    }

    // ----------------------------------------------------------
    // FIND CHUNK WITH SPACE
    // ----------------------------------------------------------

    const int chunkSize = 100;

    Map<String, dynamic>? targetChunk;

    for (final row in followingRows) {
      final ids = row['following_profile_ids'];

      final count = ids is List ? ids.length : 0;

      if (count < chunkSize) {
        targetChunk = row;
        break;
      }
    }

    // ----------------------------------------------------------
    // CREATE NEW CHUNK
    // ----------------------------------------------------------

    if (targetChunk == null) {
      final int nextChunk;

      if (followingRows.isEmpty) {
        nextChunk = 0;
      } else {
        nextChunk = (followingRows.last['chunk'] as num).toInt() + 1;
      }

      await _supabase.from('user_follow2_chunked').insert({
        'profile_id': myProfileId,
        'chunk': nextChunk,
        'follower_profile_ids': <String>[],
        'following_profile_ids': [actorProfileId],
      });
    }
    // ----------------------------------------------------------
    // ADD TO EXISTING CHUNK
    // ----------------------------------------------------------
    else {
      final chunkId = targetChunk['id'];

      final existingIds = targetChunk['following_profile_ids'];

      final List<String> followingIds = existingIds is List
          ? existingIds.map((e) => e.toString()).toList()
          : <String>[];

      if (!followingIds.contains(actorProfileId)) {
        followingIds.add(actorProfileId);

        await _supabase
            .from('user_follow2_chunked')
            .update({
              'following_profile_ids': followingIds,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', chunkId);
      }
    }
  }
}
