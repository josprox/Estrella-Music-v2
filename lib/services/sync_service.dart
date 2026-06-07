import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/helper.dart';
import 'auth_service.dart';
import 'music_service.dart';
import '../ui/screens/Library/library_controller.dart';

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

  Timer? _debounceTimer;

  // Triggers a debounced push to the server
  void triggerPush() {
    if (!_authService.isAuthenticated.value) return;
    Hive.box('AppPrefs').put('hasPendingSync', true);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      push();
    });
  }

  // Pulls all data from server and merges with local Hive boxes
  Future<bool> pull() async {
    if (!_authService.isAuthenticated.value) return false;
    printINFO("SyncService: Starting pull from server...");

    try {
      final response = await _dio.get(
        '${_normalizedBaseUrl()}api/sync/pull',
        options: Options(headers: await _headers()),
      );

      if (response.statusCode != 200) {
        printERROR("SyncService: Pull failed with status ${response.statusCode}");
        return false;
      }

      final data = response.data;
      if (data == null || data['status'] != 'success') {
        return false;
      }

      // 1. Sync Playlists
      final playlists = data['playlists'] as List? ?? [];
      final playlistBox = await Hive.openBox('LibraryPlaylists');
      await playlistBox.clear();
      for (var plData in playlists) {
        if (plData is! Map) continue;
        final playlistId = plData['playlistId']?.toString();
        if (playlistId == null) continue;
        
        // Save playlist metadata
        await playlistBox.put(playlistId, {
          "title": plData['title'],
          "playlistId": playlistId,
          "description": plData['description'] ?? '',
          "thumbnails": plData['thumbnails'] ?? [{"url": ""}],
          "isPipedPlaylist": false,
          "isCloudPlaylist": true
        });

        // Save playlist tracks
        final tracksBox = await Hive.openBox(playlistId);
        await tracksBox.clear();
        final tracksList = plData['tracks'] as List? ?? [];
        for (int i = 0; i < tracksList.length; i++) {
          await tracksBox.put(i, tracksList[i]);
        }
      }

      // 2. Sync Favorites
      final favorites = data['favorites'] as List? ?? [];
      final favBox = await Hive.openBox('LIBFAV');
      await favBox.clear();
      for (var favData in favorites) {
        if (favData is! Map) continue;
        final id = favData['id']?.toString();
        if (id != null) {
          await favBox.put(id, favData);
        }
      }

      // 3. Sync Recent Plays
      final recents = data['recent_plays'] as List? ?? [];
      final recentBox = await Hive.openBox('LIBRP');
      await recentBox.clear();
      for (var recData in recents) {
        if (recData is! Map) continue;
        await recentBox.add(recData);
      }

      // 4. Sync Albums
      final albums = data['albums'] as List? ?? [];
      final albumBox = await Hive.openBox('LibraryAlbums');
      await albumBox.clear();
      for (var albData in albums) {
        if (albData is! Map) continue;
        final albumId = albData['browseId']?.toString() ?? albData['albumId']?.toString();
        if (albumId == null) continue;

        final albMap = Map<String, dynamic>.from(albData);
        final tracksList = albMap.remove('tracks') as List? ?? [];

        // Save album metadata
        await albumBox.put(albumId, albMap);

        // Save album tracks
        final tracksBox = await Hive.openBox(albumId);
        await tracksBox.clear();
        for (int i = 0; i < tracksList.length; i++) {
          await tracksBox.put(i, tracksList[i]);
        }
      }

      // 5. Sync Artists
      final artists = data['artists'] as List? ?? [];
      final artistBox = await Hive.openBox('LibraryArtists');
      await artistBox.clear();
      for (var artData in artists) {
        if (artData is! Map) continue;
        final artistId = artData['browseId']?.toString() ?? artData['artistId']?.toString();
        if (artistId != null) {
          await artistBox.put(artistId, artData);
        }
      }

      // 6. Sync Visitor ID
      final visitorId = data['visitor_id']?.toString();
      if (visitorId != null && visitorId.isNotEmpty) {
        Get.find<MusicServices>().setVisitorId(visitorId);
      }

      printINFO("SyncService: Pull completed successfully. Refreshing UI controllers...");
      
      // Refresh UI Controllers
      _refreshControllers();

      return true;
    } catch (e) {
      printERROR("SyncService: Pull failed with exception: $e");
      return false;
    }
  }

  // Pushes the entire local state to the server
  Future<bool> push() async {
    if (!_authService.isAuthenticated.value) return false;
    printINFO("SyncService: Starting push to server...");

    try {
      // 1. Prepare Playlists
      final playlistBox = await Hive.openBox('LibraryPlaylists');
      final playlistsList = [];
      for (var key in playlistBox.keys) {
        final plData = playlistBox.get(key);
        if (plData is! Map) continue;
        
        final playlistId = key.toString();
        final tracksBox = await Hive.openBox(playlistId);
        final tracks = tracksBox.values.toList();
        
        // Create a copy of playlist map to modify
        final plMap = Map<String, dynamic>.from(plData);
        plMap['tracks'] = tracks;
        playlistsList.add(plMap);
      }

      // 2. Prepare Favorites
      final favBox = await Hive.openBox('LIBFAV');
      final favoritesList = favBox.values.toList();

      // 3. Prepare Recent Plays
      final recentBox = await Hive.openBox('LIBRP');
      final recentList = recentBox.values.toList();

      // 4. Prepare Albums (including their tracks!)
      final albumBox = await Hive.openBox('LibraryAlbums');
      final albumsList = [];
      for (var key in albumBox.keys) {
        final albData = albumBox.get(key);
        if (albData is! Map) continue;

        final albumId = key.toString();
        final tracksBox = await Hive.openBox(albumId);
        final tracks = tracksBox.values.toList();

        final albMap = Map<String, dynamic>.from(albData);
        albMap['tracks'] = tracks;
        albumsList.add(albMap);
      }

      // 5. Prepare Artists
      final artistBox = await Hive.openBox('LibraryArtists');
      final artistsList = artistBox.values.toList();

      final payload = {
        "playlists": playlistsList,
        "favorites": favoritesList,
        "recent_plays": recentList,
        "albums": albumsList,
        "artists": artistsList,
        "visitor_id": Hive.box('AppPrefs').get('visitorId')?['id'],
      };

      final response = await _dio.post(
        '${_normalizedBaseUrl()}api/sync/push',
        options: Options(headers: await _headers()),
        data: payload,
      );

      if (response.statusCode == 200) {
        printINFO("SyncService: Push completed successfully.");
        Hive.box('AppPrefs').put('hasPendingSync', false);
        return true;
      } else {
        printERROR("SyncService: Push failed with status ${response.statusCode}");
        return false;
      }
    } catch (e) {
      printERROR("SyncService: Push failed with exception: $e");
      return false;
    }
  }

  // Refreshes all active controllers in the application
  void _refreshControllers() {
    if (Get.isRegistered<LibraryPlaylistsController>()) {
      Get.find<LibraryPlaylistsController>().refreshLib();
    }
    if (Get.isRegistered<LibraryAlbumsController>()) {
      Get.find<LibraryAlbumsController>().refreshLib();
    }
    if (Get.isRegistered<LibraryArtistsController>()) {
      Get.find<LibraryArtistsController>().refreshLib();
    }
    if (Get.isRegistered<LibrarySongsController>()) {
      Get.find<LibrarySongsController>().init();
    }
  }
}
