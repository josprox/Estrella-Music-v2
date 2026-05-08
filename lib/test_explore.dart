import 'package:flutter/material.dart';

import 'services/music_service.dart';
import 'package:get/get.dart';

void main() async {
  Get.put(MusicServices());
  final service = Get.find<MusicServices>();
  try {
    debugPrint('Calling explore...');
    final exploreRes = await service.explore();
    debugPrint('Explore returned: ${exploreRes.length} items');
  } catch (e, st) {
    debugPrint('Explore failed: $e\n$st');
  }
}
