import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screens/Search/search_result_screen_controller.dart';
import '/ui/widgets/content_list_widget_item.dart';
import '/ui/theme/app_spacing.dart';
import 'package:harmonymusic/generated/l10n.dart';

class ContentListWidget extends StatelessWidget {
  /// ContentListWidget renders a horizontal-scroll section of Albums or Playlists
  const ContentListWidget(
      {super.key,
      this.content,
      this.isHomeContent = true,
      this.scrollController});

  final dynamic content;
  final bool isHomeContent;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final isAlbumContent =
        content.runtimeType.toString() == 'AlbumContent';
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    !isHomeContent && content.title.length > 14
                        ? '${content.title.substring(0, 14)}…'
                        : content.title,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isHomeContent)
                  TextButton(
                    onPressed: () {
                      final ctrl =
                          Get.find<SearchResultScreenController>();
                      ctrl.viewAllCallback(content.title);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        side: BorderSide(
                          color: cs.primary.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      S.current.viewAll,
                      style: tt.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Horizontal list ────────────────────────────────────────────────
          SizedBox(
            height: 212,
            child: Scrollbar(
              thickness: GetPlatform.isDesktop ? null : 0,
              controller: scrollController,
              child: ListView.separated(
                controller: scrollController,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.md),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm),
                itemCount: isAlbumContent
                    ? content.albumList.length
                    : content.playlistList.length,
                itemBuilder: (_, index) {
                  return isAlbumContent
                      ? ContentListItem(
                          content: content.albumList[index])
                      : ContentListItem(
                          content: content.playlistList[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
