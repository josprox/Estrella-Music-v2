
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '/ui/screens/Artists/artist_screen_controller.dart';
import '/models/album.dart';
import '/ui/widgets/image_widget.dart';
import '/ui/widgets/loader.dart';
import '/ui/widgets/snackbar.dart';
import '/ui/player/player_controller.dart';
import '/ui/navigator.dart';
import '/models/playlist.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final tag = key.hashCode.toString();
    final ArtistScreenController artistScreenController =
        Get.isRegistered<ArtistScreenController>(tag: tag)
            ? Get.find<ArtistScreenController>(tag: tag)
            : Get.put(ArtistScreenController(), tag: tag);

    // Always use the new Spotify-style screen
    return _SpotifyArtistScreen(
      ctrl: artistScreenController,
      tag: tag,
      playerController: playerController,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spotify-style Artist Screen
// ─────────────────────────────────────────────────────────────────────────────
class _SpotifyArtistScreen extends StatelessWidget {
  final ArtistScreenController ctrl;
  final String tag;
  final PlayerController playerController;

  const _SpotifyArtistScreen({
    required this.ctrl,
    required this.tag,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heroHeight = size.height * 0.45;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: Obx(() {
        if (ctrl.isArtistContentFetced.isFalse) {
          return const Center(child: LoadingIndicator());
        }

        final data = ctrl.artistData;
        final artist = ctrl.artist_;
        final thumbnails = data['thumbnails'] as List?;
        final heroUrl = thumbnails != null && thumbnails.isNotEmpty
            ? thumbnails.last['url'] as String
            : '';
        final description = data['description'] as String?;
        final subscribers = artist.subscribers ?? '';

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero image + gradient overlay ─────────────────────────────
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Hero image
                  SizedBox(
                    height: heroHeight,
                    width: double.infinity,
                    child: heroUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: heroUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.white10,
                              child: const Center(child: LoadingIndicator()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white10,
                              child: const Icon(Icons.person_rounded,
                                  size: 80, color: Colors.white38),
                            ),
                          )
                        : Container(
                            color: Colors.white10,
                            child: const Icon(Icons.person_rounded,
                                size: 80, color: Colors.white38),
                          ),
                  ),

                  // Gradient fade to dark
                  Container(
                    height: heroHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.4, 0.75, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x990D0D14),
                          Color(0xFF0D0D14),
                        ],
                      ),
                    ),
                  ),

                  // Back button
                  SafeArea(
                    child: IconButton(
                      onPressed: () => Get.nestedKey(ScreenNavigationSetup.id)!
                          .currentState!
                          .pop(),
                      icon: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(120),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),

                  // Artist name + sub count at the bottom of hero
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verified badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(50),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.blue.withAlpha(100),
                                  width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    color: Colors.blue, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'VERIFIED ARTIST',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Artist name (large bold)
                          Text(
                            artist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1.05,
                            ),
                          ),
                          if (subscribers.isNotEmpty)
                            Text(
                              subscribers,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Action buttons: PLAY + FOLLOW + Share ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // PLAY button
                    GestureDetector(
                      onTap: () async {
                        final radioId = ctrl.artist_.radioId;
                        if (radioId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            snackbar(context, 'radioNotAvailable'.tr,
                                size: SanckBarSize.BIG),
                          );
                          return;
                        }
                        playerController.startRadio(null,
                            playlistid: radioId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.black, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'PLAY',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // FOLLOW button
                    Obx(() => GestureDetector(
                          onTap: () {
                            final add = ctrl.isAddedToLibrary.isFalse;
                            ctrl.addNremoveFromLibrary(add: add).then((ok) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  snackbar(
                                    context,
                                    ok
                                        ? add
                                            ? 'artistBookmarkAddAlert'.tr
                                            : 'artistBookmarkRemoveAlert'.tr
                                        : 'operationFailed'.tr,
                                    size: SanckBarSize.MEDIUM,
                                  ),
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white54, width: 1.5),
                            ),
                            child: Text(
                              ctrl.isAddedToLibrary.isTrue
                                  ? 'FOLLOWING'
                                  : 'FOLLOW',
                              style: TextStyle(
                                color: ctrl.isAddedToLibrary.isTrue
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )),
                    const Spacer(),
                    // Share
                    GestureDetector(
                      onTap: () => Share.share(
                          'https://music.youtube.com/channel/${ctrl.artist_.browseId}'),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                        ),
                        child: const Icon(Icons.share_rounded,
                            color: Colors.white60, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── About section ─────────────────────────────────────────────
            if (description != null && description.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withAlpha(18)),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            // ── Popular Tracks header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popular Tracks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(
                          ScreenNavigationSetup.artistContentListScreen,
                          id: ScreenNavigationSetup.id,
                          arguments: {
                            'browseEndpoint': ctrl.artistData['Songs'],
                            'title': 'Songs',
                          },
                        );
                      },
                      child: const Text(
                        'Show all',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Popular Tracks list ───────────────────────────────────────
            Obx(() {
              final songs = ctrl.artistData['Songs'];
              if (songs == null) return const SliverToBoxAdapter();
              final items = (songs['content'] as List?)?.take(5).toList() ?? [];
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _TrackRow(
                    index: i + 1,
                    item: items[i],
                    ctrl: ctrl,
                    playerController: playerController,
                  ),
                  childCount: items.length,
                ),
              );
            }),

            // ── Latest Release ────────────────────────────────────────────
            Obx(() {
              final albums = ctrl.artistData['Albums'];
              if (albums == null) return const SliverToBoxAdapter();
              final content = albums['content'] as List?;
              if (content == null || content.isEmpty) {
                return const SliverToBoxAdapter();
              }
              final latest = content.first;
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latest Release',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LatestReleaseCard(item: latest),
                    ],
                  ),
                ),
              );
            }),

            // ── Albums ────────────────────────────────────────────
            Obx(() {
              final albums = ctrl.artistData['Albums'];
              if (albums == null) return const SliverToBoxAdapter();
              final content = albums['content'] as List?;
              if (content == null || content.isEmpty) {
                return const SliverToBoxAdapter();
              }
              final items = content.take(10).toList();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Albums',
                              style: TextStyle(
                                color: Colors.white.withAlpha(240),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.toNamed(
                                  ScreenNavigationSetup.artistContentListScreen,
                                  id: ScreenNavigationSetup.id,
                                  arguments: {
                                    'browseEndpoint': albums,
                                    'title': 'Albums',
                                  },
                                );
                              },
                              child: const Text(
                                'Show all',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220, // Fixed height for album cards
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _AlbumCard(item: items[index]),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ── Singles ────────────────────────────────────────────
            _buildHorizontalSection(ctrl, 'Singles'),
            
            // ── Videos ────────────────────────────────────────────
            _buildHorizontalSection(ctrl, 'Videos', isVideo: true),
            
            // ── Playlists ─────────────────────────────────────────
            _buildHorizontalSection(ctrl, 'Playlists', isPlaylist: true),

            const SliverToBoxAdapter(child: SizedBox(height: 200)),
          ],
        );
      }),
    );
  }
  Widget _buildHorizontalSection(ArtistScreenController ctrl, String sectionKey, {bool isVideo = false, bool isPlaylist = false}) {
    return Obx(() {
      final section = ctrl.artistData[sectionKey];
      if (section == null) return const SliverToBoxAdapter();
      final content = section['content'] as List?;
      if (content == null || content.isEmpty) {
        return const SliverToBoxAdapter();
      }
      final items = content.take(15).toList();
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sectionKey,
                      style: TextStyle(
                        color: Colors.white.withAlpha(240),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(
                          ScreenNavigationSetup.artistContentListScreen,
                          id: ScreenNavigationSetup.id,
                          arguments: {
                            'browseEndpoint': section,
                            'title': sectionKey,
                          },
                        );
                      },
                      child: const Text(
                        'Show all',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220, 
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _AlbumCard(item: items[index], isVideo: isVideo, isPlaylist: isPlaylist),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Track row widget
// ─────────────────────────────────────────────────────────────────────────────
class _TrackRow extends StatelessWidget {
  final int index;
  final dynamic item;
  final ArtistScreenController ctrl;
  final PlayerController playerController;

  const _TrackRow({
    required this.index,
    required this.item,
    required this.ctrl,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    // MediaItem stores artist info in .artist (joined String) and
    // the raw list in .extras['artists']. There is NO .artists getter.
    final title = item?.title ?? '';
    final artist = (() {
      // Prefer the pre-joined string from MediaItem.artist
      if (item?.artist != null && (item!.artist as String).isNotEmpty) {
        return item!.artist as String;
      }
      // Fallback: build from extras['artists'] list
      final list = item?.extras?['artists'];
      if (list is List && list.isNotEmpty) {
        return list.map((a) => a['name'] ?? '').join(', ');
      }
      return ctrl.artist_.name;
    })();
    final plays = (item?.extras?['views'] ?? '') as String;
    final thumbUrl = (item?.artUri ?? '').toString();

    return InkWell(
      onTap: () {
        final songs = ctrl.artistData['Songs'];
        if (songs == null) return;
        final allItems = (songs['content'] as List?) ?? [];
        playerController.playPlayListSong(List.from(allItems), index - 1);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Index number
            SizedBox(
              width: 24,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: thumbUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.white12,
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white38, size: 22),
                    ),
            ),
            const SizedBox(width: 12),
            // Title + artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Play count
            if (plays.isNotEmpty)
              Text(
                plays,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Latest release card — restored for detailed single highlight
// ─────────────────────────────────────────────────────────────────────────────
class _LatestReleaseCard extends StatelessWidget {
  final dynamic item;
  const _LatestReleaseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item?.title ?? '';
    final year = item?.year ?? '';
    final type = item?.description ?? 'Album';
    final thumbUrl = (item?.thumbnailUrl as String?) ?? '';

    return InkWell(
      onTap: () => Get.toNamed(
        ScreenNavigationSetup.albumScreen,
        id: ScreenNavigationSetup.id,
        arguments: (null as Album?, item.browseId as String),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: thumbUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.white12,
                      child: const Icon(Icons.album_rounded,
                          color: Colors.white38, size: 36),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$type · $year',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withAlpha(30)),
                    ),
                    child: const Text(
                      'Listen Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────────────────────
// Album card
// ─────────────────────────────────────────────────────────────────────────────
class _AlbumCard extends StatelessWidget {
  final dynamic item;
  final bool isVideo;
  final bool isPlaylist;
  const _AlbumCard({required this.item, this.isVideo = false, this.isPlaylist = false});

  @override
  Widget build(BuildContext context) {
    final title = item?.title ?? '';
    final year = (item is MediaItem) ? (item.extras?['year'] ?? '') : (item?.year ?? '');
    final type = (item is MediaItem)
        ? (item.extras?['description'] ?? (isVideo ? 'Video' : isPlaylist ? 'Playlist' : 'Album'))
        : (item?.description ?? (isVideo ? 'Video' : isPlaylist ? 'Playlist' : 'Album'));
    final thumbUrl = isVideo ? (item?.artUri ?? '').toString() : (item?.thumbnailUrl as String?) ?? '';

    return InkWell(
      onTap: () {
        if (isVideo) {
          final pCtrl = Get.find<PlayerController>();
          pCtrl.startRadio(null, playlistid: 'RDAMVM${item.videoId}');
        } else if (isPlaylist) {
          Get.toNamed(
            ScreenNavigationSetup.playlistScreen,
            id: ScreenNavigationSetup.id,
            arguments: (null as Playlist?, item.browseId as String, null, null),
          );
        } else {
          Get.toNamed(
            ScreenNavigationSetup.albumScreen,
            id: ScreenNavigationSetup.id,
            arguments: (null as Album?, item.browseId as String),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140, // Fixed width for horizontal list items
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: thumbUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.white12,
                        child: const Icon(Icons.album_rounded,
                            color: Colors.white38, size: 48),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$type${year.isNotEmpty ? ' · $year' : ''}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AboutArtist — kept for backward compatibility (used in ArtistScreenBN)
// ─────────────────────────────────────────────────────────────────────────────
class AboutArtist extends StatelessWidget {
  const AboutArtist({
    super.key,
    required this.artistScreenController,
    this.padding = const EdgeInsets.only(bottom: 90, top: 70),
  });
  final EdgeInsetsGeometry padding;
  final ArtistScreenController artistScreenController;

  @override
  Widget build(BuildContext context) {
    final artistData = artistScreenController.artistData;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          padding: padding,
          child: artistScreenController.isArtistContentFetced.value
              ? Column(
                  children: [
                    ImageWidget(
                      size: 200,
                      artist: artistScreenController.artist_,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      artistScreenController.artist_.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (artistData['description'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '"${artistData["description"]}"',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
