import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/models/album.dart';
import '/models/artist.dart';
import '/models/playlist.dart';
import '/ui/widgets/content_list_widget.dart';
import 'separate_tab_item_widget.dart';
import 'package:harmonymusic/generated/l10n.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({super.key, this.isv2Used = false});
  final bool isv2Used;

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController searchResScrController =
        Get.find<SearchResultScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 80.0;
    return Obx(
      () => Center(
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: SingleChildScrollView(
            padding:
                EdgeInsets.only(bottom: 200, top: isv2Used ? 0 : topPadding),
            child: searchResScrController.isResultContentFetced.value
                ? Column(children: [
                    if (!isv2Used)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          S.current.searchRes,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    if (!isv2Used)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${S.current.for1} \"${searchResScrController.queryString.value}\"",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    ...generateWidgetList(searchResScrController),
                  ])
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  List<Widget> generateWidgetList(
      SearchResultScreenController searchResScrController) {
    List<Widget> list = [];
    for (dynamic item in searchResScrController.resultContent.entries) {
      final values = item.value is List ? item.value as List : [item.value];
      if (values.isEmpty) continue;

      if (item.key == "Songs" || item.key == "Videos" || item.key == "Episodes") {
        list.add(SeparateTabItemWidget(
          items: values.whereType<MediaItem>().toList(),
          title: item.key,
          isCompleteList: false,
        ));
      } else if (item.key == "Albums" || item.key == "Podcasts") {
        list.add(ContentListWidget(
          content: AlbumContent(
              title: item.key, albumList: values.whereType<Album>().toList()),
          isHomeContent: false,
        ));
      } else if (item.key == "Playlists" ||
          item.key == "Featured playlists" ||
          item.key == "Community playlists") {
        list.add(ContentListWidget(
          content: PlaylistContent(
              title: item.key,
              playlistList: values.whereType<Playlist>().toList()),
          isHomeContent: false,
        ));
      } else if (item.key.contains("Artist") || item.key == "Profiles") {
        list.add(SeparateTabItemWidget(
          items: values.whereType<Artist>().toList(),
          title: item.key,
          isCompleteList: false,
        ));
      } else if (item.key == "Top Result" || item.key == "Top result") {
        final top = values.first;
        if (top is MediaItem) {
          list.add(SeparateTabItemWidget(
            items: [top],
            title: item.key,
            isCompleteList: false,
          ));
        } else if (top is Album) {
          list.add(ContentListWidget(
            content: AlbumContent(title: item.key, albumList: [top]),
            isHomeContent: false,
          ));
        } else if (top is Playlist) {
          list.add(ContentListWidget(
            content: PlaylistContent(title: item.key, playlistList: [top]),
            isHomeContent: false,
          ));
        } else if (top is Artist) {
          list.add(SeparateTabItemWidget(
            items: [top],
            title: item.key,
            isCompleteList: false,
          ));
        }
      }
    }

    return list;
  }
}
