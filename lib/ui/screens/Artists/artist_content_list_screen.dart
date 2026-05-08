import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/models/album.dart';
import '/services/music_service.dart';
import '/ui/widgets/loader.dart';
import '/ui/widgets/image_widget.dart';
import '/ui/player/player_controller.dart';
import '/ui/navigator.dart';
import '/generated/l10n.dart';

class ArtistContentListController extends GetxController {
  final musicServices = Get.find<MusicServices>();
  final items = <dynamic>[].obs;
  final isLoading = true.obs;
  final isMoreLoading = false.obs;
  String? additionalParams;
  late Map<String, dynamic> browseEndpoint;
  late String categoryTitle;
  late String categoryRaw;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    final dynamic args = Get.arguments;
    if (args is Map<String, dynamic>) {
      browseEndpoint = args['browseEndpoint'] ?? {};
      categoryTitle = args['title'] ?? '';
      categoryRaw = args['category'] ?? categoryTitle;
    } else {
      // Fallback or error handling if needed
      browseEndpoint = {};
      categoryTitle = '';
      categoryRaw = '';
    }

    _fetchInitialContent();
    
    scrollController.addListener(() {
      if (scrollController.hasClients && scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.8) {
        _fetchMoreContent();
      }
    });
    super.onInit();
  }

  Future<void> _fetchInitialContent() async {
    isLoading.value = true;
    try {
      final result = await musicServices.getArtistRealtedContent(browseEndpoint, categoryRaw);
      items.assignAll(result['results'] ?? []);
      additionalParams = result['additionalParams'];
    } catch (e) {
      debugPrint("Error fetching artist content: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchMoreContent() async {
    if (isMoreLoading.value || additionalParams == null || additionalParams == '&ctoken=null&continuation=null') return;
    
    isMoreLoading.value = true;
    try {
      final result = await musicServices.getArtistRealtedContent(
        browseEndpoint, 
        categoryRaw,
        additionalParams: additionalParams ?? ""
      );
      items.addAll(result['results'] ?? []);
      additionalParams = result['additionalParams'];
    } catch (e) {
      debugPrint("Error fetching more artist content: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

class ArtistContentListScreen extends StatelessWidget {
  const ArtistContentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(body: Center(child: Text("Error: Missing arguments")));
    }
    final tag = (args['category'] ?? args['title']) as String;

    final controller = Get.isRegistered<ArtistContentListController>(tag: tag)
        ? Get.find<ArtistContentListController>(tag: tag)
        : Get.put(ArtistContentListController(), tag: tag);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(controller.categoryTitle,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            // Delete the tagged controller on pop so a new push re-fetches
            Get.delete<ArtistContentListController>(tag: tag);
            Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
          },
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: LoadingIndicator());
        }

        return ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: controller.items.length + (controller.isMoreLoading.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == controller.items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: LoadingIndicator()),
              );
            }

            final item = controller.items[index];
            return _getContentTile(context, item, index, controller.items);
          },
        );
      }),
    );
  }

  Widget _getContentTile(BuildContext context, dynamic item, int index, List<dynamic> allItems) {
    if (item is MediaItem) {
      return ListTile(
        leading: ImageWidget(
          song: item,
          size: 50,
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500)),
        subtitle: Text(item.artist ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                fontSize: 12)),
        onTap: () {
          final pCtrl = Get.find<PlayerController>();
          // Convert all currently loaded MediaItems to play as a list
          final mediaItems = allItems.whereType<MediaItem>().toList();
          final itemIndex = mediaItems.indexOf(item);
          if (itemIndex != -1) {
            pCtrl.playPlayListSong(mediaItems, itemIndex);
          }
        },
      );
    } else if (item is Album) {
      return ListTile(
        leading: ImageWidget(
          album: item,
          size: 50,
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500)),
        subtitle: Text("${item.year ?? ''} • ${item.description ?? S.current.album}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                fontSize: 12)),
        onTap: () {
          Get.toNamed(
            ScreenNavigationSetup.albumScreen,
            id: ScreenNavigationSetup.id,
            arguments: (item, item.browseId),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
