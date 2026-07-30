import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      // Get current logged-in profile id
      final user = _supabase.auth.currentUser;

      if (user == null) return [];

      final profile =
          await _supabase
              .from('profiles')
              .select('id')
              .eq('user_id', user.id)
              .single();

      final profileId = profile['id'];

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
              username,
              display_name,
              avatar_path
            ),

            post:posts(
              media:post_media(
                storage_path,
                media_type,
                media_order
              )
            )
          ''')
          .eq('recipient_profile_id', profileId)
          .order('created_at', ascending: false);

      return response
          .map<NotificationModel>(
            (json) => NotificationModel.fromJson(json),
          )
          .toList();
    } catch (e, stack) {
      debugPrint("Notification Error: $e");
      debugPrintStack(stackTrace: stack);
      return [];
    }

    

    
  }
  

  
}