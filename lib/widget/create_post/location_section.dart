import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_pulse/controller/create_post_controller.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

class CreatePostLocationSection extends StatelessWidget {
  const CreatePostLocationSection({super.key, required this.controller});

  final CreatePostController controller;

  void _showLocationPicker() {
    debugPrint('📍 [CreatePostLocationSection] Opening location picker');

    controller.resetLocationPicker();

    Get.bottomSheet(
      _LocationPickerSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 28),
      child: Obx(() {
        final fullLocation = controller.location.value.trim();

        final displayLocation = controller.locationDisplayName.value.trim();

        final hasLocation = fullLocation.isNotEmpty;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _showLocationPicker,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ==============================================
                  // LOCATION ICON
                  // ==============================================

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.createPostRed600.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.createPostRed600,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ==============================================
                  // LOCATION TEXT
                  // ==============================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation ? 'Location' : 'Add Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasLocation
                                ? AppColors.gray500
                                : AppColors.createPostRed600,
                          ),
                        ),

                        if (hasLocation) ...[
                          const SizedBox(height: 4),

                          Text(
                            displayLocation.isNotEmpty
                                ? displayLocation
                                : fullLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.createPostGray800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ==============================================
                  // REMOVE / OPEN BUTTON
                  // ==============================================
                  if (hasLocation)
                    GestureDetector(
                      onTap: () {
                        controller.clearLocation();
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.gray500,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.gray400,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ===========================================================================
// LOCATION PICKER BOTTOM SHEET
// ===========================================================================

class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet({required this.controller});

  final CreatePostController controller;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: screenHeight * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ================================================
              // DRAG HANDLE
              // ================================================

              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.createPostGray300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // ================================================
              // HEADER
              // ================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.createPostRed600,
                      size: 23,
                    ),

                    const SizedBox(width: 9),

                    const Expanded(
                      child: Text(
                        'Add Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.createPostGray800,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.gray100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ================================================
              // SEARCH BAR
              // ================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller.locationSearchController,

                  onChanged: controller.onLocationSearchChanged,

                  textInputAction: TextInputAction.search,

                  decoration: InputDecoration(
                    hintText: 'Search city, place or address...',

                    hintStyle: const TextStyle(
                      color: AppColors.gray400,
                      fontSize: 14,
                    ),

                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.gray500,
                    ),

                    suffixIcon: Obx(() {
                      if (controller.isSearchingLocation.value) {
                        return const Padding(
                          padding: EdgeInsets.all(15),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.createPostRed600,
                            ),
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    }),

                    filled: true,
                    fillColor: AppColors.gray50,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.gray100),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.createPostRed600,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ================================================
              // CURRENT LOCATION
              // ================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final loading = controller.isGettingCurrentLocation.value;

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),

                      onTap: loading ? null : controller.useCurrentLocation,

                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.createPostRed600.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: AppColors.createPostRed600,
                                size: 20,
                              ),
                            ),

                            const SizedBox(width: 13),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Current Location',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.createPostGray800,
                                    ),
                                  ),

                                  SizedBox(height: 2),

                                  Text(
                                    'Use your phone GPS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (loading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.createPostRed600,
                                ),
                              )
                            else
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.gray400,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 12, color: AppColors.gray100),
              ),

              // ================================================
              // SEARCH RESULTS
              // ================================================
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.locationSearchController,

                  builder: (context, textValue, child) {
                    final query = textValue.text.trim();

                    return Obx(() {
                      final results = controller.locationSuggestions;

                      final searching = controller.isSearchingLocation.value;

                      // ----------------------------------------
                      // EMPTY
                      // ----------------------------------------

                      if (query.length < 2) {
                        return const _LocationEmptyState();
                      }

                      // ----------------------------------------
                      // SEARCHING
                      // ----------------------------------------

                      if (searching && results.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.createPostRed600,
                              ),

                              SizedBox(height: 14),

                              Text(
                                'Searching locations...',
                                style: TextStyle(
                                  color: AppColors.gray500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // ----------------------------------------
                      // NO RESULTS
                      // ----------------------------------------

                      if (!searching && results.isEmpty) {
                        return const _NoLocationResult();
                      }

                      // ----------------------------------------
                      // RESULT LIST
                      // ----------------------------------------

                      return ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,

                        padding: const EdgeInsets.only(bottom: 20),

                        itemCount: results.length,

                        separatorBuilder: (context, index) {
                          return const Divider(
                            height: 1,
                            indent: 72,
                            color: AppColors.gray100,
                          );
                        },

                        itemBuilder: (context, index) {
                          final item = results[index];

                          return InkWell(
                            onTap: () {
                              FocusScope.of(context).unfocus();

                              controller.selectLocation(item);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: const BoxDecoration(
                                      color: AppColors.gray100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.createPostRed600,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 13),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.createPostGray800,
                                          ),
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          item.formattedAddress,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.4,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: AppColors.gray400,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    });
                  },
                ),
              ),

              // ================================================
              // ATTRIBUTION
              // ================================================
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Location search powered by Geoapify',
                  style: TextStyle(fontSize: 10, color: AppColors.gray400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// EMPTY SEARCH STATE
// ===========================================================================

class _LocationEmptyState extends StatelessWidget {
  const _LocationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.createPostRed600.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_searching,
                size: 32,
                color: AppColors.createPostRed600,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Find a location',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.createPostGray800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Search for a city, area or place to add to your post.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// NO RESULT STATE
// ===========================================================================

class _NoLocationResult extends StatelessWidget {
  const _NoLocationResult();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 48,
              color: AppColors.gray400,
            ),

            SizedBox(height: 12),

            Text(
              'No locations found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.createPostGray800,
              ),
            ),

            SizedBox(height: 5),

            Text(
              'Try searching with another city, area or place name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
