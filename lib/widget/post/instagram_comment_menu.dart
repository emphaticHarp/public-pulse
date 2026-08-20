import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:public_pulse/core/theme/app_colors.dart';

enum OverlayMode { menu, editing }

/// Holds all the live, mutable state for a single open comment menu:
/// the finger-follow drag offset (already rubber-banded), the "lift"
/// progress that drives the floating-shadow depth effect, the settle-
/// back animation that eases both home on release, which mode the
/// overlay is in (menu vs inline editor), and whether a save is in
/// flight. One instance per open menu, found/put by [tag].
class CommentMenuController extends GetxController
    with GetTickerProviderStateMixin {
  final Rx<Offset> dragOffset = Rx<Offset>(Offset.zero);

  /// 0 = resting flat on the page, 1 = fully "lifted" off it. Drives
  /// the shadow depth and slight scale-up on the lifted card, so it
  /// visibly rises as soon as the long-press registers.
  final Rx<double> liftProgress = 0.0.obs;

  final Rx<OverlayMode> mode = Rx<OverlayMode>(OverlayMode.menu);
  final RxBool isSaving = false.obs;

  Offset? pressStartGlobal;
  AnimationController? _riseController;
  AnimationController? _settleController;

  // How far (in logical px) the card can drift before the rubber band
  // makes further movement feel increasingly "stuck".
  static const double _maxDrag = 30.0;
  static const double _rubberBandConstant = 0.55;

  double _rubberBandAxis(double delta) {
    if (delta == 0) return 0;
    final sign = delta.isNegative ? -1.0 : 1.0;
    final abs = delta.abs();
    // Standard rubber-band easing: asymptotically approaches _maxDrag
    // as the raw delta grows, instead of tracking 1:1.
    return sign *
        (abs * _rubberBandConstant * _maxDrag) /
        (_maxDrag + _rubberBandConstant * abs);
  }

  Offset _applyRubberBand(Offset delta) =>
      Offset(_rubberBandAxis(delta.dx), _rubberBandAxis(delta.dy));

  /// Called right as a new long-press begins, so a reused/stale
  /// controller (shouldn't normally happen, but cheap to guard) starts
  /// from a clean slate.
  void reset() {
    _riseController?.dispose();
    _riseController = null;
    _settleController?.dispose();
    _settleController = null;
    dragOffset.value = Offset.zero;
    liftProgress.value = 0;
    mode.value = OverlayMode.menu;
    isSaving.value = false;
    pressStartGlobal = null;
  }

  /// Animates the card "rising" off the page as soon as the long
  /// press registers — shadow deepens and the card scales up a touch.
  /// Call right after [reset] when a press starts.
  void riseUp() {
    _riseController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    curved.addListener(() {
      liftProgress.value = curved.value;
    });
    _riseController = controller;
    controller.forward().whenCompleteOrCancel(() {
      controller.dispose();
      if (_riseController == controller) _riseController = null;
    });
  }

  void updateDrag(Offset globalPosition) {
    if (pressStartGlobal == null) return;
    final rawDelta = globalPosition - pressStartGlobal!;
    dragOffset.value = _applyRubberBand(rawDelta);
  }

  /// Eases the drag offset AND the lift back to zero once the finger
  /// lifts (or the gesture is cancelled), so the card "settles" back
  /// down onto the page together with its own position, rather than
  /// snapping flat or lagging behind.
  void settleBack() {
    pressStartGlobal = null;
    _riseController?.dispose();
    _riseController = null;

    final startOffset = dragOffset.value;
    final startLift = liftProgress.value;
    if (startOffset == Offset.zero && startLift == 0) return;

    _settleController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    curved.addListener(() {
      dragOffset.value = Offset.lerp(startOffset, Offset.zero, curved.value)!;
      liftProgress.value = lerpDouble(startLift, 0, curved.value)!;
    });
    _settleController = controller;
    controller.forward().whenCompleteOrCancel(() {
      controller.dispose();
      if (_settleController == controller) _settleController = null;
    });
  }

  void enterEditMode() => mode.value = OverlayMode.editing;

  void cancelEdit() => mode.value = OverlayMode.menu;

  @override
  void onClose() {
    _riseController?.dispose();
    _settleController?.dispose();
    super.onClose();
  }
}

