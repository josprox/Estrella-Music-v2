import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/ui/player/components/animated_play_button.dart';
import '/ui/player/components/backgroud_image.dart';
import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import '/models/album.dart';
import '/ui/navigator.dart';
import '/ui/utils/theme_controller.dart';
import 'full_lyrics_page.dart';
import '/ui/widgets/image_widget.dart';
import '/ui/widgets/songinfo_bottom_sheet.dart';
import 'package:harmonymusic/generated/l10n.dart';

class StandardPlayer extends StatelessWidget {
  const StandardPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ctrl = Get.find<PlayerController>();

    final botPad = MediaQuery.of(context).padding.bottom;

    // Album art size — square, max 85% of width
    final artSize = (size.width * 0.85).clamp(220.0, 380.0);

    return Obx(() => Opacity(
          opacity: ctrl.panelPosition.value.clamp(0.0, 1.0),
          child: Stack(
            children: [
        // ── Layer 1: Blurred album background ────────────────────────────────
        BackgroudImage(
          key: Key('${ctrl.currentSong.value?.id}_bg'),
          cacheHeight: 300,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),

        // ── Layer 3: Scrollable player content ───────────────────────────────
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Top bar ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          // Minimize
                          IconButton(
                            onPressed: ctrl.playerPanelController.close,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          // Playing from
                          Expanded(
                            child: Obx(() => Column(
                                  children: [
                                    Text(
                                      ctrl.playinfrom.value.typeString
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '"${ctrl.playinfrom.value.nameString}"',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )),
                          ),
                          // More options
                          IconButton(
                            onPressed: () => _openMoreSheet(context, ctrl),
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Album art ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      child: GestureDetector(
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! < 0) ctrl.next();
                          if (details.primaryVelocity! > 0) ctrl.prev();
                        },
                        child: Obx(
                          () => ctrl.currentSong.value != null
                              ? AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 350),
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(
                                      scale: Tween(begin: 0.92, end: 1.0)
                                          .animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  ),
                                  child: Container(
                                    key: ValueKey(
                                        ctrl.currentSong.value!.id),
                                    width: artSize,
                                    height: artSize,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withAlpha(140),
                                          blurRadius: 40,
                                          offset: const Offset(0, 20),
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      child: ImageWidget(
                                        size: artSize,
                                        song: ctrl.currentSong.value!,
                                        isPlayerArtImage: true,
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: artSize,
                                  height: artSize,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                        Icons.music_note_rounded,
                                        color: Colors.white38,
                                        size: 80),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // ── Song info + heart ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 4),
                      child: Obx(
                        () => Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      final albumId = ctrl.currentSong.value?.extras?['album']?['id'];
                                      if (albumId != null) {
                                        ctrl.playerPanelController.close();
                                        Get.toNamed(
                                          ScreenNavigationSetup.albumScreen,
                                          id: ScreenNavigationSetup.id,
                                          arguments: (null as Album?, albumId as String),
                                        );
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Marquee(
                                      id: '${ctrl.currentSong.value?.id}_title_sp',
                                      delay: const Duration(milliseconds: 800),
                                      duration: const Duration(seconds: 12),
                                      child: Text(
                                        ctrl.currentSong.value?.title ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      final artists = ctrl.currentSong.value?.extras?['artists'];
                                      if (artists != null && (artists as List).isNotEmpty) {
                                        final artistId = artists[0]['id'];
                                        if (artistId != null) {
                                          ctrl.playerPanelController.close();
                                          Get.toNamed(
                                            ScreenNavigationSetup.artistScreen,
                                            id: ScreenNavigationSetup.id,
                                            arguments: [true, artistId],
                                          );
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Marquee(
                                      id: '${ctrl.currentSong.value?.id}_artist_sp',
                                      delay: const Duration(milliseconds: 800),
                                      duration: const Duration(seconds: 12),
                                      child: Text(
                                        ctrl.currentSong.value?.artist ?? '',
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: ctrl.toggleFavourite,
                              child: Obx(
                                () => AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  child: Icon(
                                    ctrl.isCurrentSongFav.isTrue
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    key: ValueKey(
                                        ctrl.isCurrentSongFav.value),
                                    color: ctrl.isCurrentSongFav.isTrue
                                        ? Colors.greenAccent
                                        : Colors.white60,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Progress bar ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: GetX<PlayerController>(
                        builder: (c) => ProgressBar(
                          thumbRadius: 7,
                          thumbGlowRadius: 18,
                          barHeight: 3.5,
                          baseBarColor: Colors.white24,
                          bufferedBarColor: Colors.white38,
                          progressBarColor: Colors.white,
                          thumbColor: Colors.white,
                          timeLabelTextStyle: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          progress: c.progressBarStatus.value.current,
                          total: c.progressBarStatus.value.total,
                          buffered: c.progressBarStatus.value.buffered,
                          onSeek: c.seek,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Transport controls ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Shuffle
                          Obx(() => _iconBtn(
                                icon: Ionicons.shuffle,
                                color: ctrl.isShuffleModeEnabled.value
                                    ? Colors.white
                                    : Colors.white38,
                                size: 22,
                                onTap: ctrl.toggleShuffleMode,
                              )),

                          // Previous
                          _iconBtn(
                            icon: Icons.skip_previous_rounded,
                            color: Colors.white,
                            size: 38,
                            onTap: ctrl.prev,
                          ),

                          // Play / Pause
                          _buildPlayButton(ctrl),

                          // Next
                          Obx(() {
                            final isLast = ctrl.currentQueue.isEmpty ||
                                (!(ctrl.isShuffleModeEnabled.isTrue ||
                                        ctrl.isQueueLoopModeEnabled
                                            .isTrue) &&
                                    ctrl.currentQueue.last.id ==
                                        ctrl.currentSong.value?.id);
                            return _iconBtn(
                              icon: Icons.skip_next_rounded,
                              color:
                                  isLast ? Colors.white30 : Colors.white,
                              size: 38,
                              onTap: isLast ? null : ctrl.next,
                            );
                          }),

                          // Loop
                          Obx(() => _iconBtn(
                                icon: Icons.all_inclusive_rounded,
                                color: ctrl.isLoopModeEnabled.value
                                    ? Colors.white
                                    : Colors.white38,
                                size: 22,
                                onTap: ctrl.toggleLoopMode,
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Modern Spotify-style Lyrics Card ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Obx(() {
                        final themeCtrl = Get.find<ThemeController>();
                        final bgColor = themeCtrl.primaryColor.value;
                        final hasLyrics = ctrl.lyrics['plainLyrics'] != null &&
                                          ctrl.lyrics['plainLyrics'] != 'NA';
                        
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: bgColor.withOpacity(0.9), // Slightly more solid for better readability
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    S.current.lyrics.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  // Expand button
                                  GestureDetector(
                                    onTap: () {
                                      if (hasLyrics || ctrl.lyrics['synced'] != null) {
                                        Get.to(
                                          () => const FullLyricsPage(),
                                          transition: Transition.downToUp,
                                          duration: const Duration(milliseconds: 400),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.open_in_full_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Lyrics content
                              if (ctrl.isLyricsLoading.isTrue)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40),
                                    child: CircularProgressIndicator(
                                        color: Colors.white38,
                                        strokeWidth: 2),
                                  ),
                                )
                              else if (!hasLyrics && ctrl.lyrics['synced'] == null)
                                Text(
                                  S.current.lyricsNotAvailable,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 16),
                                )
                              else
                                const SizedBox(
                                  height: 240,
                                  child: LyricsWidget(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 12),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: botPad + 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ));
}

  void _openMoreSheet(BuildContext context, PlayerController ctrl) {
    if (ctrl.currentSong.value == null) return;
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      context: ctrl.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (_) => SongInfoBottomSheet(
        ctrl.currentSong.value!,
        calledFromPlayer: true,
      ),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  Widget _buildPlayButton(PlayerController ctrl) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Center(
        child: AnimatedPlayButton(
          key: Key('spotifyPlayBtn'),
          iconSize: 32,
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    double size = 26,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
