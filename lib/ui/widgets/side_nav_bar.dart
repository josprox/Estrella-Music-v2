import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';
import '/ui/theme/app_colors.dart';
import 'package:harmonymusic/generated/l10n.dart';

class SideNavBar extends StatefulWidget {
  const SideNavBar({super.key});

  @override
  State<SideNavBar> createState() => _SideNavBarState();
}

class _SideNavBarState extends State<SideNavBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileOrTabScreen = size.width < 600;
    final homeScreenController = Get.find<HomeScreenController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In portrait tablet/mobile, we don't expand on hover to avoid blocking content
    final bool isExpanded = _isHovered && !isMobileOrTabScreen;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isExpanded ? 240.0 : 76.0,
        height: size.height,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                    .withValues(alpha: 0.65),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
                    width: 0.8,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Logo / Header
                  _buildHeader(isExpanded, isDark),
                  const SizedBox(height: 16),
                  // Nav Items
                  Expanded(
                    child: Obx(
                      () => ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _SideBarNavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: S.current.home,
                            isSelected: homeScreenController.tabIndex.value == 0,
                            isExpanded: isExpanded,
                            onTap: () => homeScreenController.onSideBarTabSelected(0),
                          ),
                          const SizedBox(height: 8),
                          _SideBarNavItem(
                            icon: Icons.audiotrack_outlined,
                            activeIcon: Icons.audiotrack_rounded,
                            label: S.current.songs,
                            isSelected: homeScreenController.tabIndex.value == 1,
                            isExpanded: isExpanded,
                            onTap: () => homeScreenController.onSideBarTabSelected(1),
                          ),
                          const SizedBox(height: 8),
                          _SideBarNavItem(
                            icon: Icons.library_music_outlined,
                            activeIcon: Icons.library_music_rounded,
                            label: S.current.playlists,
                            isSelected: homeScreenController.tabIndex.value == 2,
                            isExpanded: isExpanded,
                            onTap: () => homeScreenController.onSideBarTabSelected(2),
                          ),
                          const SizedBox(height: 8),
                          _SideBarNavItem(
                            icon: Icons.album_outlined,
                            activeIcon: Icons.album_rounded,
                            label: S.current.albums,
                            isSelected: homeScreenController.tabIndex.value == 3,
                            isExpanded: isExpanded,
                            onTap: () => homeScreenController.onSideBarTabSelected(3),
                          ),
                          const SizedBox(height: 8),
                          _SideBarNavItem(
                            icon: Icons.people_outline,
                            activeIcon: Icons.people_rounded,
                            label: S.current.artists,
                            isSelected: homeScreenController.tabIndex.value == 4,
                            isExpanded: isExpanded,
                            onTap: () => homeScreenController.onSideBarTabSelected(4),
                          ),
                          const SizedBox(height: 8),
                          _SideBarNavItem(
                            icon: Icons.settings_outlined,
                            activeIcon: Icons.settings_rounded,
                            label: S.current.settings,
                            isSelected: homeScreenController.tabIndex.value == 5,
                            isExpanded: isExpanded,
                            onTap: () => homeScreenController.onSideBarTabSelected(5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer
                  _buildFooter(isExpanded, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isExpanded, bool isDark) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icons/icon.png',
            height: 36,
            width: 36,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.music_note_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Estrella Music',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..shader = AppColors.primaryGradientDark.createShader(
                      const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                    ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool isExpanded, bool isDark) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: isExpanded
          ? Text(
              'v2.3.2',
              style: TextStyle(
                color: (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _SideBarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SideBarNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_SideBarNavItem> createState() => _SideBarNavItemState();
}

class _SideBarNavItemState extends State<_SideBarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Colors
    final activeBgColor = colorScheme.primaryContainer.withValues(alpha: 0.85);
    final activeTextColor = colorScheme.onPrimaryContainer;
    final hoverBgColor = colorScheme.primary.withValues(alpha: 0.08);
    final inactiveTextColor = colorScheme.onSurfaceVariant;

    final textColor = widget.isSelected
        ? activeTextColor
        : _isHovered
            ? colorScheme.primary
            : inactiveTextColor;

    final iconColor = widget.isSelected
        ? activeTextColor
        : _isHovered
            ? colorScheme.primary
            : inactiveTextColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isSelected
                ? activeBgColor
                : _isHovered
                    ? hoverBgColor
                    : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Animated Icon
              AnimatedScale(
                scale: widget.isSelected || _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isSelected ? widget.activeIcon : widget.icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              // Label (only shown/faded when expanded)
              if (widget.isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: widget.isExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
