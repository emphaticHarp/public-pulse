String supabaseStorageCacheKey(String url) {
  if (url.isEmpty) {
    return url;
  }

  try {
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;

    // Handles:
    //
    // /storage/v1/object/public/<bucket>/<path>
    // /storage/v1/object/sign/<bucket>/<path>
    // /storage/v1/object/authenticated/<bucket>/<path>
    //
    // We deliberately ignore "public/sign/authenticated"
    // so the same physical Supabase object gets the same cache key.

    for (final mode in ['public', 'sign', 'authenticated']) {
      final index = segments.indexOf(mode);

      if (index != -1 && index + 1 < segments.length) {
        return segments.sublist(index + 1).join('/');
      }
    }

    // Fallback.
    return uri.path;
  } catch (_) {
    return url;
  }
}
