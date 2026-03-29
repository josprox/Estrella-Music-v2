import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';

import '../../widgets/loader.dart';
import '../player_controller.dart';

class LyricsWidget extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final bool isFull;
  const LyricsWidget({super.key, required this.padding, this.isFull = false});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Obx(() {
      if (playerController.isLyricsLoading.isTrue) {
        return const Center(child: LoadingIndicator());
      }

      final synced = playerController.lyrics['synced'].toString();
      final plain = playerController.lyrics["plainLyrics"].toString();
      final hasSynced = synced.isNotEmpty && synced != 'null' && synced != '""';
      final hasPlain = plain.isNotEmpty && plain != 'NA' && plain != 'null';
      final mode = playerController.lyricsMode.toInt();

      // Determine what to show based on availability and preferred mode
      bool showSynced = false;
      if (mode == 0) {
        // Preferred synced
        showSynced = hasSynced;
      } else {
        // Preferred plain
        showSynced = !hasPlain && hasSynced;
      }

      if (showSynced) {
        return IgnorePointer(
          ignoring: !isFull,
          child: LyricsReader(
            padding: const EdgeInsets.only(left: 10, right: 10),
            lyricUi: playerController.lyricUi,
            position: playerController
                .progressBarStatus.value.current.inMilliseconds,
            model: LyricsModelBuilder.create()
                .bindLyricToMain(synced)
                .getModel(),
            emptyBuilder: () => _buildNoLyrics(context, playerController),
          ),
        );
      }

      if (hasPlain || (mode == 1 && !hasSynced)) {
        return Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: padding,
            child: TextSelectionTheme(
              data: Theme.of(context).textSelectionTheme,
              child: SelectableText(
                hasPlain ? plain : "lyricsNotAvailable".tr,
                textAlign: TextAlign.center,
                style: playerController.isDesktopLyricsDialogOpen
                    ? Theme.of(context).textTheme.titleMedium!
                    : const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
              ),
            ),
          ),
        );
      }

      return _buildNoLyrics(context, playerController);
    });
  }

  Widget _buildNoLyrics(BuildContext context, PlayerController ctrl) {
    return Center(
      child: Text(
        "lyricsNotAvailable".tr,
        textAlign: TextAlign.center,
        style: ctrl.isDesktopLyricsDialogOpen
            ? Theme.of(context).textTheme.titleMedium!
            : const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
      ),
    );
  }
}
