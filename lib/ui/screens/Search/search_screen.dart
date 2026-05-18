
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            NebulaBackground(seedString: searchScreenController.searchText),
            SafeArea(
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
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _FloatingSearchBarSliver(controller: searchScreenController),
                        _AestheticCategoriesSliver(controller: searchScreenController),
                        SliverToBoxAdapter(
                          child: Obx(() {
                            final isSearchEmpty = searchScreenController.searchText.value.isEmpty;
                            if (!isSearchEmpty) {
                              return _SearchResults(controller: searchScreenController);
                            }
                            return _DefaultSearchView(controller: searchScreenController);
                          }),
                        ),
                      ],
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

class _FloatingSearchBarSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _FloatingSearchBarSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      toolbarHeight: 70,
      title: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.textInputController,
                    focusNode: controller.focusNode,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.95),
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                Obx(() => controller.searchText.value.isNotEmpty
                    ? IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: Icon(Icons.close_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 18),
                        onPressed: controller.reset,
                      )
                    : const SizedBox(width: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AestheticCategoriesSliver extends StatelessWidget {
  final SearchScreenController controller;

  const _AestheticCategoriesSliver({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.searchText.value.isNotEmpty) return const SizedBox.shrink();
        
        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            physics: const BouncingScrollPhysics(),
            itemCount: controller.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = controller.categories[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                      id: ScreenNavigationSetup.id, arguments: category.name);
                  controller.addToHistryQueryList(category.name);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _DefaultSearchView extends StatelessWidget {
  final SearchScreenController controller;

  const _DefaultSearchView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Obx(() {
            if (controller.historyQuerylist.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.recentSearches,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.historyQuerylist.length,
                  itemBuilder: (context, index) {
                    final query = controller.historyQuerylist[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                            id: ScreenNavigationSetup.id, arguments: query);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.48)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                query,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.removeQueryFromHistory(query),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final SearchScreenController controller;

  const _SearchResults({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.urlPasted.isTrue) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: InkWell(
            onTap: () {
              controller.filterLinks(Uri.parse(controller.textInputController.text));
              controller.reset();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                S.current.urlSearchDes,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
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

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: combinedList.length,
        itemBuilder: (context, index) {
          final item = combinedList[index];
          return SearchItem(
            queryString: item['query'],
            isHistoryString: item['isHistory'],
          );
        },
      );
    });
  }
}
