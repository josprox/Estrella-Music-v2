import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/legacy_music_migration_service.dart';
import 'common_dialog_widget.dart';
import 'snackbar.dart';

class LegacyMusicMigrationDialog extends StatelessWidget {
  const LegacyMusicMigrationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LegacyMusicMigrationDialogController());
    return CommonDialog(
      maxWidth: 640,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Migrar desde Joss Music Kotlin',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Selecciona el `song.db` de la app anterior o un backup `.backup`. La migración crea una playlist llamada "Biblioteca migrada", conserva favoritos, playlists, álbumes y artistas compatibles con esta app.',
            ),
            const SizedBox(height: 14),
            Obx(
              () => controller.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(controller.errorMessage.value),
                    ),
            ),
            Obx(
              () => controller.isImporting.isTrue
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: LinearProgressIndicator(),
                    )
                  : const SizedBox(height: 8),
            ),
            Obx(
              () => controller.summary.value == null
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.summaryText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.isImporting.isTrue
                        ? null
                        : () => controller.importLegacyData(context),
                    icon: const Icon(Icons.import_export),
                    label: const Text('Seleccionar archivo e importar'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LegacyMusicMigrationDialogController extends GetxController {
  final isImporting = false.obs;
  final errorMessage = ''.obs;
  final summary = Rxn<LegacyMigrationSummary>();

  LegacyMusicMigrationService get _migrationService =>
      Get.find<LegacyMusicMigrationService>();

  String get summaryText {
    final currentSummary = summary.value;
    if (currentSummary == null) return '';
    return 'Migración completada desde ${currentSummary.sourceName}.\n'
        'Playlists: ${currentSummary.playlistCount}\n'
        'Canciones: ${currentSummary.songCount}\n'
        'Favoritos: ${currentSummary.favoriteCount}\n'
        'Álbumes: ${currentSummary.albumCount}\n'
        'Artistas: ${currentSummary.artistCount}';
  }

  Future<void> importLegacyData(BuildContext context) async {
    isImporting.value = true;
    errorMessage.value = '';
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['db', 'backup'],
        dialogTitle: 'Selecciona song.db o un backup .backup',
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      summary.value =
          await _migrationService.importFromPath(result.files.single.path!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snackbar(
            context,
            'Migración completada correctamente.',
            size: SanckBarSize.MEDIUM,
          ),
        );
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Bad state: ', '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          snackbar(context, errorMessage.value, size: SanckBarSize.BIG),
        );
      }
    } finally {
      isImporting.value = false;
    }
  }
}
