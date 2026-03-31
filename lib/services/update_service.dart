import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static Future<bool> checkForUpdate() async {
    try {
      final String? checkUpdates = dotenv.env["UPDATE_CHECK_URL"];
      if (checkUpdates == null) {
        if (kDebugMode) print("Update check URL not found in .env");
        return false;
      }

      final dio = Dio();
      final response = await dio.get(checkUpdates);
      
      if (response.statusCode != 200) return false;

      final data = response.data;
      if (data == null || data['Version'] == null) return false;
      
      String latestVersion = data['Version'].toString();

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      if (kDebugMode) {
        print("Checking updates: Latest=$latestVersion, Current=$currentVersion");
      }

      return _isVersionGreater(latestVersion, currentVersion);
    } catch (e) {
      if (kDebugMode) print("Error checking updates: $e");
      return false;
    }
  }

  static bool _isVersionGreater(String latestVersion, String currentVersion) {
    // Clean strings (remove 'v' or 'V' prefix)
    String cleanLatest = latestVersion.toLowerCase().replaceAll('v', '').trim();
    String cleanCurrent = currentVersion.toLowerCase().replaceAll('v', '').trim();

    // Remove build numbers for comparison if present (e.g. 1.0.0+1)
    cleanLatest = cleanLatest.split('+')[0];
    cleanCurrent = cleanCurrent.split('+')[0];

    List<String> latestParts = cleanLatest.split('.');
    List<String> currentParts = cleanCurrent.split('.');

    int maxLength = latestParts.length > currentParts.length 
        ? latestParts.length 
        : currentParts.length;

    for (int i = 0; i < maxLength; i++) {
      int latestPart = i < latestParts.length ? (int.tryParse(latestParts[i]) ?? 0) : 0;
      int currentPart = i < currentParts.length ? (int.tryParse(currentParts[i]) ?? 0) : 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    return false;
  }
}
