import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/player/player_controller.dart';
import '/ui/widgets/image_widget.dart';
import 'animated_play_button.dart';

/// Material 3 Expressive mini-player.
/// Uses MediaQuery for width so it works correctly even when placed inside
/// an unconstrained Positioned (e.g. SlidingUpPanel header).
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PlayerController>();

    return Obx(() {
      final song = ctrl.currentSong.value;
      if (song == null || !ctrl.isPlayerpanelTopVisible.value) {
        return const SizedBox.shrink();
      }
      return _MiniPlayerContent(song: song, ctrl: ctrl);
    });
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final dynamic song;
  final PlayerController ctrl;

  const _MiniPlayerContent({required this.song, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Use MediaQuery width so the widget is self-contained and never relies on
    // the parent providing finite horizontal constraints.
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = screenWidth - 24.0; // 12px padding each side

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ctrl.playerPanelController.open,
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < 0) ctrl.next();
          if ((details.primaryVelocity ?? 0) > 0) ctrl.prev();
        },
        child: SizedBox(
          width: pillWidth,
          height: 68,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Stack(
                  fit: StackFit.expand,         // ← key fix: Stack fills the SizedBox
                  children: [
                    // ── Progress bar ─────────────────────────────────────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      child: GetX<PlayerController>(
                        builder: (c) {
                          final total =
                              c.progressBarStatus.value.total.inMilliseconds;
                          final current =
                              c.progressBarStatus.value.current.inMilliseconds;
                          final pct = total > 0
                              ? (current / total).clamp(0.0, 1.0)
                              : 0.0;
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.08),
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: pct,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // ── Main row ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          // Album art
                          Hero(
                            tag: 'mini_art_${song.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ImageWidget(size: 48, song: song),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title + Artist
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  song.artist ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(
                                () => IconButton(
                                  onPressed: ctrl.toggleFavourite,
                                  icon: Icon(
                                    ctrl.isCurrentSongFav.isTrue
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: ctrl.isCurrentSongFav.isTrue
                                        ? Colors.redAccent
                                        : colorScheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                ),
                              ),
                              AnimatedPlayButton(
                                iconSize: 30,
                                iconColor: colorScheme.primary,
                              ),
                              IconButton(
                                onPressed: ctrl.next,
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  color: colorScheme.onSurface,
                                  size: 28,
                                ),
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
          ),
        ),
      ),
    );
  }
}
