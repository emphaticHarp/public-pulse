import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreatePostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();

  static const String imageBucket = 'posts-images';
  static const String videoBucket = 'posts-videos';

  String _storageUrl(String bucket) =>
      '${dotenv.env['SUPABASE_URL']}/storage/v1/object/$bucket';

  /// Log Supabase URL (masked) to verify env is loaded
  void _logEnvCheck() {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    debugPrint('🔍 [CreatePostRepo] SUPABASE_URL loaded: ${url != null && url.isNotEmpty ? "YES (${url.substring(0, url.indexOf('.', url.indexOf('//') + 2) + 4)}...)" : "NO / EMPTY"}');
    debugPrint('🔍 [CreatePostRepo] SUPABASE_PUBLISHABLE_KEY loaded: ${key != null && key.isNotEmpty ? "YES (length: ${key.length})" : "NO / EMPTY"}');
  }

  Future<String> uploadImage({
    required File imageFile,
    required String fileName,
    required String bucket,
    required void Function(int sent, int total) onProgress,
  }) async {
    debugPrint('☁️ [CreatePostRepo] uploadImage() STARTED');
    debugPrint('☁️ [CreatePostRepo] File: ${imageFile.path}');
    debugPrint('☁️ [CreatePostRepo] FileName: $fileName');
    debugPrint('☁️ [CreatePostRepo] Bucket: $bucket');

    _logEnvCheck();

    final session = _supabase.auth.currentSession;

    if (session == null) {
      debugPrint('🔴 [CreatePostRepo] User is NOT logged in. session is null');
      throw Exception("User is not logged in.");
    }

    debugPrint('🟢 [CreatePostRepo] Session active. User ID: ${session.user.id}');
    debugPrint('🟢 [CreatePostRepo] Access token length: ${session.accessToken.length}');

    final headers = {
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
      'x-upsert': 'false',
      'Content-Type': 'application/octet-stream',
    };

    try {
      final userId = session.user.id;
      final storagePath = '$userId/$fileName';
      debugPrint('☁️ [CreatePostRepo] Storage path: $storagePath');

      final bytes = await imageFile.readAsBytes();
      debugPrint('☁️ [CreatePostRepo] File read as bytes: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');

      final uploadUrl = '${_storageUrl(bucket)}/$storagePath';
      debugPrint('☁️ [CreatePostRepo] Upload URL: $uploadUrl');
      debugPrint('☁️ [CreatePostRepo] Starting HTTP PUT upload...');

      final response = await _dio.put(
        uploadUrl,
        data: bytes,
        options: Options(headers: headers),
        onSendProgress: onProgress,
      );

      debugPrint('☁️ [CreatePostRepo] Upload response status: ${response.statusCode}');
      debugPrint('☁️ [CreatePostRepo] Upload response data: ${response.data}');

      if (response.statusCode == 200) {
        debugPrint('🟢 [CreatePostRepo] uploadImage() SUCCESS - path: $storagePath');
        return storagePath;
      }

      debugPrint('🔴 [CreatePostRepo] Upload failed with status: ${response.statusCode}');
      throw Exception("Failed to upload image. Status: ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint('🔴 [CreatePostRepo] DioException during upload!');
      debugPrint('🔴 [CreatePostRepo] Dio error type: ${e.type}');
      debugPrint('🔴 [CreatePostRepo] Dio error message: ${e.message}');
      debugPrint('🔴 [CreatePostRepo] Dio response status: ${e.response?.statusCode}');
      debugPrint('🔴 [CreatePostRepo] Dio response data: ${e.response?.data}');
      debugPrint('🔴 [CreatePostRepo] Dio response headers: ${e.response?.headers}');
      debugPrint('🔴 [CreatePostRepo] Dio request URL: ${e.requestOptions.uri}');
      debugPrint('🔴 [CreatePostRepo] Dio request method: ${e.requestOptions.method}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('🔴 [CreatePostRepo] Unexpected error during upload: $e');
      debugPrint('🔴 [CreatePostRepo] Error type: ${e.runtimeType}');
      debugPrint('🔴 [CreatePostRepo] Stack trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<String?> getCurrentProfileId() async {
    debugPrint('👤 [CreatePostRepo] getCurrentProfileId() STARTED');

    final user = _supabase.auth.currentUser;
    debugPrint('👤 [CreatePostRepo] Current user: ${user?.id ?? "NULL"}');

    if (user == null) {
      debugPrint('🔴 [CreatePostRepo] No current user found. Returning null.');
      return null;
    }

    debugPrint('👤 [CreatePostRepo] Querying profiles table for user_id: ${user.id}');

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

  Future<String> createPost({
    required String profileId,
    String? caption,
    String? location,
    required String visibility,
    required List<Map<String, String>> mediaItems,
  }) async {
    debugPrint('💾 [CreatePostRepo] createPost() STARTED');
    debugPrint('💾 [CreatePostRepo] profileId: $profileId');
    debugPrint('💾 [CreatePostRepo] caption: $caption');
    debugPrint('💾 [CreatePostRepo] location: $location');
    debugPrint('💾 [CreatePostRepo] visibility: $visibility');
    debugPrint('💾 [CreatePostRepo] mediaItems count: ${mediaItems.length}');
    for (int i = 0; i < mediaItems.length; i++) {
      debugPrint('💾 [CreatePostRepo]   Media[$i]: ${mediaItems[i]}');
    }

    debugPrint('💾 [CreatePostRepo] Inserting into posts table...');
    try {
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
      debugPrint('🟢 [CreatePostRepo] Post inserted. Post ID: $postId');

      try {
        debugPrint('💾 [CreatePostRepo] Inserting ${mediaItems.length} media items into post_media...');
        final mediaRows = mediaItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final row = {
            'post_id': postId,
            'storage_path': item['storage_path'],
            'media_type': item['media_type'],
            'media_order': index+1,
            'thumbnail_path': null,
          };
          debugPrint('💾 [CreatePostRepo]   Media row[$index]: $row');
          return row;
        }).toList();

        await _supabase.from('post_media').insert(mediaRows);
        debugPrint('🟢 [CreatePostRepo] All media items inserted successfully!');
        debugPrint('🟢 [CreatePostRepo] createPost() COMPLETE - Post ID: $postId');
        return postId;
      } catch (e, stackTrace) {
        debugPrint('🔴 [CreatePostRepo] Media insert FAILED! Rolling back post $postId');
        debugPrint('🔴 [CreatePostRepo] Error: $e');
        debugPrint('🔴 [CreatePostRepo] Stack trace:');
        debugPrint('$stackTrace');
        debugPrint('🔴 [CreatePostRepo] Deleting post $postId (rollback)...');
        await _supabase.from('posts').delete().eq('id', postId);
        debugPrint('🔴 [CreatePostRepo] Rollback complete. Re-throwing error.');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 [CreatePostRepo] Posts table insert FAILED!');
      debugPrint('🔴 [CreatePostRepo] Error: $e');
      debugPrint('🔴 [CreatePostRepo] Error type: ${e.runtimeType}');
      debugPrint('🔴 [CreatePostRepo] Stack trace:');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
