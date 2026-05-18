import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/generated/l10n.dart';

import '/ui/navigator.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../../widgets/nebula_background.dart';
import 'components/search_item.dart';
import 'search_screen_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.put(SearchScreenController());
    final settingsScreenController = Get.find<SettingsScreenController>();

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            NebulaBackground(seedString: searchScreenController.searchText),
            SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (settingsScreenController.isBottomNavBarEnabled.isFalse)
                    Container(
                      width: 60,
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: context.isLandscape ? 10.0 : 20.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Theme.of(context).textTheme.titleMedium!.color,
                              ),
                              onPressed: () {
                                Get.nestedKey(ScreenNavigationSetup.id)!
                                    .currentState!
                                    .pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Obx(() {
                      final isSearchEmpty = searchScreenController.searchText.value.isEmpty;
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          if (isSearchEmpty) const _ExpressiveTitleSliver(),
                          _SearchBarSliver(controller: searchScreenController),
                          if (isSearchEmpty) ...[
                            _ExpressiveGridCategoriesSliver(controller: searchScreenController),
                            _RecentSearchesHeaderSliver(controller: searchScreenController),
                            _RecentSearchesSliver(controller: searchScreenController),
                          ] else ...[
                            _SearchResultsSliver(controller: searchScreenController),
                          ],
                          const SliverPadding(padding: EdgeInsets.only(bottom: 220)),
                        ],
                      );
                    }),
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

class _ExpressiveTitleSliver extends StatelessWidget {
  const _ExpressiveTitleSliver();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 8.0),
        child: Text(
          S.current.search,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
    );
  }
}

class _SearchBarSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _SearchBarSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      toolbarHeight: 76,
      automaticallyImplyLeading: false,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 18),
                Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.textInputController,
                    focusNode: controller.focusNode,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: controller.onChanged,
                    onSubmitted: (val) {
                      if (val.contains("https://")) {
                        controller.filterLinks(Uri.parse(val));
                        controller.reset();
                        return;
                      }
                      Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                          id: ScreenNavigationSetup.id, arguments: val);
                      controller.addToHistryQueryList(val);
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      hintText: S.current.searchDes,
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Obx(() => controller.searchText.value.isNotEmpty
                    ? IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        onPressed: controller.reset,
                      )
                    : const SizedBox(width: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpressiveGridCategoriesSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _ExpressiveGridCategoriesSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = controller.categories[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                        id: ScreenNavigationSetup.id, arguments: category.name);
                    controller.addToHistryQueryList(category.name);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      Image.network(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: category.color.withValues(alpha: 0.2),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: category.color.withValues(alpha: 0.25),
                          );
                        },
                      ),
                      // Gradient Overlay matching Category color
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              category.color.withValues(alpha: 0.85),
                              category.color.withValues(alpha: 0.25),
                            ],
                          ),
                        ),
                      ),
                      // Text label
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: controller.categories.length,
        ),
      ),
    );
  }
}

class _RecentSearchesHeaderSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _RecentSearchesHeaderSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.historyQuerylist.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 8.0),
          child: Text(
            S.current.recentSearches,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      );
    });
  }
}

class _RecentSearchesSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _RecentSearchesSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.historyQuerylist;
      if (list.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final query = list[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                            id: ScreenNavigationSetup.id, arguments: query);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                query,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                              onPressed: () => controller.removeQueryFromHistory(query),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: list.length,
          ),
        ),
      );
    });
  }
}

class _SearchResultsSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _SearchResultsSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.urlPasted.isTrue) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 24, right: 24),
            child: InkWell(
              onTap: () {
                controller.filterLinks(Uri.parse(controller.textInputController.text));
                controller.reset();
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  S.current.urlSearchDes,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final combinedList = <Map<String, dynamic>>[];
      
      for (var query in controller.filteredHistory) {
        combinedList.add({'query': query, 'isHistory': true});
      }
      
      for (var query in controller.apiSuggestions) {
        combinedList.add({'query': query, 'isHistory': false});
      }

      if (combinedList.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = combinedList[index];
              return SearchItem(
                queryString: item['query'],
                isHistoryString: item['isHistory'],
              );
            },
            childCount: combinedList.length,
          ),
        ),
      );
    });
  }
}
