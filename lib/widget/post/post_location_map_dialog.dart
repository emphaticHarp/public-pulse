import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:public_pulse/core/theme/app_colors.dart';

Future<void> showPostLocationMap({
  required String locationName,
  required double latitude,
  required double longitude,
  required String profileImage,
}) async {
  await Get.dialog(
    Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 500),
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
                        color: AppColors.loginAccentRed.withValues(alpha: 0.10),
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
                        locationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
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

              const Divider(height: 1, color: AppColors.gray100),

              // ==================================================
              // OPENSTREETMAP
              // ==================================================
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.publicpulse.app',
                    ),

                    // ==================================================
                    // PROFILE AVATAR MARKER
                    // ==================================================
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 68,
                          height: 78,

                          // Marker tip stays on exact location.
                          alignment: Alignment.bottomCenter,

                          child: _ProfileMapMarker(profileImage: profileImage),
                        ),
                      ],
                    ),

                    // ==================================================
                    // OSM ATTRIBUTION
                    // ==================================================
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: true,
    barrierColor: AppColors.overlayBlack50,
  );
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
