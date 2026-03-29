import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';
import 'package:sidebar_with_animation/animated_side_bar.dart';
import '/ui/theme/app_colors.dart';


class SideNavBar extends StatelessWidget {
  const SideNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileOrTabScreen = size.width < 480;
    final homeScreenController = Get.find<HomeScreenController>();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                .withOpacity(0.7),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(isDark ? 0.08 : 0.25),
                width: 0.5,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: isMobileOrTabScreen
                ? _buildCompactRail(homeScreenController, size, cs, isDark)
                : _buildAnimatedSidebar(homeScreenController, cs, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRail(HomeScreenController ctrl, Size size,
      ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: IntrinsicHeight(
        child: Obx(
          () => NavigationRail(
            useIndicator: false,
            selectedIndex: ctrl.tabIndex.value,
            onDestinationSelected: ctrl.onSideBarTabSelected,
            backgroundColor: Colors.transparent,
            minWidth: 60,
            leading: SizedBox(height: size.height < 750 ? 24 : 48),
            labelType: NavigationRailLabelType.all,
            destinations: [
              _compactRailDest('home'.tr, Icons.home_rounded),
              _compactRailDest('songs'.tr, Icons.audiotrack_rounded),
              _compactRailDest('playlists'.tr, Icons.library_music_rounded),
              _compactRailDest('albums'.tr, Icons.album_rounded),
              _compactRailDest('artists'.tr, Icons.people_rounded),
              _compactRailDest('settings'.tr, Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  NavigationRailDestination _compactRailDest(String label, IconData icon) {
    return NavigationRailDestination(
      icon: const SizedBox.shrink(),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RotatedBox(
          quarterTurns: -1,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildAnimatedSidebar(HomeScreenController ctrl,
      ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100.0),
      child: SideBarAnimated(
        onTap: ctrl.onSideBarTabSelected,
        sideBarColor: Colors.transparent,
        animatedContainerColor: cs.primary.withOpacity(0.22),
        hoverColor: cs.primary.withOpacity(0.12),
        splashColor: cs.primary.withOpacity(0.18),
        highlightColor: cs.primary.withOpacity(0.12),
        widthSwitch: 800,
        mainLogoImage: 'assets/icons/icon.png',
        sidebarItems: [
          SideBarItem(
            iconSelected: Icons.home_rounded,
            iconUnselected: Icons.home_outlined,
            text: 'home'.tr,
          ),
          SideBarItem(
            iconSelected: Icons.audiotrack_rounded,
            iconUnselected: Icons.audiotrack,
            text: 'songs'.tr,
          ),
          SideBarItem(
            iconSelected: Icons.library_music_rounded,
            iconUnselected: Icons.library_music_outlined,
            text: 'playlists'.tr,
          ),
          SideBarItem(
            iconSelected: Icons.album_rounded,
            iconUnselected: Icons.album_outlined,
            text: 'albums'.tr,
          ),
          SideBarItem(
            iconSelected: Icons.people_rounded,
            iconUnselected: Icons.people_outline,
            text: 'artists'.tr,
          ),
          SideBarItem(
            iconSelected: Icons.settings_rounded,
            iconUnselected: Icons.settings_outlined,
            text: 'settings'.tr,
          ),
        ],
      ),
    );
  }
}
