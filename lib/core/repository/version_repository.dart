import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:public_pulse/model/app_version_model.dart';

class VersionRepository {
  VersionRepository._();

  static final VersionRepository instance = VersionRepository._();

  final _db = Supabase.instance.client.from('app_versions');

  Future<AppVersionModel?> getLatestVersion() async {
    final data = await _db
        .select()
        .eq('platform', 'android')
        .eq('is_active', true)
        .order('build_number', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;

    return AppVersionModel.fromJson(data);
  }
}
