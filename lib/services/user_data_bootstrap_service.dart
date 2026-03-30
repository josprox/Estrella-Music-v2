import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../utils/helper.dart';
import 'app_backup_service.dart';
import 'auth_service.dart';
import 'cloud_backup_service.dart';
import 'legacy_music_migration_service.dart';

class UserDataBootstrapService extends GetxService {
  final isPreparing = false.obs;
  final statusMessage = 'Preparando tu biblioteca...'.obs;
  final lastError = ''.obs;
  final willReplaceLocalData = false.obs;

  String? _preparedUserKey;
  String? _attemptedUserKey;
  Future<void>? _runningTask;

  AuthService get _authService => Get.find<AuthService>();
  CloudBackupService get _cloudBackupService => Get.find<CloudBackupService>();
  LegacyMusicMigrationService get _legacyMigrationService =>
      Get.find<LegacyMusicMigrationService>();
  AppBackupService get _appBackupService => Get.find<AppBackupService>();

  String? get currentUserKey {
    final user = _authService.userProfile.value;
    if (user == null) return null;
    final rawKey = user['email']?.toString().trim().isNotEmpty == true
        ? user['email'].toString().trim().toLowerCase()
        : user['id']?.toString().trim().isNotEmpty == true
            ? user['id'].toString().trim()
            : user['username']?.toString().trim();
    if (rawKey == null || rawKey.isEmpty) {
      return null;
    }
    return rawKey.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  }

  bool get needsBootstrapForCurrentUser {
    final userKey = currentUserKey;
    if (!_authService.isAuthenticated.value || userKey == null) {
      return false;
    }
    if (isPreparing.value) {
      return false;
    }
    return _preparedUserKey != userKey && _attemptedUserKey != userKey;
  }

  void resetRuntimeState() {
    if (isPreparing.value) {
      return;
    }
    _preparedUserKey = null;
    _attemptedUserKey = null;
    lastError.value = '';
    willReplaceLocalData.value = false;
    statusMessage.value = 'Preparando tu biblioteca...';
  }

  Future<void> prepareForAuthenticatedUser() async {
    final userKey = currentUserKey;
    if (!_authService.isAuthenticated.value || userKey == null) {
      return;
    }
    if (_preparedUserKey == userKey || _attemptedUserKey == userKey) {
      return;
    }
    if (_runningTask != null) {
      return _runningTask!;
    }

    _attemptedUserKey = userKey;
    _runningTask = _runBootstrap(userKey);
    try {
      await _runningTask;
    } finally {
      _runningTask = null;
    }
  }

