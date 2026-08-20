import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:public_pulse/core/theme/app_colors.dart';

Future<void> showPostLocationMap({
  required String postId,
  required String locationName,
  required double latitude,
  required double longitude,
  required String profileImage,
}) async {
  await Get.dialog(
    _PostLocationMapDialog(
      postId: postId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      profileImage: profileImage,
    ),
    barrierDismissible: true,
    barrierColor: AppColors.overlayBlack50,
  );
}

// ============================================================
// NEARBY POST MODEL
// ============================================================

class _MapPost {
  final String id;
  final double latitude;
  final double longitude;
  final String locationName;
  final String thumbnailUrl;

  const _MapPost({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.thumbnailUrl,
  });

  factory _MapPost.fromJson(Map<String, dynamic> json) {
    return _MapPost(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_path']?.toString() ?? '',
    );
  }
}

// ============================================================
// STATEFUL MAP DIALOG
// ============================================================

class _PostLocationMapDialog extends StatefulWidget {
  final String postId;
  final String locationName;
  final double latitude;
  final double longitude;
  final String profileImage;

  const _PostLocationMapDialog({
    required this.postId,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.profileImage,
  });

  @override
  State<_PostLocationMapDialog> createState() =>
      _PostLocationMapDialogState();
}

class _PostLocationMapDialogState extends State<_PostLocationMapDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final List<_MapPost> _nearbyPosts = [];

  bool _isLoadingNearbyPosts = true;

  @override
  void initState() {
    super.initState();

    _loadNearbyPosts();
  }

  Future<void> _loadNearbyPosts() async {
    try {
      final response = await _supabase.rpc(
        'nearby_posts',
        params: {
          'user_lat': widget.latitude,
          'user_lng': widget.longitude,
          'radius_m': 5000,
        },
      );

      if (!mounted) return;

      final posts = <_MapPost>[];

      for (final item in response as List) {
        final data = Map<String, dynamic>.from(item as Map);

        final id = data['id']?.toString();

        // Don't add the current post again.
        if (id == null || id.isEmpty || id == widget.postId) {
          continue;
        }

        final latitude = data['latitude'];
        final longitude = data['longitude'];

        if (latitude == null || longitude == null) {
          continue;
        }

        posts.add(_MapPost.fromJson(data));
      }

      setState(() {
        _nearbyPosts
          ..clear()
          ..addAll(posts);

        _isLoadingNearbyPosts = false;
      });
    } catch (e) {
      debugPrint('[MAP] Failed to load nearby posts: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingNearbyPosts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 430,
          maxHeight: 500,
        ),
        child: SizedBox(
          height: 460,
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.loginAccentRed.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.loginAccentRed,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        widget.locationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    if (_isLoadingNearbyPosts)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),

                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                color: AppColors.gray100,
              ),

              // ==================================================
              // OPENSTREETMAP
              // ==================================================

              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      widget.latitude,
                      widget.longitude,
                    ),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.publicpulse.app',
                    ),

                    // ==============================================
                    // NEARBY POST THUMBNAILS
                    // ==============================================

                    MarkerLayer(
                      markers: _nearbyPosts.map((post) {
                        return Marker(
                          point: LatLng(
                            post.latitude,
                            post.longitude,
                          ),
                          width: 58,
                          height: 68,
                          alignment: Alignment.bottomCenter,
                          child: _NearbyPostMarker(
                            thumbnailUrl: post.thumbnailUrl,
                          ),
                        );
                      }).toList(),
                    ),

                    // ==============================================
                    // CURRENT POST PROFILE MARKER
                    // Keep this AFTER nearby markers so it stays
                    // visually above them.
                    // ==============================================

                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            widget.latitude,
                            widget.longitude,
                          ),
                          width: 68,
                          height: 78,
                          alignment: Alignment.bottomCenter,
                          child: _ProfileMapMarker(
                            profileImage: widget.profileImage,
                          ),
                        ),
                      ],
                    ),

                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NEARBY POST MARKER
// ============================================================

class _NearbyPostMarker extends StatelessWidget {
  final String thumbnailUrl;

  const _NearbyPostMarker({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 68,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // ======================================================
          // POINTER
          // ======================================================

          Positioned(
            top: 45,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // POST THUMBNAIL
          // ======================================================

          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildThumbnail(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = thumbnailUrl.trim();

    if (url.isEmpty) {
      return const _PostThumbnailFallback();
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, _) {
        return const _PostThumbnailFallback();
      },
      errorWidget: (_, _, _) {
        return const _PostThumbnailFallback();
      },
    );
  }
}

// ============================================================
// POST THUMBNAIL FALLBACK
// ============================================================

class _PostThumbnailFallback extends StatelessWidget {
  const _PostThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray100,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.gray500,
        size: 22,
      ),
    );
  }
}

// ============================================================
// PROFILE AVATAR MAP MARKER
// ============================================================

class _ProfileMapMarker extends StatelessWidget {
  final String profileImage;

  const _ProfileMapMarker({required this.profileImage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 78,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // ======================================================
          // POINTER TIP
          // ======================================================

          Positioned(
            top: 48,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.loginAccentRed,
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
            ),
          ),

          // ======================================================
          // AVATAR CIRCLE
          // ======================================================
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.loginAccentRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(child: _buildProfileImage()),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    final avatarUrl = profileImage.trim();

    if (avatarUrl.isEmpty) {
      return const _AvatarFallback();
    }

    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) {
        return const _AvatarFallback();
      },
      errorWidget: (_, __, ___) {
        return const _AvatarFallback();
      },
    );
  }
}

// ============================================================
// FALLBACK AVATAR
// ============================================================

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.gray100,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.gray500,
        size: 28,
      ),
    );
  }
}
