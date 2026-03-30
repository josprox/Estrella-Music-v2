import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Search/components/desktop_search_bar.dart';
import '/ui/screens/Search/search_screen_controller.dart';
import '/ui/widgets/animated_screen_transition.dart';
import '../Library/library_combined.dart';
import '../../widgets/side_nav_bar.dart';
import '../Library/library.dart';
import '../Search/search_screen.dart';
import '../Settings/settings_screen_controller.dart';
import '/ui/player/player_controller.dart';
import '/ui/widgets/create_playlist_dialog.dart';
import '../../navigator.dart';
import '../../widgets/content_list_widget.dart';
import '../../widgets/quickpickswidget.dart';
import '../../widgets/shimmer_widgets/home_shimmer.dart';
import 'home_screen_controller.dart';
import '../Settings/settings_screen.dart';
import '/models/quick_picks.dart';

import '/ui/theme/app_spacing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final HomeScreenController homeScreenController =
        Get.find<HomeScreenController>();
    final SettingsScreenController settingsScreenController =
        Get.find<SettingsScreenController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Obx(
        () => ((homeScreenController.tabIndex.value == 0 &&
                        !GetPlatform.isDesktop) ||
                    homeScreenController.tabIndex.value == 1) &&
                settingsScreenController.isBottomNavBarEnabled.isFalse
            ? Obx(
                () => Padding(
                  padding: EdgeInsets.only(
                    bottom: playerController.playerPanelMinHeight.value >
                            Get.mediaQuery.padding.bottom
                        ? playerController.playerPanelMinHeight.value -
                            Get.mediaQuery.padding.bottom
                        : playerController.playerPanelMinHeight.value,
                  ),
                  child: _GlassFab(
                    icon: homeScreenController.tabIndex.value == 1
                        ? Icons.add_rounded
                        : Icons.search_rounded,
                    onTap: () {
                      if (homeScreenController.tabIndex.value == 1) {
                        showDialog(
                            context: context,
                            builder: (_) =>
                                const CreateNRenamePlaylistPopup());
                      } else {
                        Get.toNamed(ScreenNavigationSetup.searchScreen,
                            id: ScreenNavigationSetup.id);
                      }
                    },
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: Obx(
        () => Row(
          children: [
            settingsScreenController.isBottomNavBarEnabled.isFalse
                ? const SideNavBar()
                : const SizedBox(width: 0),
            Expanded(
              child: Obx(() => AnimatedScreenTransition(
                    enabled: settingsScreenController
                        .isTransitionAnimationDisabled.isFalse,
                    resverse:
                        homeScreenController.reverseAnimationtransiton,
                    horizontalTransition: settingsScreenController
                        .isBottomNavBarEnabled.isTrue,
                    child: Center(
                      key: ValueKey<int>(
                          homeScreenController.tabIndex.value),
                      child: const Body(),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button with glass styling
class _GlassFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [cs.primary, cs.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    final size = MediaQuery.of(context).size;

    final topPadding = GetPlatform.isDesktop
        ? 88.0
        : context.isLandscape
            ? 52.0
            : size.height < 750
                ? 80.0
                : 88.0;

    final leftPadding =
        settingsScreenController.isBottomNavBarEnabled.isTrue ? 20.0 : 8.0;

    if (homeScreenController.tabIndex.value == 0) {
      return Padding(
        padding: EdgeInsets.only(left: leftPadding),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (GetPlatform.isDesktop) {
                  final sscontroller =
                      Get.find<SearchScreenController>();
                  if (sscontroller.focusNode.hasFocus) {
                    sscontroller.focusNode.unfocus();
                  }
                }
              },
              child: Obx(
                () => homeScreenController.networkError.isTrue
                    ? _NetworkError(
                        onRetry: homeScreenController
                            .loadContentFromNetwork)
                    : Obx(() {
                        homeScreenController
                            .disposeDetachedScrollControllers();

                        final items = homeScreenController.isContentFetched.value
                            ? [
                                Obx(() {
                                  final sc = ScrollController();
                                  homeScreenController.contentScrollControllers
                                      .add(sc);
                                  return QuickPicksWidget(
                                      content:
                                          homeScreenController.quickPicks.value,
                                      scrollController: sc);
                                }),
                                ...getWidgetList(
                                    homeScreenController.middleContent,
                                    homeScreenController),
                                ...getWidgetList(
                                    homeScreenController.fixedContent,
                                    homeScreenController),
                              ]
                            : [const HomeShimmer()];

                        return ListView.builder(
                          padding:
                              EdgeInsets.only(bottom: 200, top: topPadding),
                          itemCount: items.length,
                          itemBuilder: (_, i) => items[i],
                        );
                      }),
              ),
            ),
            // Desktop search bar
            if (GetPlatform.isDesktop)
              Align(
                alignment: Alignment.topCenter,
                child: LayoutBuilder(builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth > 800
                        ? 800
                        : constraints.maxWidth - 40,
                    child: const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.lg),
                        child: DesktopSearchBar()),
                  );
                }),
              ),
          ],
        ),
      );
    } else if (homeScreenController.tabIndex.value == 1) {
      return settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const SearchScreen()
          : const SongsLibraryWidget();
    } else if (homeScreenController.tabIndex.value == 2) {
      return settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const CombinedLibrary()
          : const PlaylistNAlbumLibraryWidget(isAlbumContent: false);
    } else if (homeScreenController.tabIndex.value == 3) {
      return settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const SettingsScreen(isBottomNavActive: true)
          : const PlaylistNAlbumLibraryWidget();
    } else if (homeScreenController.tabIndex.value == 4) {
      return const LibraryArtistWidget();
    } else if (homeScreenController.tabIndex.value == 5) {
      return const SettingsScreen();
    } else {
      return Center(
          child: Text('${homeScreenController.tabIndex.value}'));
    }
  }


  List<Widget> getWidgetList(
      dynamic list, HomeScreenController homeScreenController) {
    return list
        .map((content) {
          final sc = ScrollController();
          homeScreenController.contentScrollControllers.add(sc);
          if (content.runtimeType == QuickPicks) {
            return QuickPicksWidget(content: content, scrollController: sc);
          }
          return ContentListWidget(content: content, scrollController: sc);
        })
        .whereType<Widget>()
        .toList();
  }
}

class _NetworkError extends StatelessWidget {
  final VoidCallback onRetry;
  const _NetworkError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height - 180,
      child: Column(children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text('home'.tr, style: tt.headlineSmall),
        ),
        Expanded(
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 64, color: cs.onSurface.withOpacity(0.3)),
                  const SizedBox(height: AppSpacing.lg),
                  Text('networkError1'.tr,
                      style: tt.titleMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.6))),
                  const SizedBox(height: AppSpacing.xl),
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text('retry'.tr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                ]),
          ),
        )
      ]),
    );
  }
}
