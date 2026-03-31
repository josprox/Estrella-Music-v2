import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/generated/l10n.dart';

import '/ui/navigator.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import 'components/search_item.dart';
import 'search_screen_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.put(SearchScreenController());
    final settingsScreenController = Get.find<SettingsScreenController>();
    final topPadding = context.isLandscape ? 40.0 : 60.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => Row(
          children: [
            if (settingsScreenController.isBottomNavBarEnabled.isFalse)
              Container(
                width: 60,
                color: Theme.of(context).navigationRailTheme.backgroundColor,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: topPadding),
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
              child: Padding(
                padding: EdgeInsets.only(top: topPadding, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Styled Search Bar
                    _SearchBar(controller: searchScreenController),
                    const SizedBox(height: 24),

                    Expanded(
                      child: Obx(() {
                        final isSearchEmpty =
                            searchScreenController.searchText.value.isEmpty;

                        if (!isSearchEmpty) {
                          // Show Suggestions or URL Search
                          return _SearchResults(
                              controller: searchScreenController);
                        }

                        // Default View: Recent Searches + Categories
                        return _DefaultSearchView(
                            controller: searchScreenController);
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final SearchScreenController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller.textInputController,
        focusNode: controller.focusNode,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.sentences,
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
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: S.current.searchDes,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          suffixIcon: Obx(() => controller.searchText.value.isNotEmpty
              ? IconButton(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.close, color: Colors.white70),
                )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}

class _DefaultSearchView extends StatelessWidget {
  final SearchScreenController controller;

  const _DefaultSearchView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        Obx(() {
          if (controller.historyQuerylist.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Búsquedas recientes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.historyQuerylist.length,
                  itemBuilder: (context, index) {
                    final query = controller.historyQuerylist[index];
                    final colors = [
                      const Color(0xFFE91E63),
                      const Color(0xFF2196F3),
                      const Color(0xFFFFC107),
                      const Color(0xFF009688),
                    ];
                    final chipColor = colors[index % colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          Get.toNamed(ScreenNavigationSetup.searchResultScreen,
                              id: ScreenNavigationSetup.id, arguments: query);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Text(
                                query,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () =>
                                    controller.removeQueryFromHistory(query),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        }),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            return _CategoryCard(category: category);
          },
        ),
      ],
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
        child: InkWell(
          onTap: () {
            controller.filterLinks(
                Uri.parse(controller.textInputController.text));
            controller.reset();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              S.current.urlSearchDes,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Obx(() => ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: controller.suggestionList.length,
          itemBuilder: (context, index) {
            final item = controller.suggestionList[index];
            return SearchItem(queryString: item, isHistoryString: false);
          },
        ));
  }
}

class _CategoryCard extends StatelessWidget {
  final SearchCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.find<SearchScreenController>();
    return InkWell(
      onTap: () {
        Get.toNamed(ScreenNavigationSetup.searchResultScreen,
            id: ScreenNavigationSetup.id, arguments: category.name);
        searchScreenController.addToHistryQueryList(category.name);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 16,
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              right: -15,
              bottom: -5,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(5, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: category.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => const Icon(Icons.music_note),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
