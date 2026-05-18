import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'liquid_bottom_navigation_bar.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';
import 'package:harmonymusic/generated/l10n.dart';

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
          _dest(Icons.home_rounded, Icons.home_outlined, S.current.home,
              'house', 'house.fill'),
          _dest(Icons.music_note_rounded, Icons.music_note_outlined,
              S.current.libSongs, 'music.note', 'music.note'),
          _dest(Icons.album_rounded, Icons.album_outlined, S.current.libAlbums,
              'play.rectangle', 'play.rectangle.fill'),
          _dest(Icons.people_alt_rounded, Icons.people_outline_rounded,
              S.current.libArtists, 'person.2', 'person.2.fill'),
          _dest(Icons.queue_music_rounded, Icons.queue_music_outlined,
              S.current.libPlaylists, 'music.note.list', 'music.note.list'),
        ],
      ),
    );
  }

  LiquidTabItem _dest(IconData sel, IconData unsel, String label,
      String sfSymbol, String selectedSfSymbol) {
    final short = label.length > 9 ? '${label.substring(0, 8)}..' : label;
    return LiquidTabItem(
      widget: Icon(unsel),
      selectedWidget: Icon(sel),
      sfSymbol: sfSymbol,
      selectedSfSymbol: selectedSfSymbol,
      label: short,
    );
  }
}
