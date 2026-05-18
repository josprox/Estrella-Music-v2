import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/services/auth_service.dart';
import 'package:harmonymusic/utils/helper.dart';
import 'package:harmonymusic/utils/lang_mapping.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/common_dialog_widget.dart';
import '../../widgets/cust_switch.dart';
import '../../widgets/export_file_dialog.dart';
import '../../widgets/backup_dialog.dart';
import '../../widgets/cloud_backup_dialog.dart';
import '../../widgets/legacy_music_migration_dialog.dart';
import '../../widgets/restore_dialog.dart';
import '../Library/library_controller.dart';
import '../../widgets/snackbar.dart';
import '/ui/widgets/link_piped.dart';
import '/services/music_service.dart';
import '/ui/player/player_controller.dart';
import '/ui/utils/theme_controller.dart';
import 'components/custom_expansion_tile.dart';
import 'settings_screen_controller.dart';
import 'package:harmonymusic/generated/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.isBottomNavActive = false});
  final bool isBottomNavActive;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SettingsScreenController>();
    final auth = Get.find<AuthService>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop = GetPlatform.isDesktop;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final topPad = isBottomNavActive
        ? statusBarHeight
        : (context.isLandscape ? 50.0 : 90.0);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: topPad)),

        // ── Header ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.settings_rounded, color: cs.onPrimaryContainer, size: 24),
                ),
                const SizedBox(width: 14),
                Text(S.current.settings, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),

        // ── Update banner ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Obx(() => ctrl.isNewVersionAvailable.value
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Card(
                    color: cs.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      onTap: () => launchUrl(Uri.parse('https://github.com/anandnet/Harmony-Music/releases/latest'), mode: LaunchMode.externalApplication),
                      leading: Icon(Icons.download_rounded, color: cs.onPrimaryContainer),
                      title: Text(S.current.newVersionAvailable, style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                      subtitle: Text(S.current.goToDownloadPage, style: TextStyle(color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                      trailing: Icon(Icons.open_in_new_rounded, color: cs.onPrimaryContainer),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ),

        // ── Sections ──────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // 1. Personalización
              CustomExpansionTile(
                title: S.current.personalisation,
                icon: Icons.palette_rounded,
                children: [
                  SettingsTile(
                    title: S.current.language,
                    subtitle: S.current.languageDes,
                    leadingIcon: Icons.translate_rounded,
                    trailing: Obx(() => DropdownButton(
                      menuMaxHeight: Get.height - 250,
                      dropdownColor: cs.surfaceContainerHigh,
                      underline: const SizedBox.shrink(),
                      style: tt.titleSmall,
                      value: ctrl.currentAppLanguageCode.value,
                      items: langMap.entries.map((l) => DropdownMenuItem(value: l.key, child: Text(l.value))).whereType<DropdownMenuItem<String>>().toList(),
                      selectedItemBuilder: (ctx) => langMap.entries.map<Widget>((e) => Container(
                        alignment: Alignment.centerRight,
                        constraints: const BoxConstraints(minWidth: 50),
                        child: Text(e.value),
                      )).toList(),
                      onChanged: ctrl.setAppLanguage,
                    )),
                  ),
                  SettingsTile(
                    title: S.current.themeMode,
                    subtitle: S.current.setDiscoverContent,
                    leadingIcon: Icons.dark_mode_rounded,
                    onTap: () => showDialog(context: context, builder: (_) => const ThemeSelectorDialog()),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  SettingsTile(
                    title: S.current.disableTransitionAnimation,
                    subtitle: S.current.disableTransitionAnimationDes,
                    leadingIcon: Icons.animation_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.isTransitionAnimationDisabled.isTrue, onChanged: ctrl.disableTransitionAnimation)),
                  ),
                  SettingsTile(
                    title: S.current.enableSlidableAction,
                    subtitle: S.current.enableSlidableActionDes,
                    leadingIcon: Icons.swipe_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.slidableActionEnabled.isTrue, onChanged: ctrl.toggleSlidableAction)),
                  ),
                ],
              ),

              // 2. Contenido
              CustomExpansionTile(
                title: S.current.content,
                icon: Icons.music_video_rounded,
                children: [
                  SettingsTile(
                    title: S.current.setDiscoverContent,
                    leadingIcon: Icons.explore_rounded,
                    subtitle: null,
                    onTap: () => showDialog(context: context, builder: (_) => const DiscoverContentSelectorDialog()),
                    trailing: Obx(() => Text(
                      ctrl.discoverContentType.value == "QP" ? S.current.quickpicks
                        : ctrl.discoverContentType.value == "TMV" ? S.current.topmusicvideos
                        : ctrl.discoverContentType.value == "TR" ? S.current.trending
                        : S.current.basedOnLast,
                      style: tt.bodySmall?.copyWith(color: cs.primary),
                    )),
                  ),
                  SettingsTile(
                    title: S.current.homeContentCount,
                    subtitle: S.current.homeContentCountDes,
                    leadingIcon: Icons.grid_view_rounded,
                    trailing: Obx(() => DropdownButton(
                      dropdownColor: cs.surfaceContainerHigh,
                      underline: const SizedBox.shrink(),
                      value: ctrl.noOfHomeScreenContent.value,
                      items: [3, 5, 7, 9, 11].map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                      onChanged: ctrl.setContentNumber,
                    )),
                  ),
                  SettingsTile(
                    title: S.current.cacheHomeScreenData,
                    subtitle: S.current.cacheHomeScreenDataDes,
                    leadingIcon: Icons.cached_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.cacheHomeScreenData.value, onChanged: ctrl.toggleCacheHomeScreenData)),
                  ),
                  SettingsTile(
                    title: S.current.Piped,
                    subtitle: S.current.linkPipedDes,
                    leadingIcon: Icons.sync_alt_rounded,
                    trailing: TextButton(
                      onPressed: () {
                        if (ctrl.isLinkedWithPiped.isFalse) {
                          showDialog(context: context, builder: (_) => const LinkPiped()).whenComplete(() => Get.delete<PipedLinkedController>());
                        } else { ctrl.unlinkPiped(); }
                      },
                      child: Obx(() => Text(ctrl.isLinkedWithPiped.value ? S.current.unLink : S.current.link)),
                    ),
                  ),
                  Obx(() => ctrl.isLinkedWithPiped.isTrue
                    ? SettingsTile(
                        title: S.current.resetblacklistedplaylist,
                        subtitle: S.current.resetblacklistedplaylistDes,
                        leadingIcon: Icons.block_rounded,
                        trailing: TextButton(
                          onPressed: () async {
                            await Get.find<LibraryPlaylistsController>().resetBlacklistedPlaylist();
                            ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(Get.context!, S.current.blacklistPlstResetAlert, size: SanckBarSize.MEDIUM));
                          },
                          child: Text(S.current.reset),
                        ),
                      )
                    : const SizedBox.shrink()),
                  SettingsTile(
                    title: S.current.clearImgCache,
                    subtitle: S.current.clearImgCacheDes,
                    leadingIcon: Icons.image_not_supported_rounded,
                    isThreeLine: true,
                    onTap: () => ctrl.clearImagesCache().then((_) => ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(Get.context!, S.current.clearImgCacheAlert, size: SanckBarSize.BIG))),
                  ),
                ],
              ),

              // 3. Música y reproducción
              CustomExpansionTile(
                title: S.current.musicAndPlayback,
                icon: Icons.music_note_rounded,
                children: [
                  SettingsTile(
                    title: S.current.streamingQuality,
                    subtitle: S.current.streamingQualityDes,
                    leadingIcon: Icons.high_quality_rounded,
                    trailing: Obx(() => DropdownButton(
                      dropdownColor: cs.surfaceContainerHigh,
                      underline: const SizedBox.shrink(),
                      value: ctrl.streamingQuality.value,
                      items: [
                        DropdownMenuItem(value: AudioQuality.Low, child: Text(S.current.low)),
                        DropdownMenuItem(value: AudioQuality.High, child: Text(S.current.high)),
                      ],
                      onChanged: ctrl.setStreamingQuality,
                    )),
                  ),
                  if (GetPlatform.isAndroid) SettingsTile(
                    title: S.current.loudnessNormalization,
                    subtitle: S.current.loudnessNormalizationDes,
                    leadingIcon: Icons.equalizer_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.loudnessNormalizationEnabled.value, onChanged: ctrl.toggleLoudnessNormalization)),
                  ),
                  if (!isDesktop) SettingsTile(
                    title: S.current.cacheSongs,
                    subtitle: S.current.cacheSongsDes,
                    leadingIcon: Icons.save_alt_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.cacheSongs.value, onChanged: ctrl.toggleCachingSongsValue)),
                  ),
                  if (!isDesktop) SettingsTile(
                    title: S.current.skipSilence,
                    subtitle: S.current.skipSilenceDes,
                    leadingIcon: Icons.fast_forward_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.skipSilenceEnabled.value, onChanged: ctrl.toggleSkipSilence)),
                  ),
                  if (isDesktop) SettingsTile(
                    title: S.current.backgroundPlay,
                    subtitle: S.current.backgroundPlayDes,
                    leadingIcon: Icons.play_circle_outline_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.backgroundPlayEnabled.value, onChanged: ctrl.toggleBackgroundPlay)),
                  ),
                  SettingsTile(
                    title: S.current.keepScreenOnWhilePlaying,
                    subtitle: S.current.keepScreenOnWhilePlayingDes,
                    leadingIcon: Icons.screen_lock_rotation_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.keepScreenAwake.value, onChanged: ctrl.toggleKeepScreenAwake)),
                  ),
                  SettingsTile(
                    title: S.current.restoreLastPlaybackSession,
                    subtitle: S.current.restoreLastPlaybackSessionDes,
                    leadingIcon: Icons.restore_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.restorePlaybackSession.value, onChanged: ctrl.toggleRestorePlaybackSession)),
                  ),
                  SettingsTile(
                    title: S.current.autoOpenPlayer,
                    subtitle: S.current.autoOpenPlayerDes,
                    leadingIcon: Icons.open_in_full_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.autoOpenPlayer.value, onChanged: ctrl.toggleAutoOpenPlayer)),
                  ),
                  if (!isDesktop) SettingsTile(
                    title: S.current.equalizer,
                    subtitle: S.current.equalizerDes,
                    leadingIcon: Icons.tune_rounded,
                    onTap: () async { try { await Get.find<PlayerController>().openEqualizer(); } catch (e) { printERROR(e); } },
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  if (!isDesktop) SettingsTile(
                    title: S.current.stopMusicOnTaskClear,
                    subtitle: S.current.stopMusicOnTaskClearDes,
                    leadingIcon: Icons.stop_circle_outlined,
                    trailing: Obx(() => CustSwitch(value: ctrl.stopPlyabackOnSwipeAway.value, onChanged: ctrl.toggleStopPlyabackOnSwipeAway)),
                  ),
                  if (GetPlatform.isAndroid) Obx(() => SettingsTile(
                    title: S.current.ignoreBatOpt,
                    leadingIcon: Icons.battery_saver_rounded,
                    isThreeLine: true,
                    onTap: ctrl.isIgnoringBatteryOptimizations.isFalse ? ctrl.enableIgnoringBatteryOptimizations : null,
                    subtitle: "${S.current.status}: ${ctrl.isIgnoringBatteryOptimizations.isTrue ? S.current.enabled : S.current.disabled}\n${S.current.ignoreBatOptDes}",
                  )),

                ],
              ),

              // 4. Descargas
              CustomExpansionTile(
                title: S.current.download,
                icon: Icons.download_rounded,
                children: [
                  SettingsTile(
                    title: S.current.autoDownFavSong,
                    subtitle: S.current.autoDownFavSongDes,
                    leadingIcon: Icons.favorite_rounded,
                    trailing: Obx(() => CustSwitch(value: ctrl.autoDownloadFavoriteSongEnabled.value, onChanged: ctrl.toggleAutoDownloadFavoriteSong)),
                  ),
                  SettingsTile(
                    title: S.current.downloadingFormat,
                    subtitle: S.current.downloadingFormatDes,
                    leadingIcon: Icons.audio_file_rounded,
                    trailing: Obx(() => DropdownButton(
                      dropdownColor: cs.surfaceContainerHigh,
                      underline: const SizedBox.shrink(),
                      value: ctrl.downloadingFormat.value,
                      items: const [
                        DropdownMenuItem(value: "opus", child: Text("Opus/Ogg")),
                        DropdownMenuItem(value: "m4a", child: Text("M4a")),
                      ],
                      onChanged: ctrl.changeDownloadingFormat,
                    )),
                  ),
                  SettingsTile(
                    title: S.current.downloadLocation,
                    leadingIcon: Icons.folder_rounded,
                    subtitle: null,
                    onTap: ctrl.setDownloadLocation,
                    trailing: TextButton(onPressed: ctrl.resetDownloadLocation, child: Text(S.current.reset)),
                  ),
                  if (GetPlatform.isAndroid) SettingsTile(
                    title: S.current.exportDowloadedFiles,
                    subtitle: S.current.exportDowloadedFilesDes,
                    leadingIcon: Icons.ios_share_rounded,
                    isThreeLine: true,
                    onTap: () => showDialog(context: context, builder: (_) => const ExportFileDialog()).whenComplete(() => Get.delete<ExportFileDialogController>()),
                  ),
                  if (GetPlatform.isAndroid) SettingsTile(
                    title: S.current.exportedFileLocation,
                    leadingIcon: Icons.drive_folder_upload_rounded,
                    subtitle: null,
                    onTap: ctrl.setExportedLocation,
                    trailing: Obx(() => Text(ctrl.exportLocationPath.value, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                  ),
                ],
              ),

              // 5. General / Cuenta
              CustomExpansionTile(
                title: S.current.settings_general_section,
                icon: Icons.manage_accounts_rounded,
                children: [
                  // Cuenta
                  Obx(() => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : '?',
                          style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(auth.displayName, style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(auth.emailLabel, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    trailing: FilledButton.tonal(
                      onPressed: ctrl.logoutUser,
                      child: Text(S.current.settings_logout),
                    ),
                  )),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingsTile(
                    title: S.current.settings_cloud_backup,
                    subtitle: S.current.settings_cloud_backup_desc,
                    leadingIcon: Icons.cloud_sync_rounded,
                    onTap: () => showDialog(context: context, builder: (_) => const CloudBackupDialog()).whenComplete(() => Get.delete<CloudBackupDialogController>()),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  SettingsTile(
                    title: S.current.settings_migration_title,
                    subtitle: S.current.settings_migration_desc,
                    leadingIcon: Icons.move_to_inbox_rounded,
                    onTap: () => showDialog(context: context, builder: (_) => const LegacyMusicMigrationDialog()).whenComplete(() => Get.delete<LegacyMusicMigrationDialogController>()),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingsTile(
                    title: S.current.backupAppData,
                    subtitle: S.current.backupSettingsAndPlaylistsDes,
                    leadingIcon: Icons.backup_rounded,
                    isThreeLine: true,
                    onTap: () => showDialog(context: context, builder: (_) => const BackupDialog()).whenComplete(() => Get.delete<BackupDialogController>()),
                  ),
                  SettingsTile(
                    title: S.current.restoreAppData,
                    subtitle: S.current.restoreSettingsAndPlaylistsDes,
                    leadingIcon: Icons.settings_backup_restore_rounded,
                    isThreeLine: true,
                    onTap: () => showDialog(context: context, builder: (_) => const RestoreDialog()).whenComplete(() => Get.delete<RestoreDialogController>()),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingsTile(
                    title: S.current.resetToDefault,
                    subtitle: S.current.resetToDefaultDes,
                    leadingIcon: Icons.restart_alt_rounded,
                    onTap: () => ctrl.resetAppSettingsToDefault().then((_) => ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(Get.context!, S.current.resetToDefaultMsg, size: SanckBarSize.BIG, duration: const Duration(seconds: 2)))),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SettingsTile(
                    title: S.current.github,
                    subtitle: S.current.githubDes,
                    leadingIcon: Icons.code_rounded,
                    isThreeLine: true,
                    onTap: () => launchUrl(Uri.parse('https://github.com/josprox/Estrella-Music'), mode: LaunchMode.externalApplication),
                    trailing: const Icon(Icons.open_in_new_rounded),
                  ),
                ],
              ),

              // Footer con versión
              const SizedBox(height: 8),
              Obx(() => Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset('assets/icons/icon.png', width: 36, height: 36),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estrella Music', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                            Text(ctrl.currentVersion.value, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${ctrl.currentVersion.value} • ${S.current.developedBy}",
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.current.copyrightNotice,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    textAlign: TextAlign.center,
                  ),
                ],
              )),
              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
      ),
    );
  }

}

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    return CommonDialog(
      child: Container(
        height: 300,
        //color: Theme.of(context).cardColor,
        padding: const EdgeInsets.only(top: 30, left: 5, right: 30, bottom: 10),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.current.themeMode,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          radioWidget(
            label: S.current.dynamic,
            controller: settingsController,
            value: ThemeType.dynamic,
          ),
          radioWidget(
              label: S.current.systemDefault,
              controller: settingsController,
              value: ThemeType.system),
          radioWidget(
              label: S.current.dark,
              controller: settingsController,
              value: ThemeType.dark),
          radioWidget(
              label: S.current.light,
              controller: settingsController,
              value: ThemeType.light),
          Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(S.current.cancel),
                ),
                onTap: () => Navigator.of(context).pop(),
              ))
        ]),
      ),
    );
  }
}

