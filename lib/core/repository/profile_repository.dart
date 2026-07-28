import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../model/profile_model.dart';

class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  final _db = Supabase.instance.client.from('profiles');
  final _storage = Supabase.instance.client.storage;
  final _auth = Supabase.instance.client.auth;

  String get _uid => _auth.currentUser!.id;

  Future<ProfileModel> loadProfile() async {
    final data = await _db.select().eq('user_id', _uid).single();
    return ProfileModel.fromMap(data);
  }

  Future<void> saveProfile(ProfileModel profile) async {
    await _db.upsert({
      ...profile.toMap(),
      'profile_completed': true,//-------------------------------------fix--------------------------------
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateProfile({
    required String username,
    required String? bio,
    required String? profilePhotoUrl,
    required String? coverPhotoUrl,
  }) async {
    await _db.update({
      'username': username,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,//---------------------------------fix------------------------
      'cover_photo_url': coverPhotoUrl,//-----------------------------fix---------------
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', _uid);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final data = await _db
        .select('user_id')
        .eq('username', username)
        .neq('user_id', _uid)
        .maybeSingle();
    return data == null;
  }

  Future<String> uploadProfilePhoto(File file) => _uploadPhoto(file, 'profile_photos');

  Future<String> uploadCoverPhoto(File file) => _uploadPhoto(file, 'cover_photos');

  Future<String> _uploadPhoto(File file, String bucket) async {
    final ext = file.path.split('.').last;
    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _storage.from(bucket).upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _storage.from(bucket).getPublicUrl(path);
  }
}