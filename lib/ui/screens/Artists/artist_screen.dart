import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_service/audio_service.dart';
import '/ui/screens/Artists/artist_screen_controller.dart';
import '/ui/widgets/loader.dart';
import '/ui/player/player_controller.dart';
import '/ui/navigator.dart';
import '/models/media_Item_builder.dart';
import '/ui/widgets/songinfo_bottom_sheet.dart';
import '/models/album.dart';
import '/models/playlist.dart';
import '/ui/widgets/image_widget.dart';
import '/utils/youtube_share_manager.dart';
import 'package:harmonymusic/generated/l10n.dart';
import '/ui/widgets/song_status_badges.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Obx(() {
        if (ctrl.isArtistContentFetced.isFalse) {
          return const Center(child: LoadingIndicator());
        }

        // ── Offline mode ─────────────────────────────────────────────────
        if (ctrl.isOffline.isTrue) {
          return _OfflineArtistView(
            ctrl: ctrl,
            playerController: playerController,
            heroHeight: heroHeight,
          );
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(26),
                              child: const Center(child: LoadingIndicator()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(26),
                              child: Icon(Icons.person_rounded,
                                  size: 80,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(97)),
                            ),
                          )
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(26),
                            child: Icon(Icons.person_rounded,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(97)),
                          ),
                  ),

                  // Gradient fade to dark
                  Container(
                    height: heroHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 0.75, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Theme.of(context).colorScheme.surface.withAlpha(150),
                          Theme.of(context).colorScheme.surface,
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
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withAlpha(120),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 18),
                      ),
                    ),
                  ),

                  // Artist Name and Meta
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist.name,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        ),
                        if (subscribers.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$subscribers ${S.current.subscribers}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(180),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        // Monthly listeners (Metrolist parity)
                        Obx(() {
                          final ml = ctrl.monthlyListeners.value;
                          if (ml == null || ml.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              ml,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(140),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Floating Action Row ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Play Button
                    GestureDetector(
                      onTap: () {
                        final songs = ctrl.artistData['Songs'];
                        if (songs != null) {
                          final allItems = (songs['content'] as List?) ?? [];
                          if (allItems.isNotEmpty) {
                            playerController.playPlayListSong(
                                List.from(allItems), 0);
                          }
                        }
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(100),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            size: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Shuffle Button (Metrolist parity)
                    Obx(() {
                      final sId = ctrl.shuffleId.value;
                      if (sId == null) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          final songs = ctrl.artistData['Songs'];
                          final allItems = songs != null
                              ? (songs['content'] as List?) ?? []
                              : <dynamic>[];
                          if (allItems.isNotEmpty) {
                            final shuffled = List.from(allItems)..shuffle();
                            playerController.playPlayListSong(
                                List.from(shuffled), 0);
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(20),
                          ),
                          child: Icon(
                            Icons.shuffle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    // Follow Button
                    Obx(() => GestureDetector(
                          onTap: () => ctrl.addNremoveFromLibrary(
                              add: !ctrl.isAddedToLibrary.value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(138),
                                  width: 1.5),
                            ),
                            child: Text(
                              ctrl.isAddedToLibrary.isTrue
                                  ? S.current.following.toUpperCase()
                                  : S.current.follow.toUpperCase(),
                              style: TextStyle(
                                color: ctrl.isAddedToLibrary.isTrue
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(180),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )),
                    const Spacer(),
                    // Share
                    GestureDetector(
                      onTap: () => YoutubeShareManager.shareArtist(
                          ctrl.artist_.browseId,
                          artistName: ctrl.artist_.name),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(20),
                        ),
                        child: Icon(Icons.share_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(153),
                            size: 20),
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
                      Text(
                        'About',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(18)),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(180),
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

            // ── Liked Songs section ───────────────────────────────────
            Obx(() {
              if (ctrl.likedSongsOfArtist.isEmpty) {
                return const SliverToBoxAdapter();
              }
              final items = ctrl.likedSongsOfArtist.take(5).toList();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              S.current.favorites,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAllLikedSongs(context),
                              child: Text(
                                S.current.viewAll,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(138),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.asMap().entries.map((entry) {
                        return _TrackRow(
                          index: entry.key + 1,
                          item: entry.value,
                          ctrl: ctrl,
                          playerController: playerController,
                          isFromFavs: true,
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            // ── Popular Tracks header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.current.popularTracks,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAllPopularTracks(context),
                      child: Text(
                        S.current.viewAll,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(138),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Popular Tracks List ───────────────────────────────────────
            Obx(() {
              final songs = ctrl.artistData['Songs'];
              if (songs == null) return const SliverToBoxAdapter();
              final items = (songs['content'] as List?)?.take(5).toList() ?? [];
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TrackRow(
                    index: index + 1,
                    item: items[index],
                    ctrl: ctrl,
                    playerController: playerController,
                    isFromFavs: false,
                    customPlayList: (songs['content'] as List?) ?? [],
                  ),
                  childCount: items.length,
                ),
              );
            }),

            // ── Albums ─────────────────────────────────────────────
            Obx(() {
              final albums = ctrl.artistData['Albums'];
              if (albums == null) return const SliverToBoxAdapter();
              final items =
                  (albums['content'] as List?)?.take(10).toList() ?? [];
              if (items.isEmpty) return const SliverToBoxAdapter();

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              S.current.albums,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(240),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showAllAlbums(context),
                              child: Text(
                                S.current.viewAll,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(138),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
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
            _buildHorizontalSection(context, ctrl, 'Singles'),

            // ── Videos ────────────────────────────────────────────
            _buildHorizontalSection(context, ctrl, 'Videos', isVideo: true),

            // ── Podcasts ─────────────────────────────────────────
            _buildHorizontalSection(context, ctrl, 'Podcasts'),

            // ── Episodes ─────────────────────────────────────────
            Obx(() {
              final episodes = ctrl.artistData['Episodes'];
              if (episodes == null) return const SliverToBoxAdapter();
              final items = (episodes['content'] as List?)?.take(5).toList() ?? [];
              if (items.isEmpty) return const SliverToBoxAdapter();
              
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Episodes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // View all episodes logic
                            },
                            child: Text(
                              S.current.viewAll,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...items.asMap().entries.map((entry) {
                        return _TrackRow(
                          index: entry.key + 1,
                          item: entry.value,
                          ctrl: ctrl,
                          playerController: playerController,
                          customPlayList: (episodes['content'] as List?) ?? [],
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            // ── Playlists ─────────────────────────────────────────
            _buildHorizontalSection(context, ctrl, 'Playlists',
                isPlaylist: true),

            const SliverToBoxAdapter(child: SizedBox(height: 200)),
          ],
        );
      }),
    );
  }

  Widget _buildHorizontalSection(
      BuildContext context, ArtistScreenController ctrl, String sectionKey,
      {bool isVideo = false, bool isPlaylist = false}) {
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
                      sectionKey == 'Singles'
                          ? S.current.singles
                          : sectionKey == 'Videos'
                              ? S.current.videos
                              : sectionKey == 'Playlists'
                                  ? S.current.playlists
                                  : sectionKey == 'Albums'
                                      ? S.current.albums
                                      : sectionKey,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(240),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (sectionKey == 'Singles') {
                          _showAllSingles(context);
                        } else if (sectionKey == 'Videos') {
                          _showAllVideos(context);
                        } else {
                          // Fallback to list screen for other unknown sections
                          Get.toNamed(
                            ScreenNavigationSetup.artistContentListScreen,
                            id: ScreenNavigationSetup.id,
                            arguments: {
                              'browseEndpoint':
                                  Map<String, dynamic>.from(section as Map),
                              'title': (sectionKey == 'Singles'
                                  ? S.current.singles
                                  : sectionKey == 'Videos'
                                      ? S.current.videos
                                      : sectionKey == 'Playlists'
                                          ? S.current.playlists
                                          : sectionKey == 'Albums'
                                              ? S.current.albums
                                              : sectionKey),
                            },
                          );
                        }
                      },
                      child: Text(
                        S.current.viewAll,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(138),
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
                      child: _AlbumCard(
                          item: items[index],
                          isVideo: isVideo,
                          isPlaylist: isPlaylist),
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

  void _showAllLikedSongs(BuildContext context) {
    _showAllContent(
      context,
      title: S.current.favorites,
      initialItems: List.from(ctrl.likedSongsOfArtist),
      isFromFavs: true,
    );
  }

  void _showAllPopularTracks(BuildContext context) {
    final songs = ctrl.artistData['Songs'];
    if (songs == null) return;
    final items = (songs['content'] as List?) ?? [];
    _showAllContent(
      context,
      title: S.current.popularTracks,
      initialItems: items,
      isFromFavs: false,
      category: 'Songs',
    );
  }

  void _showAllAlbums(BuildContext context) {
    final albums = ctrl.artistData['Albums'];
    if (albums == null) return;
    final items = (albums['content'] as List?) ?? [];
    _showAllContent(
      context,
      title: S.current.albums,
      initialItems: items,
      isFromFavs: false,
      category: 'Albums',
    );
  }

  void _showAllSingles(BuildContext context) {
    final singles = ctrl.artistData['Singles'];
    if (singles == null) return;
    final items = (singles['content'] as List?) ?? [];
    _showAllContent(
      context,
      title: S.current.singles,
      initialItems: items,
      isFromFavs: false,
      category: 'Singles',
    );
  }

  void _showAllVideos(BuildContext context) {
    final videos = ctrl.artistData['Videos'];
    if (videos == null) return;
    final items = (videos['content'] as List?) ?? [];
    _showAllContent(
      context,
      title: S.current.videos,
      initialItems: items,
      isFromFavs: false,
      category: 'Videos',
    );
  }

  void _showAllContent(BuildContext context,
      {required String title,
      required List initialItems,
      required bool isFromFavs,
      String? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentModal(
        title: title,
        initialItems: initialItems,
        ctrl: ctrl,
        playerController: playerController,
        isFromFavs: isFromFavs,
        category: category,
      ),
    );
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
  final bool isFromFavs;
  final List? customPlayList;

  const _TrackRow({
    required this.index,
    required this.item,
    required this.ctrl,
    required this.playerController,
    this.isFromFavs = false,
    this.customPlayList,
  });

  void toggleLike(dynamic item) async {
    final song = (item is MediaItem) ? item : MediaItemBuilder.fromJson(item);
    final box = await Hive.openBox("LIBFAV");
    if (box.containsKey(song.id)) {
      await box.delete(song.id);
    } else {
      await box.put(song.id, MediaItemBuilder.toJson(song));
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = (item is MediaItem) ? item : MediaItemBuilder.fromJson(item);
    final title = song.title;
    final artist = song.artist ?? ctrl.artist_.name;
    final songId = song.id;

    return InkWell(
      onTap: () {
        if (customPlayList != null) {
          final playlist = customPlayList!.map((e) {
            if (e is MediaItem) return e;
            return MediaItemBuilder.fromJson(e);
          }).toList();
          if (index - 1 >= 0 && index - 1 < playlist.length) {
            playerController.playPlayListSong(playlist, index - 1);
          }
        } else if (isFromFavs) {
          final playlist = List<MediaItem>.from(ctrl.likedSongsOfArtist);
          if (index - 1 >= 0 && index - 1 < playlist.length) {
            playerController.playPlayListSong(playlist, index - 1);
          }
        } else {
          final songs = ctrl.artistData['Songs'];
          if (songs == null) return;
          final allItems = (songs['content'] as List?) ?? [];
          final playlist = allItems.map((e) {
            if (e is MediaItem) return e;
            return MediaItemBuilder.fromJson(e);
          }).toList();
          if (index - 1 >= 0 && index - 1 < playlist.length) {
            playerController.playPlayListSong(playlist, index - 1);
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Obx(() {
        final isPlaying = playerController.currentSong.value?.id == songId;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isPlaying
                ? Theme.of(context).colorScheme.primary.withAlpha(25)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: isPlaying
                    ? Icon(
                        Icons.equalizer_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      )
                    : Text(
                        '$index',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(97),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 12),
              SongStatusBadges(
                songId: songId,
                child: ImageWidget(
                  song: song,
                  size: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(138),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Like icon
              ValueListenableBuilder(
                valueListenable: Hive.box("LIBFAV").listenable(),
                builder: (context, Box box, _) {
                  final isLiked = box.containsKey(songId);
                  return IconButton(
                    onPressed: () => toggleLike(item),
                    icon: Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isLiked
                          ? Colors.red
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(97),
                      size: 20,
                    ),
                  );
                },
              ),
              // Download icon
              ValueListenableBuilder(
                valueListenable: Hive.box("SongDownloads").listenable(),
                builder: (context, Box box, _) {
                  final isDownloaded = box.containsKey(songId);
                  if (!isDownloaded) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  );
                },
              ),
              // More icon
              IconButton(
                onPressed: () {
                  final song = (item is MediaItem)
                      ? item
                      : MediaItemBuilder.fromJson(item);
                  Get.bottomSheet(
                    SongInfoBottomSheet(song),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(97),
                  size: 20,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Content Modal for "Show All"
// ─────────────────────────────────────────────────────────────────────────────
class _ContentModal extends StatefulWidget {
  final String title;
  final List initialItems;
  final ArtistScreenController ctrl;
  final PlayerController playerController;
  final bool isFromFavs;
  final String? category;

  const _ContentModal({
    required this.title,
    required this.initialItems,
    required this.ctrl,
    required this.playerController,
    required this.isFromFavs,
    this.category,
  });

  @override
  State<_ContentModal> createState() => _ContentModalState();
}

class _ContentModalState extends State<_ContentModal> {
  final TextEditingController _searchController = TextEditingController();
  List _allItems = [];
  List _filteredItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _allItems = widget.initialItems;
    _filteredItems = widget.initialItems;

    // If not from favs and we have a category, try to fetch full content
    if (!widget.isFromFavs && widget.category != null) {
      _fetchFullContent();
    }
  }

  Future<void> _fetchFullContent() async {
    setState(() => _isLoading = true);
    try {
      final fullList = await widget.ctrl.fetchCategoryContent(widget.category!);
      if (fullList.isNotEmpty) {
        setState(() {
          _allItems = fullList;
          _filter(_searchController.text);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((item) {
          final title = (item is MediaItem)
              ? item.title
              : (item is Album)
                  ? item.title
                  : (item['title'] as String? ?? '');
          return title.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(32),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title & Loading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: S.current.search,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.onSurface.withAlpha(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: _filteredItems.isEmpty && !_isLoading
                ? const Center(child: Text("No se encontraron resultados"))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      if (item is MediaItem ||
                          (item is Map && item.containsKey('videoId'))) {
                        return _TrackRow(
                          index: index + 1,
                          item: item,
                          ctrl: widget.ctrl,
                          playerController: widget.playerController,
                          isFromFavs: widget.isFromFavs,
                          customPlayList: _filteredItems,
                        );
                      } else {
                        // For Albums/Videos in the modal
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImageWidget(
                              song: (item is MediaItem) ? item : null,
                              album: (item is Album) ? item : null,
                              size: 50,
                            ),
                          ),
                          title: Text(
                            (item is Album)
                                ? item.title
                                : (item['title'] as String? ?? ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            (item is Album)
                                ? (item.year ?? '')
                                : (item['year'] as String? ?? ''),
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(138),
                                fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (item is Map && item.containsKey('videoId')) {
                              // It's a video
                              widget.playerController.startRadio(null,
                                  playlistid: 'RDAMVM${item['videoId']}');
                            } else {
                              final browseId = (item is Album)
                                  ? item.browseId
                                  : (item['browseId'] as String? ?? '');
                              Get.toNamed(
                                ScreenNavigationSetup.albumScreen,
                                id: ScreenNavigationSetup.id,
                                arguments: (
                                  item is Album ? item : null,
                                  browseId
                                ),
                              );
                            }
                          },
                        );
                      }
                    },
                  ),
          ),
        ],
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
  const _AlbumCard(
      {required this.item, this.isVideo = false, this.isPlaylist = false});

  @override
  Widget build(BuildContext context) {
    final title = item is MediaItem
        ? item.title
        : item is Album
            ? item.title
            : item is Playlist
                ? item.title
                : (item is Map ? item['title'] as String? : null) ?? '';
    final year = item is MediaItem
        ? (item.extras?['year']?.toString() ?? '')
        : item is Album
            ? (item.year ?? '')
            : '';
    final type = item is MediaItem
        ? (item.extras?['description']?.toString() ??
            (isVideo
                ? S.current.video
                : isPlaylist
                    ? S.current.playlist
                    : S.current.album))
        : item is Album
            ? (item.description ??
                (item.isPodcast ? 'Podcast' : S.current.album))
            : item is Playlist
                ? (item.description ?? S.current.playlist)
                : (isVideo
                    ? S.current.video
                    : isPlaylist
                        ? S.current.playlist
                        : S.current.album);

    return InkWell(
      onTap: () {
        if (isVideo) {
          final pCtrl = Get.find<PlayerController>();
          final videoId = item is MediaItem
              ? item.id
              : item is Map
                  ? item['videoId'] as String?
                  : null;
          if (videoId != null) {
            pCtrl.startRadio(null, playlistid: 'RDAMVM$videoId');
          }
        } else if (isPlaylist) {
          final playlist = item is Playlist
              ? item
              : item is Map
                  ? Playlist.fromJson(item)
                  : Playlist(
                      title: title,
                      playlistId: item?.playlistId ?? item?.browseId ?? '',
                      thumbnailUrl: item?.thumbnailUrl ?? '');
          Get.toNamed(
            ScreenNavigationSetup.playlistScreen,
            id: ScreenNavigationSetup.id,
            arguments: [playlist, playlist.playlistId],
          );
        } else {
          final album = item is Album
              ? item
              : item is Map
                  ? Album.fromJson(item)
                  : Album(
                      title: title,
                      browseId: item?.browseId ?? '',
                      artists: item?.artists ?? const [],
                      thumbnailUrl: item?.thumbnailUrl ?? '');
          Get.toNamed(
            ScreenNavigationSetup.albumScreen,
            id: ScreenNavigationSetup.id,
            arguments: (album, album.browseId),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140, // Fixed width for horizontal list items
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(15)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ImageWidget(
                song: (item is MediaItem)
                    ? item
                    : (isVideo ? MediaItemBuilder.fromJson(item) : null),
                album: (item is Album)
                    ? item
                    : (!isVideo && !isPlaylist && item is! MediaItem
                        ? (item is Map
                            ? Album.fromJson(item)
                            : Album(
                                title: item.title ?? '',
                                browseId: item.browseId ?? '',
                                artists: item.artists ?? const [],
                                thumbnailUrl: item.thumbnailUrl ?? ''))
                        : null),
                playlist: (isPlaylist && item is! MediaItem)
                    ? (item is Map
                        ? Playlist.fromJson(item)
                        : Playlist(
                            title: item.title ?? '',
                            playlistId: item.playlistId ?? item.browseId ?? '',
                            thumbnailUrl: item.thumbnailUrl ?? ''))
                    : null,
                size: 140,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$type${year.isNotEmpty ? ' · $year' : ''}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
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

// ─────────────────────────────────────────────────────────────────────────────
// Offline Artist View
// ─────────────────────────────────────────────────────────────────────────────
class _OfflineArtistView extends StatelessWidget {
  final ArtistScreenController ctrl;
  final PlayerController playerController;
  final double heroHeight;

  const _OfflineArtistView({
    required this.ctrl,
    required this.playerController,
    required this.heroHeight,
  });

  @override
  Widget build(BuildContext context) {
    final artist = ctrl.artist_;
    final thumbnailUrl = artist.thumbnailUrl;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero image ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Stack(
            children: [
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: thumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(26),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(26),
                          child: Icon(Icons.person_rounded,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(97)),
                        ),
                      )
                    : Container(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(26),
                        child: Icon(Icons.person_rounded,
                            size: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(97)),
                      ),
              ),
              // Gradient fade
              Container(
                height: heroHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.75, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withAlpha(150),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
              ),
              // Back button
              SafeArea(
                child: IconButton(
                  onPressed: () =>
                      Get.nestedKey(ScreenNavigationSetup.id)!
                          .currentState!
                          .pop(),
                  icon: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withAlpha(120),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18),
                  ),
                ),
              ),
              // Artist name + offline chip
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Chip(
                      label: Text(
                        'Sin conexión',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      avatar: Icon(Icons.wifi_off_rounded, size: 14),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Downloaded songs header ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              'Canciones descargadas',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        // ── Downloaded songs list ─────────────────────────────────────────
        Obx(() {
          if (ctrl.offlineDownloadedSongs.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(60),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay canciones descargadas de este artista',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(120),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = ctrl.offlineDownloadedSongs[index];
                return _TrackRow(
                  index: index + 1,
                  item: song,
                  ctrl: ctrl,
                  playerController: playerController,
                  isFromFavs: false,
                  customPlayList: ctrl.offlineDownloadedSongs,
                );
              },
              childCount: ctrl.offlineDownloadedSongs.length,
            ),
          );
        }),

        const SliverToBoxAdapter(child: SizedBox(height: 200)),
      ],
    );
  }
}
