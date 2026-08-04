import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../model/comment_model.dart';

class CommentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getCurrentProfileId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return profile?['id'];
    } catch (e) {
      debugPrint("getCurrentProfileId Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('''
id,
username,
avatar_path
''')
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      debugPrint("getCurrentProfile Error: $e");
      return null;
    }
  }

  Future<int> getCommentCount(String postId) async {
    final response = await _supabase
        .from('posts')
        .select('comment_count')
        .eq('id', postId)
        .single();

    return response['comment_count'] ?? 0;
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
id,
post_id,
profile_id,
content,
created_at,
profiles!comments_profile_id_fkey(
username,
avatar_path
)
''')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      return response
          .map<CommentModel>((e) => CommentModel.fromMap(e))
          .toList();
    } catch (e) {
      debugPrint("getComments Error: $e");
      return [];
    }
  }

  Future<CommentModel?> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final profileId = await getCurrentProfileId();

      if (profileId == null) return null;

      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'profile_id': profileId,
            'content': content,
          })
          .select('''
id,
post_id,
profile_id,
content,
created_at,
profiles!comments_profile_id_fkey(
  username,
  avatar_path
)
''')
          .single();

      return CommentModel.fromMap(response);
    } catch (e) {
      debugPrint("addComment Error: $e");
      return null;
    }
  }

  Future<CommentModel?> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _supabase
          .from('comments')
          .update({'content': content})
          .eq('id', commentId)
          .select('''
id,
post_id,
profile_id,
content,
created_at,
profiles!comments_profile_id_fkey(
  username,
  avatar_path
)
''')
          .single();

      return CommentModel.fromMap(response);
    } catch (e) {
      debugPrint("updateComment Error: $e");
      return null;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);

      return true;
    } catch (e) {
      debugPrint("deleteComment Error: $e");
      return false;
    }
  }
}
