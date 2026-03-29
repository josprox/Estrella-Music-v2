import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../player_controller.dart';
import '/ui/utils/theme_controller.dart';
import 'lyrics_widget.dart';

class FullLyricsPage extends StatelessWidget {
  const FullLyricsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PlayerController>();
    final themeCtrl = Get.find<ThemeController>();
    
    return Obx(() {
      final bgColor = themeCtrl.primaryColor.value;
      
      return Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Background gradient for depth
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40), // spacer
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                ctrl.currentSong.value?.title ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ctrl.currentSong.value?.artist ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lyrics content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LyricsWidget(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        isFull: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
