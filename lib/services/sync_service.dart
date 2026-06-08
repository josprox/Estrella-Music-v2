import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/helper.dart';
import 'auth_service.dart';
import '../models/playlist.dart';

class SyncService extends GetxService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      validateStatus: (_) => true,
    ),
  );

  AuthService get _authService => Get.find<AuthService>();

  String? get syncBaseUrl {
    final isDebugEnv = dotenv.env['DEBUG']?.toLowerCase() == 'true';
    if (kDebugMode && isDebugEnv) {
      if (GetPlatform.isWindows) {
        return 'http://127.0.0.1:9000';
      } else if (GetPlatform.isAndroid) {
        return 'http://10.0.2.2:9000';
      }
    }
    return dotenv.env['EMUSICWEB'];
  }

  String _normalizedBaseUrl() {
    var base = syncBaseUrl?.trim() ?? '';
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }
    return '$base/';
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getAccessToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }


  // Triggers a debounced push to the server
  void triggerPush() {
    printINFO("SyncService: triggerPush is disabled (local-only mode).");
  }

  // Pulls all data from server and merges with local Hive boxes
  Future<bool> pull() async {
    printINFO("SyncService: Pull is disabled (local-only mode).");
    return true;
  }

  // Pushes the entire local state to the server
  Future<bool> push() async {
    printINFO("SyncService: Push is disabled (local-only mode).");
    return true;
  }


  Future<bool> pushCollaborative(Playlist playlist) async {
    if (!_authService.isAuthenticated.value) return false;
    printINFO("SyncService: Pushing collaborative playlist...");

    try {
      final tracksBox = await Hive.openBox(playlist.playlistId);
      final tracks = tracksBox.values.toList();

      final plMap = playlist.toJson();
      plMap['tracks'] = tracks;

      final response = await _dio.post(
        '${_normalizedBaseUrl()}api/sync/push-collaborative',
        options: Options(headers: await _headers()),
        data: {"playlist": plMap},
      );

      if (response.statusCode == 200) {
        printINFO("SyncService: Collaborative push completed successfully.");
        return true;
      } else {
        printERROR("SyncService: Collaborative push failed with status ${response.statusCode}");
        return false;
      }
    } catch (e) {
      printERROR("SyncService: Collaborative push failed with exception: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (!_authService.isAuthenticated.value) return [];
    try {
      final response = await _dio.get(
        '${_normalizedBaseUrl()}api/users/search',
        queryParameters: {"query": query},
        options: Options(headers: await _headers()),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List users = response.data['users'] as List? ?? [];
        return users.map((u) => Map<String, dynamic>.from(u)).toList();
      }
    } catch (e) {
      printERROR("SyncService: Search users failed: $e");
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    if (!_authService.isAuthenticated.value) return [];
    try {
      final response = await _dio.get(
        '${_normalizedBaseUrl()}api/users/friends',
        options: Options(headers: await _headers()),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List friends = response.data['friends'] as List? ?? [];
        return friends.map((u) => Map<String, dynamic>.from(u)).toList();
      }
    } catch (e) {
      printERROR("SyncService: Fetch friends failed: $e");
    }
    return [];
  }

  Future<List<Playlist>> fetchPublicPlaylists() async {
    if (!_authService.isAuthenticated.value) return [];
    try {
      final response = await _dio.get(
        '${_normalizedBaseUrl()}api/playlists/public',
        options: Options(headers: await _headers()),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List playlists = response.data['playlists'] as List? ?? [];
        return playlists.map((p) => Playlist.fromJson(p)).toList();
      }
    } catch (e) {
      printERROR("SyncService: Fetch public playlists failed: $e");
    }
    return [];
  }
}
