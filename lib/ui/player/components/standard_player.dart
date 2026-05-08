import 'dart:ui';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:widget_marquee/widget_marquee.dart';
import 'package:audio_service/audio_service.dart';
import '/utils/youtube_share_manager.dart';


import '/ui/player/components/animated_play_button.dart';
import '/ui/player/components/backgroud_image.dart';
import '/ui/player/components/lyrics_widget.dart';
import '/ui/player/player_controller.dart';
import 'full_lyrics_page.dart';
import '/ui/widgets/image_widget.dart';
import '/ui/widgets/songinfo_bottom_sheet.dart';
import '/ui/navigator.dart';
import 'package:harmonymusic/generated/l10n.dart';

class StandardPlayer extends StatelessWidget {
  const StandardPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PlayerController>();

    return Obx(() {
      final song = ctrl.currentSong.value;
      if (song == null) return const SizedBox.shrink();
      return _StandardPlayerContent(song: song, ctrl: ctrl);
    });
  }
}

// ── Stateless content widget — receives explicit song & ctrl ─────────────────
class _StandardPlayerContent extends StatelessWidget {
  final MediaItem song;
  final PlayerController ctrl;

  const _StandardPlayerContent({required this.song, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final botPad = MediaQuery.of(context).padding.bottom;
    final artSize = (size.width * 0.82).clamp(240.0, 400.0);

    return Obx(
      () => Opacity(
        opacity: ctrl.panelPosition.value.clamp(0.0, 1.0),
        child: Stack(
          children: [
            // ── Background: blurred album art ──────────────────────────────
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                child: BackgroudImage(
                  key: ValueKey('${song.id}_bg'),
                  cacheHeight: 600,
                ),
              ),
            ),
            // ── Gradient overlay ───────────────────────────────────────────
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: [
                        colorScheme.surface.withValues(alpha: 0.25),
                        colorScheme.surface.withValues(alpha: 0.70),
                        colorScheme.surface.withValues(alpha: 0.97),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────────
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top bar
                          _TopBar(ctrl: ctrl, textTheme: textTheme, colorScheme: colorScheme),
                          const SizedBox(height: 24),

                          // Album art — centered
                          Center(child: _AlbumArt(song: song, artSize: artSize)),
                          const SizedBox(height: 36),

                          // Song info + fav
                          _SongInfo(song: song, ctrl: ctrl, colorScheme: colorScheme, textTheme: textTheme),
                          const SizedBox(height: 28),

                          // Progress bar
                          _ProgressBar(ctrl: ctrl, colorScheme: colorScheme, textTheme: textTheme),
                          const SizedBox(height: 20),

                          // Transport controls
                          _TransportControls(ctrl: ctrl, colorScheme: colorScheme),
                          const SizedBox(height: 36),

                          // Secondary actions row
                          _SecondaryActions(ctrl: ctrl, colorScheme: colorScheme),
                          const SizedBox(height: 32),

                          // Lyrics card
                          _LyricsCard(ctrl: ctrl, colorScheme: colorScheme, textTheme: textTheme),
                          SizedBox(height: botPad + 64),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final PlayerController ctrl;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  const _TopBar({required this.ctrl, required this.textTheme, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Collapse handle
          _GlassIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 28,
            onTap: ctrl.playerPanelController.close,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),

          // Playing-from info
          Expanded(
            child: Column(
              children: [
                Obx(() => Text(
                  ctrl.playinfrom.value.typeString.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                )),
                const SizedBox(height: 2),
                Obx(() => Text(
                  ctrl.playinfrom.value.nameString,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(width: 12),
          // More options
          _GlassIconButton(
            icon: Icons.more_horiz_rounded,
            size: 24,
            onTap: () => _openSheet(context),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  void _openSheet(BuildContext context) {
    if (ctrl.currentSong.value == null) return;
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      isScrollControlled: true,
      context: context,
      builder: (_) => SongInfoBottomSheet(ctrl.currentSong.value!, calledFromPlayer: true),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _GlassIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, size: size, color: colorScheme.onSurface),
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final MediaItem song;
  final double artSize;
  const _AlbumArt({required this.song, required this.artSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: artSize,
      height: artSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 48,
            offset: const Offset(0, 24),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Hero(
          tag: 'player_art_${song.id}',
          child: ImageWidget(
            size: artSize,
            song: song,
            isPlayerArtImage: true,
          ),
        ),
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  final MediaItem song;
  final PlayerController ctrl;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  const _SongInfo({
    required this.song,
    required this.ctrl,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Extract album browseId from extras (stored by MusicServices as 'album' map)
    final albumMap = song.extras?['album'] as Map?;
    final albumId = albumMap?['id'] as String?;
    // Artist ID: extras['artists'] is a list of {id, name} maps
    final artistsList = song.extras?['artists'] as List?;
    final firstArtist = artistsList != null && artistsList.isNotEmpty
        ? artistsList.first as Map?
        : null;
    final artistId = firstArtist?['id'] as String?;
    final artistName = song.artist ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Song title → navigate to album ──────────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: albumId != null && albumId.isNotEmpty
                    ? () {
                        ctrl.playerPanelController.close();
                        Get.toNamed(
                          ScreenNavigationSetup.albumScreen,
                          id: ScreenNavigationSetup.id,
                          arguments: (null, albumId),
                        );
                      }
                    : null,
                child: Marquee(
                  id: 'player_title_${song.id}',
                  child: Text(
                    song.title,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: colorScheme.onSurface,
                      decoration: albumId != null && albumId.isNotEmpty
                          ? TextDecoration.underline
                          : null,
                      decorationColor:
                          colorScheme.onSurface.withValues(alpha: 0.3),
                      decorationThickness: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // ── Artist name → navigate to artist ───────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: artistId != null && artistId.isNotEmpty
                    ? () {
                        ctrl.playerPanelController.close();
                        Get.toNamed(
                          ScreenNavigationSetup.artistScreen,
                          id: ScreenNavigationSetup.id,
                          arguments: [true, artistId],
                        );
                      }
                    : artistName.isNotEmpty
                        ? () {
                            ctrl.playerPanelController.close();
                            Get.toNamed(
                              ScreenNavigationSetup.artistScreen,
                              id: ScreenNavigationSetup.id,
                              arguments: [false, artistName],
                            );
                          }
                        : null,
                child: Text(
                  artistName.isEmpty ? 'Unknown Artist' : artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: artistName.isNotEmpty
                        ? TextDecoration.underline
                        : null,
                    decorationColor: colorScheme.primary.withValues(alpha: 0.4),
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Obx(
          () => _GlassIconButton(
            icon: ctrl.isCurrentSongFav.isTrue
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 22,
            onTap: ctrl.toggleFavourite,
            colorScheme: ctrl.isCurrentSongFav.isTrue
                ? colorScheme.copyWith(
                    onSurface: Colors.redAccent,
                    surfaceContainerHigh:
                        Colors.redAccent.withValues(alpha: 0.15),
                  )
                : colorScheme,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final PlayerController ctrl;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  const _ProgressBar({required this.ctrl, required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return GetX<PlayerController>(
      builder: (c) => ProgressBar(
        progress: c.progressBarStatus.value.current,
        total: c.progressBarStatus.value.total,
        buffered: c.progressBarStatus.value.buffered,
        onSeek: c.seek,
        barHeight: 5,
        baseBarColor: colorScheme.onSurface.withValues(alpha: 0.1),
        bufferedBarColor: colorScheme.onSurface.withValues(alpha: 0.2),
        progressBarColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        thumbRadius: 7,
        thumbGlowRadius: 18,
        thumbGlowColor: colorScheme.primary.withValues(alpha: 0.25),
        timeLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        timeLabelPadding: 12,
      ),
    );
  }
}

class _TransportControls extends StatelessWidget {
  final PlayerController ctrl;
  final ColorScheme colorScheme;
  const _TransportControls({required this.ctrl, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          Obx(() => IconButton(
            onPressed: ctrl.toggleShuffleMode,
            icon: Icon(
              Ionicons.shuffle,
              color: ctrl.isShuffleModeEnabled.isTrue
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          )),

          // Prev
          IconButton(
            onPressed: ctrl.prev,
            icon: Icon(
              Icons.skip_previous_rounded,
              color: colorScheme.onSurface,
              size: 40,
            ),
          ),

          // Play / Pause — prominent M3 filled circle
          _PlayButton(ctrl: ctrl, colorScheme: colorScheme),

          // Next
          IconButton(
            onPressed: ctrl.next,
            icon: Icon(
              Icons.skip_next_rounded,
              color: colorScheme.onSurface,
              size: 40,
            ),
          ),

          // Loop
          Obx(() => IconButton(
            onPressed: ctrl.toggleLoopMode,
            icon: Icon(
              Icons.repeat_rounded,
              color: ctrl.isLoopModeEnabled.isTrue
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          )),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final PlayerController ctrl;
  final ColorScheme colorScheme;
  const _PlayButton({required this.ctrl, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedPlayButton(
        iconSize: 38,
        iconColor: colorScheme.onPrimary,
      ),
    );
  }
}

class _SecondaryActions extends StatelessWidget {
  final PlayerController ctrl;
  final ColorScheme colorScheme;
  const _SecondaryActions({required this.ctrl, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Add to playlist
        _SecondaryButton(
          icon: Icons.playlist_add_rounded,
          label: 'Cola',
          colorScheme: colorScheme,
          onTap: () => ctrl.queuePanelController.open(),
        ),
        // Cast / Share
        _SecondaryButton(
          icon: Icons.share_rounded,
          label: S.current.shareSong,
          colorScheme: colorScheme,
          onTap: () {
            final currentSong = ctrl.currentSong.value;
            if (currentSong != null) {
              YoutubeShareManager.shareSong(
                currentSong.id,
                title: currentSong.title,
                artist: currentSong.artist,
              );
            }
          },
        ),
        // Equalizer
        _SecondaryButton(
          icon: Icons.equalizer_rounded,
          label: S.current.equalizer,
          colorScheme: colorScheme,
          onTap: () {
            ctrl.openEqualizer();
          },
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, color: colorScheme.onSurface, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricsCard extends StatelessWidget {
  final PlayerController ctrl;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  const _LyricsCard({required this.ctrl, required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasLyrics =
          ctrl.lyrics['plainLyrics'] != null && ctrl.lyrics['plainLyrics'] != 'NA';
      final hasSynced = ctrl.lyrics['synced'] != null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.current.lyrics.toUpperCase(),
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (hasLyrics || hasSynced)
                  GestureDetector(
                    onTap: () => Get.to(
                      () => const FullLyricsPage(),
                      transition: Transition.downToUp,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full_rounded,
                              size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Ver todo',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            if (ctrl.isLyricsLoading.isTrue)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator.adaptive(),
                ),
              )
            else if (!hasLyrics && !hasSynced)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  S.current.lyricsNotAvailable,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              const SizedBox(
                height: 200,
                child: LyricsWidget(padding: EdgeInsets.zero),
              ),
          ],
        ),
      );
    });
  }
}
