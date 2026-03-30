import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '/ui/player/player_controller.dart';
import '/ui/widgets/image_widget.dart';
import 'animated_play_button.dart';

/// Compact mini-player bar matching the Spotify-style reference design.
/// Layout: [Album art] [Title + Artist (expand)] [SkipPrev] [Play] [SkipNext]
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PlayerController>();
    final size = MediaQuery.of(context).size;

    return Obx(() {
      if (!ctrl.isPlayerpanelTopVisible.value) return const SizedBox.shrink();

      return AnimatedOpacity(
        opacity: ctrl.playerPaneOpacity.value,
        duration: Duration.zero,
        child: Container(
          height: ctrl.playerPanelMinHeight.value,
          width: size.width,
          padding: const EdgeInsets.only(top: 4, left: 8, right: 8), // Floating margins top
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(30),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Content row ───────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GestureDetector(
                          onTap: ctrl.playerPanelController.open,
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity! < 0) ctrl.next();
                            if (details.primaryVelocity! > 0) ctrl.prev();
                          },
                          onVerticalDragEnd: (details) {
                            // Swipe down to close and save resources
                            if (details.primaryVelocity! > 0) {
                              ctrl.closePlayer();
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              // Album art
                              _AlbumArt(ctrl: ctrl),
                              const SizedBox(width: 12),

                              // Song info — tappable to expand
                              Expanded(
                                child: _SongInfo(ctrl: ctrl),
                              ),

                              // Controls
                              _Controls(ctrl: ctrl),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Thin progress line at bottom of the pill ──────────
                    GetX<PlayerController>(
                      builder: (c) {
                        final total = c.progressBarStatus.value.total;
                        final current = c.progressBarStatus.value.current;
                        final progress = (total.inMilliseconds > 0)
                            ? (current.inMilliseconds /
                                    total.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _AlbumArt extends StatelessWidget {
  final PlayerController ctrl;
  const _AlbumArt({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final song = ctrl.currentSong.value;
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song != null
              ? ImageWidget(size: 46, song: song)
              : Container(
                  color: Colors.white12,
                  child: const Icon(Icons.music_note_rounded,
                      color: Colors.white38, size: 22),
                ),
        ),
      );
    });
  }
}

class _SongInfo extends StatelessWidget {
  final PlayerController ctrl;
  const _SongInfo({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                ctrl.currentSong.value?.title ?? '',
                key: ValueKey(ctrl.currentSong.value?.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ctrl.currentSong.value?.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ));
  }
}

class _Controls extends StatelessWidget {
  final PlayerController ctrl;
  const _Controls({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Heart (Favorite)
        Obx(() => _btn(
              icon: ctrl.isCurrentSongFav.value
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              onTap: ctrl.toggleFavourite,
              color:
                  ctrl.isCurrentSongFav.value ? Colors.white : Colors.white60,
              size: 24,
            )),

        const SizedBox(width: 4),

        // Play / pause — white circle
        Container(
          width: 42,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Center(
            child: AnimatedPlayButton(
              iconSize: 22,
              iconColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    VoidCallback? onTap,
    double size = 26,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
