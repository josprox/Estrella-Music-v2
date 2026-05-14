import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../search_result_screen_controller.dart';


class SearchChips extends StatelessWidget {
  const SearchChips({super.key});

  @override
  Widget build(BuildContext context) {
    final SearchResultScreenController controller = Get.find<SearchResultScreenController>();

    return Obx(() {
      if (!controller.isResultContentFetced.value || controller.railItems.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.railItems.length + 1,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final label = isAll ? 'All' : controller.railItems[index - 1];
            final isSelected = controller.navigationRailCurrentIndex.value == index;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  controller.onDestinationSelected(index);
                },
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
