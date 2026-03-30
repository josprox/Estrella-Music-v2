import 'services/music_service.dart';
import 'package:get/get.dart';

void main() async {
  Get.put(MusicServices());
  final service = Get.find<MusicServices>();
  try {
    print('Calling explore...');
    final exploreRes = await service.explore();
    print('Explore returned: ${exploreRes.length} items');
  } catch(e, st) {
    print('Explore failed: $e\n$st');
  }
}
