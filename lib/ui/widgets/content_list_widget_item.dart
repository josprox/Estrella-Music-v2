import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../navigator.dart';
import 'image_widget.dart';

class ContentListItem extends StatelessWidget {
  final double? width;
  final double? height;
  final double? imageSize;
  const ContentListItem(
      {super.key,
      required this.content,
      this.isLibraryItem = false,
      this.width,
      this.height,
      this.imageSize});
// ignore: unused_element
  // const ContentListItem.old(
  // {super.key, required this.content, this.isLibraryItem = false});

  ///content will be of Type class Album or Playlist
  final dynamic content;
  final bool isLibraryItem;

  @override
  Widget build(BuildContext context) {
    final finalWidth = width ?? 130.0;
    final finalHeight = height ?? 194.0;
    final finalImageSize = imageSize ?? 120.0;
    final isAlbum = content.runtimeType.toString() == "Album";
    final subtitle = isAlbum
        ? isLibraryItem
            ? ""
            : content.isPodcast
                ? "${content.artists[0]['name'] ?? ""}${content.episodeCount == null ? "" : " | ${content.episodeCount}"}"
                : "${content.artists[0]['name'] ?? ""} | ${content.year ?? ""}"
        : isLibraryItem
            ? ""
            : content.description ?? "";
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        if (isAlbum) {
          Get.toNamed(ScreenNavigationSetup.albumScreen,
              id: ScreenNavigationSetup.id,
              arguments: (content, content.browseId));
          return;
        }
        Get.toNamed(ScreenNavigationSetup.playlistScreen,
            id: ScreenNavigationSetup.id,
            arguments: [content, content.playlistId]);
      },
      child: Container(
        width: finalWidth,
        height: finalHeight,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isAlbum
                ? ImageWidget(
                    size: finalImageSize,
                    album: content,
                  )
                : content.isCloudPlaylist ||
                        !(content.playlistId == 'LIBRP' ||
                            content.playlistId == 'LIBFAV' ||
                            content.playlistId == 'SongsCache' ||
                            content.playlistId == 'SongDownloads')
                    ? SizedBox.square(
                        dimension: finalImageSize,
                        child: Stack(
                          children: [
                            ImageWidget(
                              size: finalImageSize,
                              playlist: content,
                            ),
                            if (content.isPipedPlaylist)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height: 18,
                                    width: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    child: Center(
                                        child: Text(
                                      "P",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(fontSize: 14),
                                    )),
                                  ),
                                ),
                              ),
                            if (!content.isCloudPlaylist)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height: 18,
                                    width: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    child: Center(
                                        child: Text(
                                      "L",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(fontSize: 14),
                                    )),
                                  ),
                                ),
                              )
                          ],
                        ),
                      )
                    : Container(
                        height: finalImageSize,
                        width: finalImageSize,
                        decoration: BoxDecoration(
                            color: Theme.of(context).primaryColorLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                            child: Icon(
                          content.playlistId == 'LIBRP'
                              ? Icons.history
                              : content.playlistId == 'LIBFAV'
                                  ? Icons.favorite
                                  : content.playlistId == 'SongsCache'
                                      ? Icons.flight
                                      : Icons.download,
                          color: Colors.white,
                          size: 40,
                        ))),
            const SizedBox(height: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(height: 1.25),
                  ),
                  if (subtitle.trim().isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
