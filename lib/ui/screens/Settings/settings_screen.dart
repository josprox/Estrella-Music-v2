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
    final settingsController = Get.find<SettingsScreenController>();
    final authService = Get.find<AuthService>();
    final topPadding = context.isLandscape ? 50.0 : 90.0;
    final isDesktop = GetPlatform.isDesktop;
    return Padding(
      padding: isBottomNavActive
          ? EdgeInsets.only(left: 20, top: topPadding, right: 15)
          : EdgeInsets.only(top: topPadding, left: 5, right: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              S.current.settings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
              child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 200, top: 20),
            children: [
              Obx(
                () => settingsController.isNewVersionAvailable.value
                    ? Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, right: 10, bottom: 8.0),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              launchUrl(
                                Uri.parse(
                                  'https://github.com/anandnet/Harmony-Music/releases/latest',
                                ),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            tileColor: Theme.of(context).colorScheme.secondary,
                            contentPadding:
                                const EdgeInsets.only(left: 8, right: 10),
                            leading:
                                const CircleAvatar(child: Icon(Icons.download)),
                            title: Text(S.current.newVersionAvailable),
                            visualDensity: const VisualDensity(horizontal: -2),
                            subtitle: Text(
                              S.current.goToDownloadPage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              CustomExpansionTile(
                title: S.current.personalisation,
                icon: Icons.palette,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.language),
                    subtitle: Text(S.current.languageDes,
                        style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Obx(
                      () => DropdownButton(
                        menuMaxHeight: Get.height - 250,
                        dropdownColor: Theme.of(context).cardColor,
                        underline: const SizedBox.shrink(),
                        style: Theme.of(context).textTheme.titleSmall,
                        value: settingsController.currentAppLanguageCode.value,
                        items: langMap.entries
                            .map((lang) => DropdownMenuItem(
                                  value: lang.key,
                                  child: Text(lang.value),
                                ))
                            .whereType<DropdownMenuItem<String>>()
                            .toList(),
                        selectedItemBuilder: (context) =>
                            langMap.entries.map<Widget>((item) {
                          return Container(
                            alignment: Alignment.centerRight,
                            constraints: const BoxConstraints(minWidth: 50),
                            child: Text(
                              item.value,
                            ),
                          );
                        }).toList(),
                        onChanged: settingsController.setAppLanguage,
                      ),
                    ),
                  ),
                  ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.disableTransitionAnimation),
                      subtitle: Text(S.current.disableTransitionAnimationDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Obx(
                        () => CustSwitch(
                            value: settingsController
                                .isTransitionAnimationDisabled.isTrue,
                            onChanged:
                                settingsController.disableTransitionAnimation),
                      )),
                  ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.enableSlidableAction),
                      subtitle: Text(S.current.enableSlidableActionDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Obx(
                        () => CustSwitch(
                            value:
                                settingsController.slidableActionEnabled.isTrue,
                            onChanged: settingsController.toggleSlidableAction),
                      )),
                ],
              ),
              CustomExpansionTile(
                  title: S.current.content,
                  icon: Icons.music_video,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.setDiscoverContent),
                      subtitle: Obx(() => Text(
                          settingsController.discoverContentType.value == "QP"
                              ? S.current.quickpicks
                              : settingsController.discoverContentType.value ==
                                      "TMV"
                                  ? S.current.topmusicvideos
                                  : settingsController
                                              .discoverContentType.value ==
                                          "TR"
                                      ? S.current.trending
                                      : S.current.basedOnLast,
                          style: Theme.of(context).textTheme.bodyMedium)),
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) =>
                            const DiscoverContentSelectorDialog(),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.homeContentCount),
                      subtitle: Text(S.current.homeContentCountDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Obx(
                        () => DropdownButton(
                          dropdownColor: Theme.of(context).cardColor,
                          underline: const SizedBox.shrink(),
                          value: settingsController.noOfHomeScreenContent.value,
                          items: ([3, 5, 7, 9, 11])
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text("$e")))
                              .toList(),
                          onChanged: settingsController.setContentNumber,
                        ),
                      ),
                    ),
                    ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 5, right: 10),
                        title: Text(S.current.cacheHomeScreenData),
                        subtitle: Text(S.current.cacheHomeScreenDataDes,
                            style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Obx(
                          () => CustSwitch(
                              value:
                                  settingsController.cacheHomeScreenData.value,
                              onChanged:
                                  settingsController.toggleCacheHomeScreenData),
                        )),
                    ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 5, right: 10, top: 0),
                      title: Text(S.current.Piped),
                      subtitle: Text(S.current.linkPipedDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: TextButton(
                          child: Obx(() => Text(
                                settingsController.isLinkedWithPiped.value
                                    ? S.current.unLink
                                    : S.current.link,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontSize: 15),
                              )),
                          onPressed: () {
                            if (settingsController.isLinkedWithPiped.isFalse) {
                              showDialog(
                                context: context,
                                builder: (context) => const LinkPiped(),
                              ).whenComplete(
                                  () => Get.delete<PipedLinkedController>());
                            } else {
                              settingsController.unlinkPiped();
                            }
                          }),
                    ),
                    Obx(() => (settingsController.isLinkedWithPiped.isTrue)
                        ? ListTile(
                            contentPadding: const EdgeInsets.only(
                                left: 5, right: 10, top: 0),
                            title: Text(S.current.resetblacklistedplaylist),
                            subtitle: Text(S.current.resetblacklistedplaylistDes,
                                style: Theme.of(context).textTheme.bodyMedium),
                            trailing: TextButton(
                                child: Text(
                                  S.current.reset,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(fontSize: 15),
                                ),
                                onPressed: () async {
                                  await Get.find<LibraryPlaylistsController>()
                                      .resetBlacklistedPlaylist();
                                  ScaffoldMessenger.of(Get.context!)
                                      .showSnackBar(snackbar(Get.context!,
                                          S.current.blacklistPlstResetAlert,
                                          size: SanckBarSize.MEDIUM));
                                }),
                          )
                        : const SizedBox.shrink()),
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.clearImgCache),
                      subtitle: Text(
                        S.current.clearImgCacheDes,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      isThreeLine: true,
                      onTap: () {
                        settingsController.clearImagesCache().then((value) =>
                            ScaffoldMessenger.of(Get.context!).showSnackBar(
                                snackbar(Get.context!, S.current.clearImgCacheAlert,
                                    size: SanckBarSize.BIG)));
                      },
                    ),
                  ]),
              CustomExpansionTile(
                title: S.current.musicAndPlayback,
                icon: Icons.music_note,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.streamingQuality),
                    subtitle: Text(S.current.streamingQualityDes,
                        style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Obx(
                      () => DropdownButton(
                        dropdownColor: Theme.of(context).cardColor,
                        underline: const SizedBox.shrink(),
                        value: settingsController.streamingQuality.value,
                        items: [
                          DropdownMenuItem(
                              value: AudioQuality.Low, child: Text(S.current.low)),
                          DropdownMenuItem(
                            value: AudioQuality.High,
                            child: Text(S.current.high),
                          ),
                        ],
                        onChanged: settingsController.setStreamingQuality,
                      ),
                    ),
                  ),
                  if (GetPlatform.isAndroid)
                    ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 5, right: 10),
                        title: Text(S.current.loudnessNormalization),
                        subtitle: Text(S.current.loudnessNormalizationDes,
                            style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Obx(
                          () => CustSwitch(
                              value: settingsController
                                  .loudnessNormalizationEnabled.value,
                              onChanged: settingsController
                                  .toggleLoudnessNormalization),
                        )),
                  if (!isDesktop)
                    ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 5, right: 10),
                        title: Text(S.current.cacheSongs),
                        subtitle: Text(S.current.cacheSongsDes,
                            style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Obx(
                          () => CustSwitch(
                              value: settingsController.cacheSongs.value,
                              onChanged:
                                  settingsController.toggleCachingSongsValue),
                        )),
                  if (!isDesktop)
                    ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 5, right: 10),
                        title: Text(S.current.skipSilence),
                        subtitle: Text(S.current.skipSilenceDes,
                            style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Obx(
                          () => CustSwitch(
                              value:
                                  settingsController.skipSilenceEnabled.value,
                              onChanged: settingsController.toggleSkipSilence),
                        )),
                  if (isDesktop)
                    ListTile(
                        contentPadding:
                            const EdgeInsets.only(left: 5, right: 10),
                        title: Text(S.current.backgroundPlay),
                        subtitle: Text(S.current.backgroundPlayDes,
                            style: Theme.of(context).textTheme.bodyMedium),
                        trailing: Obx(
                          () => CustSwitch(
                              value: settingsController
                                  .backgroundPlayEnabled.value,
                              onChanged:
                                  settingsController.toggleBackgroundPlay),
                        )),
                  ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.keepScreenOnWhilePlaying),
                      subtitle: Text(S.current.keepScreenOnWhilePlayingDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Obx(
                        () => CustSwitch(
                            value: settingsController.keepScreenAwake.value,
                            onChanged:
                                settingsController.toggleKeepScreenAwake),
                      )),
                  ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.restoreLastPlaybackSession),
                      subtitle: Text(S.current.restoreLastPlaybackSessionDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Obx(
                        () => CustSwitch(
                            value:
                                settingsController.restorePlaybackSession.value,
                            onChanged: settingsController
                                .toggleRestorePlaybackSession),
                      )),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.autoOpenPlayer),
                    subtitle: Text(S.current.autoOpenPlayerDes,
                        style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Obx(
                      () => CustSwitch(
                          value: settingsController.autoOpenPlayer.value,
                          onChanged: settingsController.toggleAutoOpenPlayer),
                    ),
                  ),
                  if (!isDesktop)
                    ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 5, right: 10, top: 0),
                      title: Text(S.current.equalizer),
                      subtitle: Text(S.current.equalizerDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      onTap: () async {
                        try {
                          await Get.find<PlayerController>().openEqualizer();
                        } catch (e) {
                          printERROR(e);
                        }
                      },
                    ),
                  if (!isDesktop)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.stopMusicOnTaskClear),
                      subtitle: Text(S.current.stopMusicOnTaskClearDes,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: Obx(
                        () => CustSwitch(
                            value: settingsController
                                .stopPlyabackOnSwipeAway.value,
                            onChanged: settingsController
                                .toggleStopPlyabackOnSwipeAway),
                      ),
                    ),
                  GetPlatform.isAndroid
                      ? Obx(
                          () => ListTile(
                            contentPadding:
                                const EdgeInsets.only(left: 5, right: 10),
                            title: Text(S.current.ignoreBatOpt),
                            onTap: settingsController
                                    .isIgnoringBatteryOptimizations.isFalse
                                ? settingsController
                                    .enableIgnoringBatteryOptimizations
                                : null,
                            subtitle: Obx(() => RichText(
                                  text: TextSpan(
                                    text:
                                        "${S.current.status}: ${settingsController.isIgnoringBatteryOptimizations.isTrue ? S.current.enabled : S.current.disabled}\n",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(fontWeight: FontWeight.bold),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: S.current.ignoreBatOptDes,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium),
                                    ],
                                  ),
                                )),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
              CustomExpansionTile(
                title: S.current.download,
                icon: Icons.download,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.autoDownFavSong),
                    subtitle: Text(S.current.autoDownFavSongDes,
                        style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Obx(
                      () => CustSwitch(
                          value: settingsController
                              .autoDownloadFavoriteSongEnabled.value,
                          onChanged: settingsController
                              .toggleAutoDownloadFavoriteSong),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.downloadingFormat),
                    subtitle: Text(S.current.downloadingFormatDes,
                        style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Obx(
                      () => DropdownButton(
                        dropdownColor: Theme.of(context).cardColor,
                        underline: const SizedBox.shrink(),
                        value: settingsController.downloadingFormat.value,
                        items: const [
                          DropdownMenuItem(
                              value: "opus", child: Text("Opus/Ogg")),
                          DropdownMenuItem(
                            value: "m4a",
                            child: Text("M4a"),
                          ),
                        ],
                        onChanged: settingsController.changeDownloadingFormat,
                      ),
                    ),
                  ),
                  ListTile(
                    trailing: TextButton(
                      child: Text(
                        S.current.reset,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontSize: 15),
                      ),
                      onPressed: () {
                        settingsController.resetDownloadLocation();
                      },
                    ),
                    contentPadding:
                        const EdgeInsets.only(left: 5, right: 10, top: 0),
                    title: Text(S.current.downloadLocation),
                    subtitle: Obx(() => Text(
                        settingsController.isCurrentPathsupportDownDir
                            ? "In App storage directory"
                            : settingsController.downloadLocationPath.value,
                        style: Theme.of(context).textTheme.bodyMedium)),
                    onTap: () async {
                      settingsController.setDownloadLocation();
                    },
                  ),
                  if (GetPlatform.isAndroid)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(S.current.exportDowloadedFiles),
                      subtitle: Text(
                        S.current.exportDowloadedFilesDes,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      isThreeLine: true,
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => const ExportFileDialog(),
                      ).whenComplete(
                          () => Get.delete<ExportFileDialogController>()),
                    ),
                  if (GetPlatform.isAndroid)
                    ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 5, right: 10, top: 0),
                      title: Text(S.current.exportedFileLocation),
                      subtitle: Obx(() => Text(
                          settingsController.exportLocationPath.value,
                          style: Theme.of(context).textTheme.bodyMedium)),
                      onTap: () async {
                        settingsController.setExportedLocation();
                      },
                    ),
                ],
              ),
              CustomExpansionTile(
                title: "General",
                icon: Icons.settings,
                children: [
                   Obx(
                    () => ListTile(
                      contentPadding: const EdgeInsets.only(left: 5, right: 10),
                      title: Text(authService.displayName),
                      subtitle: Text(
                        authService.emailLabel,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: TextButton(
                        onPressed: settingsController.logoutUser,
                        child: const Text('Cerrar sesion'),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: const Text('Backup en la nube'),
                    subtitle: Text(
                      'Sube, restaura y administra respaldos desde el servidor.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const CloudBackupDialog(),
                    ).whenComplete(
                      () => Get.delete<CloudBackupDialogController>(),
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: const Text('Migrar desde Joss Music Kotlin'),
                    subtitle: Text(
                      'Importa playlists, canciones, albumes y artistas desde song.db o un backup legado.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const LegacyMusicMigrationDialog(),
                    ).whenComplete(
                      () => Get.delete<LegacyMusicMigrationDialogController>(),
                    ),
                  ),
                  const Divider(indent: 10, endIndent: 10, height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.backupAppData),
                    subtitle: Text(
                      S.current.backupSettingsAndPlaylistsDes,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    isThreeLine: true,
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const BackupDialog(),
                    ).whenComplete(
                        () => Get.delete<BackupDialogController>()),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.restoreAppData),
                    subtitle: Text(
                      S.current.restoreSettingsAndPlaylistsDes,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    isThreeLine: true,
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => const RestoreDialog(),
                    ).whenComplete(
                        () => Get.delete<RestoreDialogController>()),
                  ),
                  const Divider(indent: 10, endIndent: 10, height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.resetToDefault),
                    subtitle: Text(
                      S.current.resetToDefaultDes,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      settingsController
                          .resetAppSettingsToDefault()
                          .then((_) {
                        ScaffoldMessenger.of(Get.context!).showSnackBar(
                            snackbar(Get.context!, S.current.resetToDefaultMsg,
                                size: SanckBarSize.BIG,
                                duration: const Duration(seconds: 2)));
                      });
                    },
                  ),
                  const Divider(indent: 10, endIndent: 10, height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 5, right: 10),
                    title: Text(S.current.github),
                    subtitle: Text(
                      "${S.current.githubDes}${((Get.find<PlayerController>().playerPanelMinHeight.value) == 0 || !isBottomNavActive) ? "" : "\n\n${settingsController.currentVersion.value} ${S.current.by} josprox"}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    isThreeLine: true,
                    onTap: () {
                      launchUrl(
                        Uri.parse(
                          'https://github.com/josprox/Estrella-Music',
                        ),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    child: Column(
                      children: [
                        Text(
                          "Estrella Music",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Obx(() => Text(settingsController.currentVersion.value,
                            style: Theme.of(context).textTheme.titleMedium))
                      ],
                    ),
                  ),
                ],
              )
            ],
          )),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Obx(
              () => Text(
                "${settingsController.currentVersion.value} ${S.current.by} josprox",
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
            groupValue: value.runtimeType == ThemeType
                ? controller.themeModetype.value
                : controller.discoverContentType.value,
            onChanged: value.runtimeType == ThemeType
                ? controller.onThemeChange
                : controller.onContentChange),
        title: Text(label),
      ));
}
