import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BunnyUploadService {
  BunnyUploadService._();

  static final BunnyUploadService instance = BunnyUploadService._();

  Future<String?> uploadMedia(File file, String folder) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return null;
    }
    final supabaseUrl = dotenv.env['SUPABASE_URL'];

    if (supabaseUrl == null || supabaseUrl.trim().isEmpty) {
      return null;
    }

    final baseUrl = supabaseUrl.replaceAll(RegExp(r'/+$'), '');

    final uri = Uri.parse('$baseUrl/functions/v1/upload-media');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${session.accessToken}'
      ..fields['folder'] = folder
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(
            lookupMimeType(file.path) ?? 'application/octet-stream',
          ),
        ),
      );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      return data['url'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Resolves either a legacy Supabase relative path or a full Bunny CDN URL
  /// into a displayable URL.
  String resolveMediaUrl(String storagePath, {required String bucket}) {
    if (storagePath.startsWith('http')) {
      return storagePath; // already a full Bunny CDN URL
    }
    return Supabase.instance.client.storage
        .from(bucket)
        .getPublicUrl(storagePath);
  }
}