class DiscoverContentSelectorDialog extends StatelessWidget {
  const DiscoverContentSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsScreenController>();
    return CommonDialog(
      child: Container(
        height: 300,
        //color: Theme.of(context).cardColor,
        padding: const EdgeInsets.only(top: 30, left: 5, right: 30, bottom: 10),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, bottom: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.current.setDiscoverContent,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  radioWidget(
                      label: S.current.quickpicks,
                      controller: settingsController,
                      value: "QP"),
                  radioWidget(
                      label: S.current.topmusicvideos,
                      controller: settingsController,
                      value: "TMV"),
                  radioWidget(
                      label: S.current.trending,
                      controller: settingsController,
                      value: "TR"),
                  radioWidget(
                      label: S.current.basedOnLast,
                      controller: settingsController,
                      value: "BOLI"),
                ],
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
          Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(S.current.cancel),
                ),
                onTap: () => Navigator.of(context).pop(),
              ))
        ]),
      ),
    );
  }
}

Widget radioWidget(
    {required String label,
    required SettingsScreenController controller,
    required value}) {
  return Obx(() => ListTile(
        visualDensity: const VisualDensity(vertical: -4),
        onTap: () {
          if (value.runtimeType == ThemeType) {
            controller.onThemeChange(value);
          } else {
            controller.onContentChange(value);
            Navigator.of(Get.context!).pop();
          }
        },
        leading: Radio(
            value: value,
            // ignore: deprecated_member_use
            groupValue: value.runtimeType == ThemeType
                ? controller.themeModetype.value
                : controller.discoverContentType.value,
            // ignore: deprecated_member_use
            onChanged: value.runtimeType == ThemeType
                ? controller.onThemeChange
                : controller.onContentChange),
        title: Text(label),
      ));
}
