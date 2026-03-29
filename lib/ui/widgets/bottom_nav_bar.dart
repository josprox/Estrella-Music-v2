import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_tabbar_minimize/liquid_tabbar_minimize.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeScreenController>();

    return Obx(
      () => LiquidBottomNavigationBar(
        currentIndex: ctrl.tabIndex.toInt(),
        onTap: ctrl.onBottonBarTabSelected,
        labelVisibility: LabelVisibility.always,
        items: [
          _dest(Icons.home_rounded, Icons.home_outlined, 'home'.tr, 'house', 'house.fill'),
          _dest(Icons.search_rounded, Icons.search_outlined, 'search'.tr, 'magnifyingglass', 'magnifyingglass'),
          _dest(Icons.library_music_rounded, Icons.library_music_outlined, 'library'.tr, 'music.note.list', 'music.note.list'),
          _dest(Icons.settings_rounded, Icons.settings_outlined, 'settings'.tr, 'gearshape', 'gearshape.fill'),
        ],
      ),
    );
  }

  LiquidTabItem _dest(IconData sel, IconData unsel, String label, String sfSymbol, String selectedSfSymbol) {
    final short = label.length > 9 ? '${label.substring(0, 8)}..' : label;
    return LiquidTabItem(
      widget: Icon(unsel, color: Colors.white38),
      selectedWidget: Icon(sel, color: Colors.white),
      sfSymbol: sfSymbol,
      selectedSfSymbol: selectedSfSymbol,
      label: short,
    );
  }
}