/// Owns the text-editing state for the inline editor: seeded
/// [TextEditingController], autofocus, and a reactive [canSave] flag
/// so the Save button can be an `Obx` instead of a `setState`.
class CommentEditController extends GetxController {
  CommentEditController(this.initialText);

  final String initialText;

  late final TextEditingController textController;
  late final FocusNode focusNode;
  final RxBool canSave = false.obs;

  static const int maxLength = 240;

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController(text: initialText)
      ..selection = TextSelection.collapsed(offset: initialText.length);
    focusNode = FocusNode();
    canSave.value = initialText.trim().isNotEmpty;
    textController.addListener(() {
      canSave.value = textController.text.trim().isNotEmpty;
    });
    // Autofocus after the entrance animation/build settles so the
    // keyboard doesn't fight the dialog's own transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void onClose() {
    textController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}

/// Wrap any comment tile with this widget to get an Instagram-style
/// long-press context menu (Edit / Delete) that pops up anchored to
/// the comment itself, with the rest of the screen dimmed.
///
/// As soon as the long-press registers, the lifted comment visibly
/// rises off the page — its shadow deepens and it scales up a touch —
/// and while the finger is still down it subtly follows it (rubber-
/// banded, with a tiny tilt), just like Instagram's own comment long-
/// press. On release both the position and the depth ease back down
/// together. All of that live state is driven by
/// [CommentMenuController]; this widget and the overlay it opens are
/// both plain [StatelessWidget]s.
///
/// Tapping "Edit" no longer fires a callback and closes the menu —
/// the lifted comment itself morphs into an inline editor (text field
/// + Cancel/Save) right where it is, and [onEdit] is only called once
/// the user actually saves. [onEdit] is awaited, so the Save button
/// shows a spinner and the menu stays open until it resolves.
///
/// Usage:
/// ```dart
/// CommentLongPressMenu(
///   isOwner: comment.authorId == currentUserId,
///   commentText: comment.text,
///   authorName: comment.authorName,
///   avatar: CommentAvatar(url: comment.authorAvatarUrl),
///   onEdit: (newText) => _saveEdit(comment, newText),
///   onDelete: () => _deleteComment(comment),
///   child: CommentTile(comment: comment),
/// )
/// ```
///
/// Note on [key]: pass a stable, comment-identifying key (e.g.
/// `ValueKey(comment.id)`) when using this inside a list. It's used
/// to tag the underlying GetX controllers, so a stable key keeps the
/// in-flight drag/edit state correctly attached to its comment across
/// rebuilds; without one a fallback identity is used per build.
class CommentLongPressMenu extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;

  /// Called with the new text only after the user taps Save in the
  /// inline editor. Not called on cancel.
  final Future<void> Function(String) onEdit;

  /// The current comment text, used to seed the inline editor.
  final String commentText;

  /// Optional header shown above the text field while editing, so the
  /// editor still reads like "this comment" rather than a bare text box.
  final String? authorName;
  final Widget? avatar;

  /// Only owners (or moderators) should see Edit/Delete.
  /// If false, long press does nothing.
  final bool isOwner;

  /// Identifies the pressed comment's on-screen position at long-press
  /// time.
  final GlobalKey _anchorKey = GlobalKey();

  /// Tag used to scope this menu's controllers in GetX's dependency
  /// graph, so several comments on screen at once don't share state.
  /// Prefers the widget's own [key] (stable across rebuilds when the
  /// caller supplies one, e.g. `ValueKey(comment.id)`); falls back to
  /// this instance's identity otherwise.
  String get _tag => key?.toString() ?? identityHashCode(this).toString();

  CommentLongPressMenu({
    super.key,
    required this.child,
    required this.commentText,
    required this.onEdit,
    required this.onDelete,
    this.authorName,
    this.avatar,
    this.isOwner = true,
  });

  CommentMenuController _controller() {
    if (Get.isRegistered<CommentMenuController>(tag: _tag)) {
      return Get.find<CommentMenuController>(tag: _tag);
    }
    return Get.put(CommentMenuController(), tag: _tag);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!isOwner) return;

    final renderBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final tag = _tag;
    final controller = _controller();
    controller.reset();
    controller.pressStartGlobal = details.globalPosition;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    HapticFeedback.mediumImpact();

    Get.generalDialog(
      barrierColor: AppColors.overlayBlack55,
      barrierDismissible: true,
      barrierLabel: 'Dismiss comment menu',
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CommentContextMenuOverlay(
          tag: tag,
          // & combines position (top-left) with size into one Rect,
          // so the overlay knows both where AND how big the original
          // tile was — the height half of that is what keeps the
          // lifted card from collapsing/squeezing (see commentRect
          // .height usage below).
          commentRect: position & size,
          commentBuilder: () => child,
          commentText: commentText,
          authorName: authorName,
          avatar: avatar,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, page) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curved, child: page);
      },
    ).then((_) {
      // Overlay is gone (saved, deleted, or dismissed) — tear down
      // this menu's controllers so state doesn't leak between opens.
      if (Get.isRegistered<CommentMenuController>(tag: tag)) {
        Get.delete<CommentMenuController>(tag: tag);
      }
      if (Get.isRegistered<CommentEditController>(tag: tag)) {
        Get.delete<CommentEditController>(tag: tag);
      }
    });

    // Kick off the "rise" the moment the dialog is scheduled, so the
    // shadow starts deepening in step with the entrance animation
    // rather than only once the finger starts moving.
    controller.riseUp();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!isOwner) return;
    _controller().updateDrag(details.globalPosition);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!isOwner) return;
    _controller().settleBack();
  }

  void _handleLongPressCancel() {
    if (!isOwner) return;
    _controller().settleBack();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _anchorKey,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

/// Dimmed barrier content: a "lifted" copy of the comment in its
/// original screen position, plus a small floating quick-action menu
/// anchored above or below it depending on available space.
///
/// While the finger is still down, the lifted card translates and
/// tilts slightly to track it, and its shadow/scale track
/// [CommentMenuController.liftProgress] to sell the sense that it's
/// physically risen off the page — all driven by [Obx] rather than a
/// State field. Tapping Edit swaps the lifted card for an inline
/// editor in place, instead of dismissing the overlay.
class CommentContextMenuOverlay extends StatelessWidget {
  final String tag;
  final Rect commentRect;
  final Widget Function() commentBuilder;
  final String commentText;
  final String? authorName;
  final Widget? avatar;
  final Future<void> Function(String) onEdit;
  final VoidCallback onDelete;

  static const double menuWidth = 200;
  static const double menuHeight = 96;
  static const double gap = 12;

  // Rough estimate used to keep the editor above the keyboard; the
  // actual card sizes itself, this is only used for positioning math.
  static const double _estimatedEditHeight = 148;

  const CommentContextMenuOverlay({
    super.key,
    required this.tag,
    required this.commentRect,
    required this.commentBuilder,
    required this.commentText,
    required this.onEdit,
    required this.onDelete,
    this.authorName,
    this.avatar,
  });

  CommentMenuController get _controller =>
      Get.find<CommentMenuController>(tag: tag);

  Future<void> _handleSave(String newText) async {
    if (newText.trim().isEmpty) return;
    if (!Get.isRegistered<CommentMenuController>(tag: tag)) return;

    final controller = _controller;
    controller.isSaving.value = true;
    try {
      await onEdit(newText.trim());
      Get.back();
    } finally {
      if (Get.isRegistered<CommentMenuController>(tag: tag)) {
        controller.isSaving.value = false;
      }
    }
  }

  void _handleCancelEdit() => _controller.cancelEdit();

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenSize.height - keyboardHeight;

    final spaceBelow = screenSize.height - commentRect.bottom;
    final showMenuBelow = spaceBelow > (menuHeight + gap + 40);

    final menuTop = showMenuBelow
        ? commentRect.bottom + gap
        : (commentRect.top - menuHeight - gap).clamp(
            topPadding + 8,
            screenSize.height,
          );

    double menuLeft = commentRect.left + 16;
    if (menuLeft + menuWidth > screenSize.width - 12) {
      menuLeft = screenSize.width - menuWidth - 12;
    }
    if (menuLeft < 12) menuLeft = 12;

    // Keep the editor's estimated bottom edge above the keyboard.
    double editTop = commentRect.top;
    if (editTop + _estimatedEditHeight > availableHeight) {
      editTop = (availableHeight - _estimatedEditHeight).clamp(
        topPadding + 8,
        screenSize.height,
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: Get.back,
              child: Container(color: AppColors.overlayBlack18),
            ),
          ),
          // Lifted, non-dimmed copy of the comment in its original spot.
          Obx(() {
            final mode = controller.mode.value;
            final rawOffset = controller.dragOffset.value;
            // Only follow the finger while the quick menu is showing;
            // once editing starts the finger has already lifted.
            final followOffset = mode == OverlayMode.menu
                ? rawOffset
                : Offset.zero;
            // A hair of tilt proportional to horizontal drag, like a
            // card being held between two fingers.
            final tilt = (followOffset.dx / 400).clamp(-0.035, 0.035);

            return Positioned(
              left: commentRect.left,
              top: mode == OverlayMode.menu ? commentRect.top : editTop,
              width: commentRect.width,
              // FIX: pin the exact original height while in menu mode
              // so the tile doesn't collapse to its minimum intrinsic
              // height once it's floating outside the list's layout
              // constraints (that collapse is what read as "squeezed").
              // Left null in editing mode so the editor can size
              // itself normally (it's usually taller than the tile).
              height: mode == OverlayMode.menu ? commentRect.height : null,
              child: Transform.translate(
                offset: followOffset,
                child: Transform.rotate(
                  angle: tilt,
                  alignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween(
                              begin: .98,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: mode == OverlayMode.menu
                          ? _LiftedCommentCard(
                              key: const ValueKey("comment"),
                              commentBuilder: commentBuilder,
                              liftProgress: controller.liftProgress,
                              // Also passed straight through here so the
                              // card can force its own height even if a
                              // future caller drops the Positioned height.
                              height: commentRect.height,
                            )
                          : _CommentEditCard(
                              key: const ValueKey("editor"),
                              tag: tag,
                              initialText: commentText,
                              authorName: authorName,
                              avatar: avatar,
                              isSaving: controller.isSaving,
                              onSave: _handleSave,
                              onCancel: _handleCancelEdit,
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            final mode = controller.mode.value;
            return Positioned(
              left: menuLeft,
              top: menuTop,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: mode == OverlayMode.menu ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 120),
                  offset: mode == OverlayMode.menu
                      ? Offset.zero
                      : const Offset(0, -0.15),
                  child: IgnorePointer(
                    ignoring: mode != OverlayMode.menu,
                    child: _CommentQuickMenu(
                      width: menuWidth,
                      onEdit: controller.enterEditMode,
                      onDelete: () {
                        Get.back();
                        onDelete();
                      },
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// The plain (non-editing) lifted card: a white, rounded clip of the
/// comment tile, held at its original [height] so it can't collapse
/// to a squeezed minimum size once it's floating outside the list.
/// Two layers of depth on top of each other:
/// - A one-time "pop-in" scale (.94 -> 1.0) when the card first mounts.
/// - A continuous, [liftProgress]-driven scale + shadow that grows and
///   drops deeper as the card rises off the page, and eases back down
///   again on release — this is what actually reads as "in the air".
class _LiftedCommentCard extends StatelessWidget {
  final Widget Function() commentBuilder;
  final Rx<double> liftProgress;
  final double height;

  const _LiftedCommentCard({
    super.key,
    required this.commentBuilder,
    required this.liftProgress,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentFull,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: .94, end: 1.0),
        builder: (context, popInScale, child) {
          return Transform.scale(scale: popInScale, child: child);
        },
        child: Obx(() {
          final lift = liftProgress.value;

          // A small extra scale on top of the pop-in, so the card
          // visibly grows as it rises — like it's coming toward you.
          final liftScale = 1.0 + (lift * 0.02);

          // Shadow deepens, blurs more, and drops further as lift
          // increases — the core of the "floating above the page"
          // illusion. Interpolated continuously by the same animation
          // that drives the position settle, so both move in lockstep.
          final blur = lerpDouble(20, 44, lift)!;
          final spread = lerpDouble(0, 3, lift)!;
          final dy = lerpDouble(10, 26, lift)!;
          final mainOpacity = lerpDouble(.18, .30, lift)!;

          return Transform.scale(
            scale: liftScale,
            child: Container(
              // Explicit height instead of letting the Row/Column
              // inside commentBuilder() decide — this is the fix for
              // the squeezed look: without it, the tile shrink-wraps
              // to its minimum intrinsic height once outside the list.
              height: height,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  // Long, soft "ambient" shadow — grows with lift.
                  BoxShadow(
                    color: AppColors.overlayBlack50.withValues(
                      alpha: mainOpacity,
                    ),
                    blurRadius: blur,
                    spreadRadius: spread,
                    offset: Offset(0, dy),
                  ),
                  // Tight contact shadow directly under the card, kept
                  // at rest so it never looks like it's floating even
                  // before the lift animation kicks in.
                  BoxShadow(
                    color: AppColors.shadowBlack10,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: commentBuilder(),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The inline editor that replaces the lifted card once "Edit" is
/// tapped: optional author header, an auto-growing text field seeded
/// with the current comment text, and a Cancel / Save row. All text
/// state lives in [CommentEditController]; Save/Cancel enablement is
/// read reactively via [Obx].
class _CommentEditCard extends StatelessWidget {
  final String tag;
  final String initialText;
  final String? authorName;
  final Widget? avatar;
  final RxBool isSaving;
  final Future<void> Function(String) onSave;
  final VoidCallback onCancel;

  const _CommentEditCard({
    super.key,
    required this.tag,
    required this.initialText,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    this.authorName,
    this.avatar,
  });

  CommentEditController _controller() {
    if (Get.isRegistered<CommentEditController>(tag: tag)) {
      return Get.find<CommentEditController>(tag: tag);
    }
    return Get.put(CommentEditController(initialText), tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller();

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 18,
      shadowColor: AppColors.shadowBlack38,
      clipBehavior: Clip.antiAlias,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          final isEnter = event.logicalKey == LogicalKeyboardKey.enter;
          final isEscape = event.logicalKey == LogicalKeyboardKey.escape;
          final metaOrCtrl =
              HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isControlPressed;
          if (isEnter &&
              metaOrCtrl &&
              controller.canSave.value &&
              !isSaving.value) {
            onSave(controller.textController.text);
          } else if (isEscape) {
            onCancel();
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authorName != null || avatar != null) ...[
                Row(
                  children: [
                    if (avatar != null) ...[avatar!, const SizedBox(width: 8)],
                    if (authorName != null)
                      Text(
                        authorName!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              TextField(
                controller: controller.textController,
                focusNode: controller.focusNode,
                maxLines: null,
                minLines: 1,
                maxLength: CommentEditController.maxLength,
                style: const TextStyle(fontSize: 14, height: 1.4),
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.grayshade200.withValues(alpha: .35),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.grayshade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.grayshade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.gray900),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Obx(() {
                final canSave = controller.canSave.value && !isSaving.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving.value ? null : onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gray900.withValues(
                          alpha: .6,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: canSave
                          ? () => onSave(controller.textController.text)
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: canSave
                            ? AppColors.gray900
                            : AppColors.grayshade200,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSaving.value
                          ? const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small floating Edit/Delete card. Slides up 20px while fading
/// in, independent of the lifted card's own scale animation. Rows are
/// left-aligned and full-width so the icon/label sit against the left
/// edge (Instagram-style) instead of being centered in the card.
class _CommentQuickMenu extends StatelessWidget {
  final double width;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommentQuickMenu({
    required this.width,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: Transform.scale(
              scale: 0.96 + (0.04 * value),
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 18,
        shadowColor: AppColors.shadowBlack38,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Stretch each row to the card's full width so the row's
            // own left-anchored content isn't centered by the Column.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MenuRow(
                icon: Icons.edit_outlined,
                label: "Edit",
                color: AppColors.gray900,
                onTap: onEdit,
              ),
              const Divider(
                height: 1,
                thickness: .6,
                color: AppColors.grayshade200,
                indent: 14,
                endIndent: 14,
              ),
              _MenuRow(
                icon: Icons.delete_outline,
                label: "Delete",
                color: AppColors.loginAccentRed,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          // Full-width + start alignment: icon and label hug the left
          // edge instead of being squeezed into the middle of the row.
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