  Future<void> _runBootstrap(String userKey) async {
    isPreparing.value = true;
    lastError.value = '';
    willReplaceLocalData.value = false;

    try {
      statusMessage.value = 'Revisando tu biblioteca local...';
      final hasLocalData = await _hasMeaningfulLocalData();

      statusMessage.value = 'Buscando backups de tu cuenta...';
      final latestAppBackup = await _getLatestBackup(
        CloudBackupService.defaultAppName,
      );
      if (latestAppBackup != null) {
        if (_wasBackupAlreadyProcessed(
              userKey: userKey,
              source: latestAppBackup.appName,
              fileId: latestAppBackup.fileId,
            ) &&
            hasLocalData) {
          statusMessage.value = 'Tu backup ya estaba sincronizado.';
          _preparedUserKey = userKey;
          return;
        }

        willReplaceLocalData.value = hasLocalData;
        statusMessage.value = hasLocalData
            ? 'Encontramos un backup de tu cuenta. Reemplazaremos los datos locales.'
            : 'Restaurando tu backup de Estrella Music...';
        final bytes =
            await _cloudBackupService.downloadBackupBytes(latestAppBackup);
        statusMessage.value = 'Restaurando tu backup de Estrella Music...';
        await _appBackupService.restoreBackupBytes(
          bytes,
          clearExistingMediaAssets: true,
          reopenCoreBoxes: true,
        );
        await _persistProcessedBackup(
          userKey: userKey,
          source: latestAppBackup.appName,
          fileId: latestAppBackup.fileId,
          fileName: latestAppBackup.fileName,
        );
        _applyLocaleFromAppPrefs();
        statusMessage.value = 'Tu biblioteca quedo restaurada.';
        _preparedUserKey = userKey;
        return;
      }

      final latestLegacyBackup = await _getLatestBackup(
        CloudBackupService.legacyMusicAppName,
      );
      if (latestLegacyBackup != null) {
        if (_wasBackupAlreadyProcessed(
              userKey: userKey,
              source: latestLegacyBackup.appName,
              fileId: latestLegacyBackup.fileId,
            ) &&
            hasLocalData) {
          statusMessage.value = 'Tu migracion ya estaba aplicada.';
          _preparedUserKey = userKey;
          return;
        }

        willReplaceLocalData.value = hasLocalData;
        statusMessage.value = 'Descargando tu respaldo de Joss Music...';
        final bytes =
            await _cloudBackupService.downloadBackupBytes(latestLegacyBackup);
        if (hasLocalData) {
          statusMessage.value =
              'Borrando los datos locales antes de migrar tu respaldo...';
          await _appBackupService.clearLocalMusicData();
        }

        statusMessage.value = 'Migrando tu respaldo de Joss Music...';
        await _legacyMigrationService.importFromBackupBytes(
          bytes,
          sourceName: latestLegacyBackup.fileName,
        );
        await _persistProcessedBackup(
          userKey: userKey,
          source: latestLegacyBackup.appName,
          fileId: latestLegacyBackup.fileId,
          fileName: latestLegacyBackup.fileName,
        );
        statusMessage.value = 'Tus datos fueron migrados a Estrella Music.';
        _preparedUserKey = userKey;
        return;
      }

      statusMessage.value = hasLocalData
          ? 'No encontramos backups remotos. Conservamos tus datos locales.'
          : 'No encontramos backups remotos. Entrando...';
      _preparedUserKey = userKey;
    } catch (e) {
      lastError.value = e.toString().replaceFirst('Bad state: ', '');
      statusMessage.value = willReplaceLocalData.value
          ? 'No se pudo completar la restauracion automatica. Entrando a la app.'
          : 'No se pudo recuperar tu backup. Entrando...';
      printERROR('Bootstrap de usuario fallo: $e');
      _preparedUserKey = userKey;
    } finally {
      isPreparing.value = false;
    }
  }

  Future<CloudBackupFile?> _getLatestBackup(String appName) async {
    final backups = await _cloudBackupService.listBackups(appName: appName);
    return backups.isEmpty ? null : backups.first;
  }

  Future<bool> _hasMeaningfulLocalData() async {
    final boxesToCheck = <String>[
      'LibraryPlaylists',
      'LibraryAlbums',
      'LibraryArtists',
      'LIBFAV',
      'LIBRP',
      'SongDownloads',
    ];

    for (final boxName in boxesToCheck) {
      final wasOpen = Hive.isBoxOpen(boxName);
      final box = wasOpen ? Hive.box(boxName) : await Hive.openBox(boxName);
      final hasData = box.isNotEmpty;
      if (!wasOpen) {
        await box.close();
      }
      if (hasData) {
        return true;
      }
    }
    return false;
  }

  bool _wasBackupAlreadyProcessed({
    required String userKey,
    required String source,
    required String fileId,
  }) {
    final raw = Hive.box('AppPrefs').get(_bootstrapStateKey(userKey));
    if (raw is! Map) {
      return false;
    }
    final state = raw.map((key, value) => MapEntry(key.toString(), value));
    return state['source']?.toString() == source &&
        state['fileId']?.toString() == fileId;
  }

  Future<void> _persistProcessedBackup({
    required String userKey,
    required String source,
    required String fileId,
    required String fileName,
  }) async {
    await Hive.box('AppPrefs').put(
      _bootstrapStateKey(userKey),
      {
        'source': source,
        'fileId': fileId,
        'fileName': fileName,
        'processedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  String _bootstrapStateKey(String userKey) => 'bootstrap_state_$userKey';

  void _applyLocaleFromAppPrefs() {
    if (!Hive.isBoxOpen('AppPrefs')) {
      return;
    }
    final appPrefs = Hive.box('AppPrefs');
    final autoLanguage = appPrefs.get('autoLanguage', defaultValue: true);
    final languageCode = appPrefs.get('currentAppLanguageCode');
    if (!autoLanguage &&
        languageCode is String &&
        languageCode.trim().isNotEmpty) {
      Get.updateLocale(Locale(languageCode));
    }
  }
}
