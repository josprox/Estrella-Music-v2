import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/custom_marquee.dart';
import '/utils/youtube_share_manager.dart';

import '/models/playling_from.dart';
import '/ui/widgets/playlist_album_scroll_behaviour.dart';
import '../../widgets/playlist_cover_widget.dart';
import '../../../services/downloader.dart';
import '../../navigator.dart';
import '../../player/player_controller.dart';
import '../../widgets/create_playlist_dialog.dart';
import '../../widgets/loader.dart';
import '../../widgets/playlist_export_dialog.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/song_list_tile.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/sort_widget.dart';
import '../Library/library_controller.dart';
import 'playlist_screen_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_service.dart';
import 'package:harmonymusic/generated/l10n.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tag = key.hashCode.toString();
    final playlistController =
        (Get.isRegistered<PlaylistScreenController>(tag: tag))
            ? Get.find<PlaylistScreenController>(tag: tag)
            : Get.put(PlaylistScreenController(), tag: tag);
    final size = MediaQuery.of(context).size;
    final playerController = Get.find<PlayerController>();
    final landscape = size.width > size.height;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          final scrollOffset = scrollInfo.metrics.pixels;

          if (landscape) {
            playlistController.scrollOffset.value = 0;
          } else {
            playlistController.scrollOffset.value = scrollOffset;
          }
          if (scrollOffset > 270 || (landscape && scrollOffset > 215)) {
            playlistController.appBarTitleVisible.value = true;
          } else {
            playlistController.appBarTitleVisible.value = false;
          }
          return true;
        },
        child: Stack(
          children: [
            Obx(
              () => playlistController.isContentFetched.isTrue
                  ? Positioned(
                      top: 0,
                      right: landscape ? 0 : null,
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).canvasColor,
                              spreadRadius: 200,
                              blurRadius: 100,
                              offset: Offset(-size.height, 0),
                            ),
                            BoxShadow(
                              color: Theme.of(context).canvasColor,
                              spreadRadius: 200,
                              blurRadius: 100,
                              offset: Offset(
                                  0,
                                  landscape
                                      ? size.height
                                      : size.width + 80),
                            )
                          ],
                        ),
                        child: PlaylistCoverWidget(
                          size: landscape ? size.height : size.width,
                          playlist: playlistController.playlist.value,
                        ),
                      ))
                  : SizedBox(
                      height: size.width,
                      width: size.width,
                    ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      right: 10),
                  height: 80,
                  child: Center(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            tooltip: S.current.back,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.arrow_back_ios)),
                        ),
                        Expanded(
                          child: Obx(
                            () => Marquee(
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(seconds: 5),
                              id: "${playlistController.playlist.value.title.hashCode.toString()}_appbar",
                              child: Text(
                                playlistController.appBarTitleVisible.isTrue
                                    ? playlistController.playlist.value.title
                                    : "",
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
                        if (playlistController.isDefaultPlaylist.isFalse)
                          SizedBox(
                            width: 50,
                            child: IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    constraints:
                                        const BoxConstraints(maxWidth: 500),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(15.0)),
                                    ),
                                    context: Get.find<PlayerController>()
                                        .homeScaffoldkey
                                        .currentState!
                                        .context,
                                    barrierColor:
                                        Colors.transparent.withAlpha(100),
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setStateSheet) {
                                        final playlist = playlistController.playlist.value;
                                        final isAuthenticated = Get.find<AuthService>().isAuthenticated.value;
                                        final myUserId = Get.find<AuthService>().userProfile.value?['id'];
                                        final isOwner = playlist.ownerId == null || playlist.ownerId == myUserId;

                                        return SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ListTile(
                                                  leading: const Icon(Icons.edit),
                                                  title: Text(S.current.renamePlaylist),
                                                  onTap: () {
                                                    Navigator.of(context).pop();
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          CreateNRenamePlaylistPopup(
                                                              renamePlaylist: true,
                                                              playlist: playlistController.playlist.value),
                                                    );
                                                  },
                                                ),
                                                if (isAuthenticated && isOwner) ...[
                                                  SwitchListTile(
                                                    secondary: Icon(playlist.isPublic ? Icons.public : Icons.public_off),
                                                    title: const Text("Playlist Pública"),
                                                    subtitle: const Text("Cualquiera puede escuchar esta playlist"),
                                                    value: playlist.isPublic,
                                                    onChanged: (val) {
                                                      setStateSheet(() {
                                                        playlistController.togglePlaylistPrivacy(val);
                                                      });
                                                    },
                                                  ),
                                                  SwitchListTile(
                                                    secondary: Icon(playlist.isCollaborative ? Icons.people : Icons.people_outline),
                                                    title: const Text("Playlist Colaborativa"),
                                                    subtitle: const Text("Amigos autorizados pueden editarla"),
                                                    value: playlist.isCollaborative,
                                                    onChanged: (val) {
                                                      setStateSheet(() {
                                                        playlistController.togglePlaylistCollaboration(val);
                                                      });
                                                    },
                                                  ),
                                                  if (playlist.isCollaborative)
                                                    ListTile(
                                                      leading: const Icon(Icons.person_add),
                                                      title: const Text("Gestionar Colaboradores"),
                                                      subtitle: Text("${playlist.collaborators.length} colaboradores"),
                                                      onTap: () {
                                                        Navigator.of(context).pop();
                                                        _showCollaboratorsDialog(context, playlistController);
                                                      },
                                                    ),
                                                ],
                                                ListTile(
                                                  leading: const Icon(Icons.delete, color: Colors.red),
                                                  title: Text(S.current.removePlaylist, style: const TextStyle(color: Colors.red)),
                                                  onTap: () {
                                                    Navigator.of(context).pop();
                                                    playlistController
                                                        .addNremoveFromLibrary(
                                                            playlistController
                                                                .playlist.value,
                                                            add: false)
                                                        .then((value) {
                                                      Get.nestedKey(
                                                              ScreenNavigationSetup
                                                                  .id)!
                                                          .currentState!
                                                          .pop();
                                                      ScaffoldMessenger.of(
                                                              Get.context!)
                                                          .showSnackBar(snackbar(
                                                              Get.context!,
                                                              value
                                                                  ? S.current.playlistRemovedAlert
                                                                  : S.current.operationFailed,
                                                              size: SanckBarSize
                                                                  .MEDIUM));
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.more_vert)),
                          )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 800,
                      ),
                      child: Obx(() {
                        Widget buildItem(BuildContext context, int index) {
                          if (index == 0) {
                            return Padding(
                              key: const ValueKey('header_0'),
                              padding: const EdgeInsets.only(left: 15.0),
                                  child: SizedBox(
                                    height: 40,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          // Bookmark button
                                          Obx(() => (playlistController.playlist
                                                      .value.isPipedPlaylist ||
                                                  !playlistController.playlist
                                                      .value.isCloudPlaylist)
                                              ? const SizedBox.shrink()
                                              : IconButton(
                                                  tooltip: playlistController
                                                          .isAddedToLibrary
                                                          .isFalse
                                                      ? S.current.addToLibrary
                                                      : S.current.removeFromLibrary,
                                                  splashRadius: 10,
                                                  onPressed: () {
                                                    final add = playlistController
                                                        .isAddedToLibrary.isFalse;
                                                    playlistController
                                                        .addNremoveFromLibrary(
                                                            playlistController
                                                                .playlist.value,
                                                            add: add)
                                                        .then((value) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                      
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(snackbar(
                                                              context,
                                                              value
                                                                  ? add
                                                                      ? S.current.playlistBookmarkAddAlert
                                                                      : S.current.playlistBookmarkRemoveAlert
                                                                  : S.current.operationFailed,
                                                              size: SanckBarSize
                                                                  .MEDIUM));
                                                    });
                                                  },
                                                  icon: Icon(playlistController
                                                          .isAddedToLibrary
                                                          .isFalse
                                                      ? Icons.bookmark_add
                                                      : Icons.bookmark_added))),
                                          // Play button
                                          IconButton(
                                            tooltip: S.current.play,
                                              onPressed: () {
                                                playerController.playPlayListSong(
                                                    List<MediaItem>.from(
                                                        playlistController
                                                            .songList),
                                                    0,
                                                    playfrom: PlaylingFrom(
                                                        name: playlistController
                                                            .playlist.value.title,
                                                        type: PlaylingFromType
                                                            .PLAYLIST));
                                              },
                                              icon: Icon(
                                                Icons.play_circle,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color,
                                              )),
                                          // Enqueue button
                                          IconButton(
                                              tooltip: S.current.enqueueSongs,
                                              onPressed: () {
                                                Get.find<PlayerController>()
                                                    .enqueueSongList(
                                                        playlistController
                                                            .songList
                                                            .toList())
                                                    .whenComplete(() {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(snackbar(
                                                            context,
                                                            S.current.songEnqueueAlert,
                                                            size: SanckBarSize
                                                                .MEDIUM));
                                                  }
                                                });
                                              },
                                              icon: Icon(
                                                Icons.merge,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color,
                                              )),
                                      
                                          // Shuffle button
                                          IconButton(
                                              tooltip: S.current.shuffle,
                                              onPressed: () {
                                                final songsToplay =
                                                    List<MediaItem>.from(
                                                        playlistController
                                                            .songList);
                                                songsToplay.shuffle();
                                                songsToplay.shuffle();
                                                playerController.playPlayListSong(
                                                    songsToplay, 0,
                                                    playfrom: PlaylingFrom(
                                                        name: playlistController
                                                            .playlist.value.title,
                                                        type: PlaylingFromType
                                                            .PLAYLIST));
                                              },
                                              icon: Icon(
                                                Icons.shuffle,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium!
                                                    .color,
                                              )),
                                          // Download button
                                          GetX<Downloader>(builder: (controller) {
                                            final id = playlistController
                                                .playlist.value.playlistId;
                                            return IconButton(
                                              tooltip: S.current.downloadPlaylist,
                                              onPressed: () {
                                                if (playlistController
                                                    .isDownloaded.isTrue) {
                                                  return;
                                                }
                                                controller.downloadPlaylist(
                                                    id,
                                                    playlistController.songList
                                                        .toList());
                                              },
                                              icon: playlistController
                                                      .isDownloaded.isTrue
                                                  ? const Icon(
                                                      Icons.download_done)
                                                  : controller.playlistQueue
                                                              .containsKey(id) &&
                                                          controller
                                                                  .currentPlaylistId
                                                                  .toString() ==
                                                              id
                                                      ? Stack(
                                                          children: [
                                                            Center(
                                                                child: Text(
                                                                    "${controller.playlistDownloadingProgress.value}/${playlistController.songList.length}",
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .titleMedium!
                                                                        .copyWith(
                                                                            fontSize:
                                                                                10,
                                                                            fontWeight:
                                                                                FontWeight.bold))),
                                                            const Center(
                                                                child:
                                                                    LoadingIndicator(
                                                                dimension: 30,
                                                              ))
                                                          ],
                                                        )
                                                      : controller.playlistQueue
                                                              .containsKey(id)
                                                          ? const Stack(
                                                              children: [
                                                                Center(
                                                                    child: Icon(
                                                                  Icons
                                                                      .hourglass_bottom,
                                                                  size: 20,
                                                                )),
                                                                Center(
                                                                    child:
                                                                        LoadingIndicator(
                                                                  dimension: 30,
                                                                ))
                                                              ],
                                                            )
                                                          : const Icon(
                                                              Icons.download),
                                            );
                                          }),
                                      
                                          if (playlistController
                                              .isAddedToLibrary.isTrue)
                                            IconButton(
                                                tooltip:
                                                    S.current.syncPlaylistSongs,
                                                onPressed: () {
                                                  playlistController
                                                      .syncPlaylistSongs();
                                                },
                                                icon:
                                                    const Icon(Icons.cloud_sync)),
                                          if (playlistController
                                              .playlist.value.isPipedPlaylist)
                                            IconButton(
                                                tooltip:
                                                    S.current.blacklistPipedPlaylist,
                                                icon: const Icon(
                                                  Icons.block,
                                                  size: 20,
                                                ),
                                                splashRadius: 10,
                                                onPressed: () {
                                                  Get.nestedKey(
                                                          ScreenNavigationSetup
                                                              .id)!
                                                      .currentState!
                                                      .pop();
                                                  Get.find<
                                                          LibraryPlaylistsController>()
                                                      .blacklistPipedPlaylist(
                                                          playlistController
                                                              .playlist.value);
                                                  ScaffoldMessenger.of(
                                                          Get.context!)
                                                      .showSnackBar(snackbar(
                                                          Get.context!,
                                                          S.current.playlistBlacklistAlert,
                                                          size: SanckBarSize
                                                              .MEDIUM));
                                                }),
                                          if (playlistController
                                              .playlist.value.isCloudPlaylist)
                                            IconButton(
                                              tooltip:
                                                  S.current.sharePlaylist,
                                              visualDensity: const VisualDensity(
                                                vertical: -3,
                                              ),
                                              splashRadius: 10,
                                              onPressed: () {
                                                final content = playlistController
                                                    .playlist.value;
                                                if (content.isPipedPlaylist) {
                                                  YoutubeShareManager.sharePlaylist(content.playlistId);
                                                } else {
                                                  final isPlaylistIdPrefixAvlbl =
                                                      content.playlistId
                                                              .substring(0, 2) ==
                                                          "VL";
                                                  final id = isPlaylistIdPrefixAvlbl
                                                      ? content.playlistId.substring(2)
                                                      : content.playlistId;
                                                  YoutubeShareManager.sharePlaylist(id);
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.share,
                                                size: 20,
                                              ),
                                            ),
                                          // Export button - opens export dialog
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (dialogContext) =>
                                                    PlaylistExportDialog(
                                                  controller: playlistController,
                                                  parentContext: context,
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.file_upload),
                                            tooltip: S.current.exportPlaylist,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else if (index == 1) {
                                final title =
                                    playlistController.playlist.value.title;
                                final description = playlistController
                                    .playlist.value.description;

                                return AnimatedBuilder(
                                  key: const ValueKey('header_1'),
                                  animation:
                                      playlistController.animationController,
                                  builder: (context, child) {
                                    return SizedBox(
                                      height: playlistController
                                          .heightAnimation.value,
                                      child: Transform.scale(
                                        scale: playlistController
                                            .scaleAnimation.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 25.0, bottom: 10, right: 30),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Marquee(
                                          delay:
                                              const Duration(milliseconds: 300),
                                          duration: const Duration(seconds: 5),
                                          id: title.hashCode.toString(),
                                          child: Text(
                                            title.length > 50
                                                ? title.substring(0, 50)
                                                : title,
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(fontSize: 30),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Marquee(
                                            delay: const Duration(
                                                milliseconds: 300),
                                            duration:
                                                const Duration(seconds: 5),
                                            id: description.hashCode.toString(),
                                            child: Text(
                                              description ?? S.current.playlist,
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (index == 2) {
                                if (playlistController.isArranging.isTrue) {
                                  return Padding(
                                    key: const ValueKey('header_2_arranging'),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          S.current.reArrangePlaylist,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            playlistController.isArranging.value = false;
                                          },
                                          icon: const Icon(Icons.check),
                                          label: const Text("Listo"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.secondary,
                                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                }
                                return SizedBox(
                                    key: const ValueKey('header_2_sort'),
                                    height:
                                        playlistController.isSearchingOn.isTrue
                                            ? 60
                                            : 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0, right: 10),
                                      child: Obx(
                                        () => SortWidget(
                                          tag: playlistController
                                              .playlist.value.playlistId,
                                          screenController: playlistController,
                                          isSearchFeatureRequired: true,
                                          isPlaylistRearrageFeatureRequired: !playlistController
                                                  .playlist
                                                  .value
                                                  .isCloudPlaylist &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "LIBRP" &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "SongDownloads" &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "SongsCache",
                                          isSongDeletetioFeatureRequired:
                                              !playlistController.playlist.value
                                                  .isCloudPlaylist,
                                          itemCountTitle:
                                              "${playlistController.songList.length}",
                                          itemIcon: Icons.music_note,
                                          titleLeftPadding: 9,
                                          requiredSortTypes:
                                              buildSortTypeSet(false, true),
                                          onSort: playlistController.onSort,
                                          onSearch: playlistController.onSearch,
                                          onSearchClose:
                                              playlistController.onSearchClose,
                                          onSearchStart:
                                              playlistController.onSearchStart,
                                          startAdditionalOperation:
                                              playlistController
                                                  .startAdditionalOperation,
                                          selectAll:
                                              playlistController.selectAll,
                                          performAdditionalOperation:
                                              playlistController
                                                  .performAdditionalOperation,
                                          cancelAdditionalOperation:
                                              playlistController
                                                  .cancelAdditionalOperation,
                                        ),
                                      ),
                                    ));
                              } else if (playlistController
                                      .isContentFetched.isFalse ||
                                  playlistController.songList.isEmpty) {
                                return SizedBox(
                                  key: const ValueKey('header_3_empty'),
                                  height: 300,
                                  child: Center(
                                    child: playlistController
                                            .isContentFetched.isFalse
                                        ? const LoadingIndicator()
                                        : Text(
                                            S.current.emptyPlaylist,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                  ),
                                );
                              }

                              final song = playlistController.songList[index - 3];
                              final child = Padding(
                                padding:
                                    const EdgeInsets.only(left: 20.0, right: 5),
                                child: SongListTile(
                                  onTap: () {
                                    playerController.playPlayListSong(
                                        List<MediaItem>.from(
                                            playlistController.songList),
                                        index - 3,
                                        playfrom: PlaylingFrom(
                                            name: playlistController
                                                .playlist.value.title,
                                            type: PlaylingFromType.PLAYLIST));
                                  },
                                  song: song,
                                  isPlaylistOrAlbum: true,
                                  playlist: playlistController.playlist.value,
                                ),
                              );

                              if (playlistController.isArranging.isTrue) {
                                return KeyedSubtree(
                                  key: ValueKey('${song.id}_$index'),
                                  child: Row(
                                    children: [
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 10, right: 5),
                                          child: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.secondary),
                                        ),
                                      ),
                                      Expanded(child: child),
                                    ],
                                  ),
                                );
                              }
                              return KeyedSubtree(key: ValueKey('${song.id}_$index'), child: child);
                            }

                            final padding = EdgeInsets.only(
                              top: playlistController.isSearchingOn.isTrue ? 0 : landscape ? 150 : 200,
                              bottom: 200,
                            );
                            final itemCount = playlistController.songList.isEmpty || playlistController.isContentFetched.isFalse ? 4 : playlistController.songList.length + 3;

                            return ScrollConfiguration(
                              behavior: PlaylistAlbumScrollBehaviour(),
                              child: playlistController.isArranging.isTrue ?
                                ReorderableListView.builder(
                                  padding: padding,
                                  itemCount: itemCount,
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) {
                                    if (oldIndex < 3 || newIndex < 3) return;
                                    playlistController.reorderList(oldIndex - 3, newIndex - 3);
                                  },
                                  itemBuilder: buildItem,
                                )
                              : ListView.builder(
                                  addRepaintBoundaries: false,
                                  padding: padding,
                                  itemCount: itemCount,
                                  itemBuilder: buildItem,
                              ),
                            );
                          }),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future openBottomSheet(BuildContext context, MediaItem song) {
    return showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (context) => SongInfoBottomSheet(song),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  void _showCollaboratorsDialog(BuildContext context, PlaylistScreenController controller) {
    final textController = TextEditingController();
    final searchResults = <Map<String, dynamic>>[].obs;
    final isSearching = false.obs;
    final friends = <Map<String, dynamic>>[].obs;
    final isLoadingFriends = true.obs;

    Get.find<SyncService>().fetchFriends().then((value) {
      friends.value = value;
      isLoadingFriends.value = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Gestionar Colaboradores"),
        content: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: "Buscar por nombre de usuario...",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (val) async {
                        if (val.trim().isNotEmpty) {
                          isSearching.value = true;
                          final res = await Get.find<SyncService>().searchUsers(val);
                          searchResults.value = res;
                          isSearching.value = false;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () async {
                      final val = textController.text;
                      if (val.trim().isNotEmpty) {
                        isSearching.value = true;
                        final res = await Get.find<SyncService>().searchUsers(val);
                        searchResults.value = res;
                        isSearching.value = false;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => isSearching.isTrue
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: ListView(
                        children: [
                          if (searchResults.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text("Resultados de búsqueda:", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            ...searchResults.map((user) => ListTile(
                                  title: Text(user['username'] ?? ''),
                                  subtitle: Text("${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: () {
                                      controller.addCollaborator(user);
                                      Get.back();
                                      _showCollaboratorsDialog(context, controller); // reopen to update
                                    },
                                  ),
                                )),
                            const Divider(),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("Añadir Amigos:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (isLoadingFriends.isTrue)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          else ...[
                            ...(() {
                              final collaboratorsIds = controller.playlist.value.collaborators.map((c) => c['id']).toSet();
                              final addableFriends = friends.where((f) => !collaboratorsIds.contains(f['id'])).toList();
                              if (addableFriends.isEmpty) {
                                return [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      "No hay amigos disponibles para añadir.",
                                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                                    ),
                                  )
                                ];
                              }
                              return addableFriends.map((friend) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(friend['username'] ?? ''),
                                    subtitle: Text("${friend['first_name'] ?? ''} ${friend['last_name'] ?? ''}"),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.green),
                                      onPressed: () {
                                        controller.addCollaborator(friend);
                                        Get.back();
                                        _showCollaboratorsDialog(context, controller);
                                      },
                                    ),
                                  )).toList();
                            })()
                          ],
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("Colaboradores actuales:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (controller.playlist.value.collaborators.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text("No hay colaboradores añadidos.", style: TextStyle(fontStyle: FontStyle.italic)),
                            ),
                          ...controller.playlist.value.collaborators.map((user) => ListTile(
                                title: Text(user['username'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () {
                                    controller.removeCollaborator(Map<String, dynamic>.from(user));
                                    Get.back();
                                    _showCollaboratorsDialog(context, controller); // reopen to update
                                  },
                                ),
                              )),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }
}
