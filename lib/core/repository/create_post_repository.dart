import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/core/services/bunny_upload_service.dart';

class CreatePostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String imageBucket = 'posts-images';

  static const String bunnyImageFolder = 'posts-images';


  /// Log Supabase URL (masked) to verify env is loaded
 

  Future<String> uploadImage({
    required File imageFile,
    required String fileName,
    required String bucket,
    void Function(int sent, int total)? onProgress,
  }) async {
    debugPrint('[CREATE POST] Uploading image to Bunny CDN');

    // Optional initial progress.
    final totalBytes = await imageFile.length();

    onProgress?.call(0, totalBytes);

    final bunnyUrl = await BunnyUploadService.instance.uploadMedia(
      imageFile,
      bunnyImageFolder,
    );

    if (bunnyUrl == null || bunnyUrl.isEmpty) {
      throw Exception('Bunny image upload failed');
    }

    // MultipartRequest in BunnyUploadService does not currently expose
    // upload progress, so mark it complete after successful upload.
    onProgress?.call(totalBytes, totalBytes);

    debugPrint('[CREATE POST] Bunny image uploaded successfully: $bunnyUrl');

    // IMPORTANT:
    // This is already the FULL Bunny CDN URL.
    return bunnyUrl;
  }

  Future<String?> getCurrentProfileId() async {
    debugPrint('👤 [CreatePostRepo] getCurrentProfileId() STARTED');

    final user = _supabase.auth.currentUser;
    debugPrint('👤 [CreatePostRepo] Current user: ${user?.id ?? "NULL"}');

    if (user == null) {
      debugPrint('🔴 [CreatePostRepo] No current user found. Returning null.');
      return null;
    }

    debugPrint(
      '👤 [CreatePostRepo] Querying profiles table for user_id: ${user.id}',
    );

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      debugPrint('👤 [CreatePostRepo] Profile query result: $profile');

      if (profile == null) {
        debugPrint('🔴 [CreatePostRepo] No profile found for user ${user.id}');
        return null;
      }

      final profileId = profile['id'] as String;
      debugPrint('🟢 [CreatePostRepo] Profile ID found: $profileId');
      return profileId;
    } catch (e, stackTrace) {
      debugPrint('🔴 [CreatePostRepo] Error fetching profile: $e');
      debugPrint('🔴 [CreatePostRepo] Stack trace:');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String profileId,
    String? caption,
    String? location,
    required String visibility,
    required List<Map<String, dynamic>> mediaItems,
  }) async {
    final postResponse = await _supabase
        .from('posts')
        .insert({
          'profile_id': profileId,
          'caption': caption,
          'location_name': location,
          'visibility': visibility,
        })
        .select('id')
        .single();

    final postId = postResponse['id'] as String;

    try {
      final mediaRows = mediaItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return {
          'post_id': postId,
          'storage_path': item['storage_path'],
          'media_type': item['media_type'],
          'media_order': index + 1,
          'thumbnail_path': null,
          'width': item['width'],
          'height': item['height'],
        };
      }).toList();

      // select('id') so we get back the generated post_media ids, in the same order inserted
      final insertedMedia = await _supabase
          .from('post_media')
          .insert(mediaRows)
          .select('id');

      final mediaIds = (insertedMedia as List)
          .map((row) => row['id'] as String)
          .toList();

      return {'post_id': postId, 'media_ids': mediaIds};
    } catch (e) {
      debugPrint("Media insert failed, rolling back post $postId: $e");
      await _supabase.from('posts').delete().eq('id', postId);
      rethrow;
    }
  }

  Future<void> insertMediaMetadata(
    List<Map<String, dynamic>> metadataRows,
  ) async {
    if (metadataRows.isEmpty) return;
    await _supabase.from('media_metadata').insert(metadataRows);
  }
}
