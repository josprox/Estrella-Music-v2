// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:hive/hive.dart';

import '/models/album.dart';
import '/services/utils.dart';
import '../utils/helper.dart';
import 'constant.dart';
import 'continuations.dart';
import 'nav_parser.dart';
import '/models/artist.dart';
import '/models/playlist.dart';

enum AudioQuality {
  Low,
  High,
}

extension ListExtension<T> on List<T> {
  List<T> distinctBy(dynamic Function(T) keySelector) {
    final seen = <dynamic>{};
    return where((item) => seen.add(keySelector(item))).toList();
  }
}

class MusicServices extends getx.GetxService {
  final Map<String, String> _headers = {
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': domain,
    'cookie': 'CONSENT=YES+1',
  };

  final Map<String, dynamic> _context = {
    'context': {
      'client': {
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20230213.01.00",
        "visitorData": null,
      },
      'user': {}
    }
  };

  @override
  void onInit() {
    init();
    super.onInit();
  }

  final dio = Dio();

  Future<void> init() async {
    //check visitor id in data base, if not generate one , set lang code
    final date = DateTime.now();
    _context['context']['client']['clientVersion'] =
        "1.${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}.01.00";
    final signatureTimestamp = getDatestamp() - 1;
    _context['playbackContext'] = {
      'contentPlaybackContext': {'signatureTimestamp': signatureTimestamp},
    };

    final appPrefsBox = Hive.box('AppPrefs');
    hlCode = appPrefsBox.get('contentLanguage') ?? "en";
    if (appPrefsBox.containsKey('visitorId')) {
      final visitorData = appPrefsBox.get("visitorId");
      if (visitorData != null && !isExpired(epoch: visitorData['exp'])) {
        _headers['X-Goog-Visitor-Id'] = visitorData['id'];
        _context['context']['client']['visitorData'] = visitorData['id'];
        appPrefsBox.put("visitorId", {
          'id': visitorData['id'],
          'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2590200
        });
        printINFO("Got Visitor id (${visitorData['id']}) from Box");
        return;
      }
    }

    final visitorId = await genrateVisitorId();
    if (visitorId != null) {
      _headers['X-Goog-Visitor-Id'] = visitorId;
      _context['context']['client']['visitorData'] = visitorId;
      printINFO("New Visitor id generated ($visitorId)");
      appPrefsBox.put("visitorId", {
        'id': visitorId,
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2592000
      });
      return;
    }
    // not able to generate in that case
    final defaultId = visitorId ?? "CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D";
    _headers['X-Goog-Visitor-Id'] = defaultId;
    _context['context']['client']['visitorData'] = defaultId;
  }

  void setVisitorId(String id) {
    _headers['X-Goog-Visitor-Id'] = id;
    _context['context']['client']['visitorData'] = id;
    final appPrefsBox = Hive.box('AppPrefs');
    appPrefsBox.put("visitorId", {
      'id': id,
      'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2592000
    });
    printINFO("Visitor id updated manually ($id)");
  }

  set hlCode(String code) {
    _context['context']['client']['hl'] = code;
  }

  Future<String?> genrateVisitorId() async {
    try {
      final response =
          await dio.get(domain, options: Options(headers: _headers));
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(response.data.toString());
      String? visitorId;
      if (matches != null) {
        final ytcfg = json.decode(matches.group(1).toString());
        visitorId = ytcfg['VISITOR_DATA']?.toString();
      }
      return visitorId;
    } catch (e) {
      return null;
    }
  }

  Future<Response> _sendRequest(String action, Map<dynamic, dynamic> data,
      {additionalParams = "", int attempt = 0}) async {
    //print("$baseUrl$action$fixedParms$additionalParams          data:$data");
    try {
      final response =
          await dio.post("$baseUrl$action$fixedParms$additionalParams",
              options: Options(
                headers: _headers,
                validateStatus: (_) => true,
              ),
              data: data);

      if (response.statusCode == 200) {
        return response;
      }
      if (_shouldRetry(response.statusCode) && attempt < 1) {
        return _sendRequest(
          action,
          data,
          additionalParams: additionalParams,
          attempt: attempt + 1,
        );
      }
      throw NetworkError(
        statusCode: response.statusCode,
        responseData: response.data,
        message: 'Request failed for $action',
      );
    } on DioException catch (e) {
      printINFO("Error $e");
      if (_shouldRetry(e.response?.statusCode) && attempt < 1) {
        return _sendRequest(
          action,
          data,
          additionalParams: additionalParams,
          attempt: attempt + 1,
        );
      }
      throw NetworkError(
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        message: e.message ?? 'Network Error',
      );
    }
  }

  bool _shouldRetry(int? statusCode) {
    if (statusCode == null) {
      return true;
    }
    return statusCode == 429 || statusCode >= 500;
  }

  // Future<List<Map<String, dynamic>>>
  Future<dynamic> getHome({int limit = 4}) async {
    final data = Map.from(_context);
    data["browseId"] = "FEmusic_home";
    final response = await _sendRequest("browse", data);
    final results = nav(response.data, single_column_tab + section_list);
    final home = [...parseMixedContent(results)];

    final sectionList =
        nav(response.data, single_column_tab + ['sectionListRenderer']);
    //inspect(sectionList);
    //print(sectionList.containsKey('continuations'));
    if (sectionList.containsKey('continuations')) {
      requestFunc(additionalParams) async {
        return (await _sendRequest("browse", data,
                additionalParams: additionalParams))
            .data;
      }

      parseFunc(contents) => parseMixedContent(contents);
      final x = (await getContinuations(sectionList, 'sectionListContinuation',
          limit - home.length, requestFunc, parseFunc));
      // inspect(x);
      home.addAll([...x]);
    }

    return home;
  }

  Future<List<Map<String, dynamic>>> getCharts(String catogory,
      {String? countryCode}) async {
    final List<Map<String, dynamic>> charts = [];
    final data = Map.from(_context);

    data['browseId'] = 'FEmusic_charts';
    data['context']['client']["hl"] = 'en';
    if (countryCode != null) {
      data['formData'] = {
        'selectedValues': [countryCode]
      };
    }
    final response = (await _sendRequest('browse', data)).data;
    final results = nav(response, single_column_tab + section_list);
    results.removeAt(0);
    for (dynamic result in results) {
      if (nav(result, [
            "musicCarouselShelfRenderer",
            "header",
            "musicCarouselShelfBasicHeaderRenderer",
            ...title_text
          ]) ==
          "Video charts") {
        for (dynamic item in result['musicCarouselShelfRenderer']['contents']) {
          final chartItem =
              await getChartItems(parseChartsItemBrowseId(item), catogory);
          charts.add(chartItem);
        }
      } else {
        continue;
      }
    }

    return charts;
  }

  Future<Map<String, dynamic>> getChartItems(
      Map<String, dynamic> item, String catogory) async {
    final catString = catogory == "TMV" ? "Top Music Videos" : "Trending";
    if ((item['title'])!.contains(catString)) {
      final songs = (await getPlaylistOrAlbumSongs(
          playlistId: item['browseId']))['tracks'];
      final limitedSongs = songs.length > 24 ? songs.sublist(0, 24) : songs;
      return {'title': item['title'], 'contents': limitedSongs};
    }
    return {'title': item['title'], 'contents': []};
  }

  Future<Map<String, dynamic>> getWatchPlaylist(
      {String videoId = "",
      String? playlistId,
      int limit = 25,
      bool radio = false,
      bool shuffle = false,
      String? additionalParamsNext,
      bool onlyRelated = false}) async {
    if (videoId.isNotEmpty && videoId.substring(0, 4) == "MPED") {
      videoId = videoId.substring(4);
    }
    final data = Map.from(_context);
    data['enablePersistentPlaylistPanel'] = true;
    data['isAudioOnly'] = true;
    data['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';
    if (videoId == "" && playlistId == null) {
      throw Exception(
          "You must provide either a video id, a playlist id, or both");
    }
    if (videoId != "") {
      data['videoId'] = videoId;
      playlistId ??= "RDAMVM$videoId";

      if (!(radio || shuffle)) {
        data['watchEndpointMusicSupportedConfigs'] = {
          'watchEndpointMusicConfig': {
            'hasPersistentPlaylistPanel': true,
            'musicVideoType': "MUSIC_VIDEO_TYPE_ATV",
          }
        };
      }
    }

    playlistId = validatePlaylistId(playlistId!);
    data['playlistId'] = playlistId;
    final isPlaylist =
        playlistId.startsWith('PL') || playlistId.startsWith('OLA');
    if (shuffle) {
      data['params'] = "wAEB8gECKAE%3D";
    }
    if (radio) {
      data['params'] = "wAEB";
    }

    final List<dynamic> tracks = [];
    dynamic lyricsBrowseId, relatedBrowseId, playlist;
    final results = {};

    if (additionalParamsNext == null) {
      final response = (await _sendRequest("next", data)).data;
      final watchNextRenderer = nav(response, [
        'contents',
        'singleColumnMusicWatchNextResultsRenderer',
        'tabbedRenderer',
        'watchNextTabbedResultsRenderer'
      ]);

      lyricsBrowseId = getTabBrowseId(watchNextRenderer, 1);
      relatedBrowseId = getTabBrowseId(watchNextRenderer, 2);
      if (onlyRelated) {
        return {
          'lyrics': lyricsBrowseId,
          'related': relatedBrowseId,
        };
      }

      results.addAll(nav(watchNextRenderer, [
        ...tab_content,
        'musicQueueRenderer',
        'content',
        'playlistPanelRenderer'
      ]));
      playlist = results['contents']
          .map((content) => nav(content,
              ['playlistPanelVideoRenderer', ...navigation_playlist_id]))
          .where((e) => e != null)
          .toList()
          .first;
      tracks.addAll(parseWatchPlaylist(results['contents']));
    }

    dynamic additionalParamsForNext;
    if (results.containsKey('continuations') || additionalParamsNext != null) {
      requestFunc(additionalParams) async =>
          (await _sendRequest("next", data, additionalParams: additionalParams))
              .data;
      parseFunc(contents) => parseWatchPlaylist(contents);
      final x = await getContinuations(results, 'playlistPanelContinuation',
          limit - tracks.length, requestFunc, parseFunc,
          ctokenPath: isPlaylist ? '' : 'Radio',
          isAdditionparamReturnReq: true,
          additionalParams_: additionalParamsNext);
      additionalParamsForNext = x[1];
      tracks.addAll(List<dynamic>.from(x[0]));
    }

    return {
      'tracks': tracks,
      'playlistId': playlist,
      'lyrics': lyricsBrowseId,
      'related': relatedBrowseId,
      'additionalParamsForNext': additionalParamsForNext
    };
  }

  Future<String> getAlbumBrowseId(String audioPlaylistId) async {
    final response = await dio.get("${domain}playlist",
        options: Options(headers: _headers),
        queryParameters: {"list": audioPlaylistId});
    final reg = RegExp(r'\"MPRE.+?\"');
    final matchs = reg.firstMatch(response.data.toString());
    if (matchs != null) {
      final x = (matchs[0])!;
      final res = (x.substring(1)).split("\\")[0];
      return res;
    }
    return audioPlaylistId;
  }

  Future<List<Map<String, dynamic>>> getContentRelatedToSong(String videoId, String hlCode) async {
    try {
      final params = await getWatchPlaylist(videoId: videoId, onlyRelated: true);
      if (params['related'] == null) return [];
      
      final data = Map.from(_context);
      data['browseId'] = params['related'];
      data['context']['client']['hl'] = hlCode;
      
      final response = (await _sendRequest('browse', data)).data;
      final sections = nav(response, ['contents'] + section_list);
      if (sections == null) return [];
      
      final x = parseMixedContent(sections);
      return x;
    } catch (e) {
      printERROR("getContentRelatedToSong failed: $e");
      return [];
    }
  }

  dynamic getLyrics(String browseId) async {
    final data = Map.from(_context);
    data['browseId'] = browseId;
    final response = (await _sendRequest('browse', data)).data;
    return nav(
      response,
      ['contents', ...section_list_item, ...description_shelf, ...description],
    );
  }

  Future<Map<String, dynamic>> getPlaylistOrAlbumSongs(
      {String? playlistId,
      String? albumId,
      int limit = 3000,
      bool related = false,
      int suggestionsLimit = 0}) async {
    String browseId = playlistId != null
        ? (playlistId.startsWith("VL") ? playlistId : "VL$playlistId")
        : albumId!;
    if (albumId != null && albumId.contains("OLAK5uy")) {
      browseId = await getAlbumBrowseId(browseId);
    }
    final data = Map.from(_context);
    data['browseId'] = browseId;
    final Map<String, dynamic> response =
        (await _sendRequest('browse', data)).data;
    if (playlistId != null) {
      final Map<String, dynamic> header =
          nav(response, ['header', "musicDetailHeaderRenderer"]) ??
              nav(response, [
                'contents',
                "twoColumnBrowseResultsRenderer",
                'tabs',
                0,
                "tabRenderer",
                "content",
                "sectionListRenderer",
                "contents",
                0,
                "musicResponsiveHeaderRenderer"
              ]);

      final Map<String, dynamic> results =
          nav(response, musicPlaylistShelfRenderer) ??
              nav(
                response,
                [
                  'contents',
                  "singleColumnBrowseResultsRenderer",
                  "tabs",
                  0,
                  "tabRenderer",
                  "content",
                  'sectionListRenderer',
                  'contents',
                  0,
                  "musicPlaylistShelfRenderer"
                ],
              );
      final Map<String, dynamic> playlist = {'id': results['playlistId']};

      playlist['title'] = nav(header, title_text);
      playlist['thumbnails'] = nav(header, thumnail_cropped) ??
          nav(header, [
            "thumbnail",
            "musicThumbnailRenderer",
            "thumbnail",
            "thumbnails"
          ]);
      playlist["description"] = nav(header, description);
      final int runCount = header['subtitle']['runs'].length;
      if (runCount > 1) {
        playlist['author'] = {
          'name': nav(header, subtitle2),
          'id': nav(header, ['subtitle', 'runs', 2] + navigation_browse_id)
        };
        if (runCount == 5) {
          playlist['year'] = nav(header, subtitle3);
        }
      }

      final int secondSubtitleRunCount =
          header['secondSubtitle']['runs'].length;
      final String count = (((header['secondSubtitle']['runs']
                      [secondSubtitleRunCount % 3]['text'])
                  .split(' ')[0])
              .split(',') as List)
          .join();
      final int songCount = int.parse(count);
      if (header['secondSubtitle']['runs'].length > 1) {
        playlist['duration'] = header['secondSubtitle']['runs']
            [(secondSubtitleRunCount % 3) + 2]['text'];
      }
      playlist['trackCount'] = songCount;

      // requestFunc(additionalParams) async => (await _sendRequest("browse", data,
      //         additionalParams: additionalParams))
      //     .data;

      requestFuncCountinuation(cont) async =>
          (await _sendRequest("browse", {...data, ...cont})).data;

      if (songCount > 0) {
        playlist['tracks'] = parsePlaylistItems(results['contents']);
        limit = songCount;

        List<dynamic> parseFunc(contents) => parsePlaylistItems(contents);

        playlist['tracks'] = [
          ...(playlist['tracks']),
          ...(await getContinuationsPlaylist(
              results, limit, requestFuncCountinuation, parseFunc))
        ];
      }
      playlist['duration_seconds'] = sumTotalDuration(playlist);
      return playlist;
    }

    //album content
    final album = parseAlbumHeader(response);
    dynamic results = nav(
          response,
          [
            'contents',
            "twoColumnBrowseResultsRenderer",
            "secondaryContents",
            'sectionListRenderer',
            'contents',
            0,
            'musicShelfRenderer'
          ],
        ) ??
        nav(
          response,
          [
            'contents',
            "singleColumnBrowseResultsRenderer",
            "tabs",
            0,
            "tabRenderer",
            "content",
            'sectionListRenderer',
            'contents',
            0,
            'musicShelfRenderer'
          ],
        );

    album['tracks'] = parsePlaylistItems(results['contents'],
        artistsM: album['artists'],
        thumbnailsM: album["thumbnails"],
        albumIdName: {"id": albumId, 'name': album['title']},
        albumYear: album['year'],
        isAlbum: true);
    results = nav(
      response,
      [...single_column_tab, ...section_list, 1, 'musicCarouselShelfRenderer'],
    );
    if (results != null) {
      List contents = [];
      if (results.runtimeType.toString().contains("Iterable") ||
          results.runtimeType.toString().contains("List")) {
        for (dynamic result in results) {
          contents.add(parseAlbum(result['musicTwoRowItemRenderer']));
        }
      } else {
        contents
            .add(parseAlbum(results['contents'][0]['musicTwoRowItemRenderer']));
      }
      album['other_versions'] = contents;
    }
    album['duration_seconds'] = sumTotalDuration(album);

    return album;
  }

  Future<List<String>> getSearchSuggestion(String queryStr) async {
    final data = Map.from(_context);
    data['input'] = queryStr;
    final res = nav(
            (await _sendRequest("music/get_search_suggestions", data)).data,
            ['contents', 0, 'searchSuggestionsSectionRenderer', 'contents']) ??
        [];
    return res
        .map<String?>((item) {
          return (nav(item, [
            'searchSuggestionRenderer',
            'navigationEndpoint',
            'searchEndpoint',
            'query'
          ])).toString();
        })
        .whereType<String>()
        .toList();
  }

  ///Specially created for deep-links
  Future<List> getSongWithId(String songId) async {
    final data = Map.of(_context);
    data['videoId'] = songId;
    try {
      final response = (await _sendRequest("player", data)).data;
      final category =
          nav(response, ["microformat", "microformatDataRenderer", "category"]);
      if (category == "Music" ||
          (response["videoDetails"]).containsKey("musicVideoType")) {
        final list = await getWatchPlaylist(videoId: songId);
        return [true, list['tracks']];
      }
    } on NetworkError catch (error) {
      printERROR("No fue posible resolver la cancion $songId: $error");
    }
    return [false, null];
  }

  Future<Map<String, dynamic>> search(String query,
      {String? filter,
      String? scope,
      int limit = 30,
      bool ignoreSpelling = false,
      String? filterParams}) async {
    final data = Map.of(_context);
    data['context']['client']["hl"] = 'en';
    data['query'] = query;

    final Map<String, dynamic> searchResults = {};
    final filters = [
      'albums',
      'artists',
      'playlists',
      'community_playlists',
      'featured_playlists',
      'songs',
      'videos',
      'podcasts',
      'episodes',
      'profiles'
    ];

    if (filter != null && !filters.contains(filter)) {
      throw Exception(
          'Invalid filter provided. Please use one of the following filters or leave out the parameter: ${filters.join(', ')}');
    }

    final scopes = ['library', 'uploads'];

    if (scope != null && !scopes.contains(scope)) {
      throw Exception(
          'Invalid scope provided. Please use one of the following scopes or leave out the parameter: ${scopes.join(', ')}');
    }

    if (scope == scopes[1] && filter != null) {
      throw Exception(
          'No filter can be set when searching uploads. Please unset the filter parameter when scope is set to uploads.');
    }

    final params = getSearchParams(filter, scope, ignoreSpelling);

    if (filterParams != null || params != null) {
      data['params'] = filterParams ?? params;
    }

    final response = (await _sendRequest("search", data)).data;

    dynamic results;

    if (response['contents'] != null && (response['contents']).containsKey('tabbedSearchResultsRenderer')) {
      final tabIndex =
          scope == null || filter != null ? 0 : scopes.indexOf(scope) + 1;
      results = response['contents']['tabbedSearchResultsRenderer']['tabs']
          [tabIndex]['tabRenderer']['content'];
    } else {
      results = response['contents'];
    }

    if (results == null) return searchResults;

    // Search Chips
    if (filter == null) {
      final searchChips = nav(results,
          ['sectionListRenderer', 'header', "chipCloudRenderer", "chips"]);

      searchResults['searchEndpoint'] = {};
      if (searchChips != null) {
        for (dynamic chipsItemRenderer in searchChips) {
          final chip = chipsItemRenderer['chipCloudChipRenderer'];
          final chipText = nav(chip, ['text', 'runs', 0, 'text']);
          searchResults['searchEndpoint'][chipText] =
              nav(chip, ['navigationEndpoint', 'searchEndpoint', 'params']);
        }
      }

      // now Featured playlists and community playlists are not coming in top results
      // so adding them in tab if not present
      if ((searchResults['searchEndpoint'])
              .containsKey("Community playlists") &&
          !searchResults.containsKey("Community playlists")) {
        searchResults["Community playlists"] = [];
      }

      if ((searchResults['searchEndpoint']).containsKey("Featured playlists") &&
          !searchResults.containsKey("Featured playlists")) {
        searchResults["Featured playlists"] = [];
      }
    }

    results = nav(results, ['sectionListRenderer', 'contents']);
    if (results == null) return searchResults;

    String? type = filter?.substring(0, filter.length - 1).toLowerCase();

    for (var res in results) {
      if (res is! Map) continue;

      // Extract additional chips if present in sections (common in some YTM responses)
      final sectionChips = nav(res, ['itemSectionRenderer', 'header', "chipCloudRenderer", "chips"]) ??
                           nav(res, ["chipCloudRenderer", "chips"]);
      if (sectionChips != null && filter == null) {
        for (dynamic chipsItemRenderer in sectionChips) {
          final chip = chipsItemRenderer['chipCloudChipRenderer'];
          final chipText = nav(chip, ['text', 'runs', 0, 'text']);
          if (chipText != null) {
            searchResults['searchEndpoint'][chipText] =
                nav(chip, ['navigationEndpoint', 'searchEndpoint', 'params']);
          }
        }
      }

      if (res.containsKey('musicCardShelfRenderer')) {
        final card = res['musicCardShelfRenderer'];
        final topResult = parseTopResult(card,
            ['artist', 'playlist', 'song', 'video', 'station', 'podcast', 'episode', 'profile']);
        if (topResult != null) {
          _addToSearchResults(searchResults, 'Top result', [topResult]);
          
          if (card.containsKey('contents')) {
            final cardItems = parseSearchResults(card['contents'],
                ['artist', 'playlist', 'song', 'video', 'station', 'podcast', 'episode', 'profile'], null, 'Top result');
            if (filter == null) {
              _groupResultsByType(cardItems, searchResults);
            }
          }
        }
      } else if (res.containsKey('musicShelfRenderer')) {
        await _parseAndAddShelf(res['musicShelfRenderer'], searchResults, filter, type, data, limit);
      } else if (res.containsKey('musicCarouselShelfRenderer')) {
        await _parseAndAddShelf(res['musicCarouselShelfRenderer'], searchResults, filter, type, data, limit);
      } else if (res.containsKey('itemSectionRenderer')) {
        final sectionContents = res['itemSectionRenderer']['contents'];
        if (sectionContents is List) {
          bool hasShelves = false;
          for (var content in sectionContents) {
            if (content is Map && (content.containsKey('musicShelfRenderer') || content.containsKey('musicCarouselShelfRenderer'))) {
              hasShelves = true;
              break;
            }
          }
          if (hasShelves) {
            for (var content in sectionContents) {
              if (content is! Map) continue;
              if (content.containsKey('musicShelfRenderer')) {
                await _parseAndAddShelf(content['musicShelfRenderer'], searchResults, filter, type, data, limit);
              } else if (content.containsKey('musicCarouselShelfRenderer')) {
                await _parseAndAddShelf(content['musicCarouselShelfRenderer'], searchResults, filter, type, data, limit);
              }
            }
          } else {
            final parsedItems = parseSearchResults(
              sectionContents,
              ['artist', 'playlist', 'song', 'video', 'station', 'podcast', 'episode', 'profile'],
              type,
              'mixed',
            );
            if (parsedItems.isNotEmpty) {
              if (filter == null) {
                _groupResultsByType(parsedItems, searchResults);
              } else {
                _addToSearchResults(searchResults, 'mixed', parsedItems);
              }
            }
          }
        }
      }
    }

    if (filter == null) {
      final List<String> orderedKeys = [
        'Top result',
        'Songs',
        'Videos',
        'Albums',
        'Podcasts',
        'Episodes',
        'Artists',
        'Profiles',
        'Playlists',
        'Community playlists',
        'Featured playlists'
      ];
      final Map<String, dynamic> orderedResults = {};
      
      if (searchResults.containsKey('searchEndpoint')) {
        orderedResults['searchEndpoint'] = searchResults['searchEndpoint'];
      }
      
      for (var key in orderedKeys) {
        if (searchResults.containsKey(key) && searchResults[key] != null && (searchResults[key] as List).isNotEmpty) {
           orderedResults[key] = (searchResults[key] as List).distinctBy((item) => item is MediaItem ? item.id : (item is Artist ? item.browseId : (item is Album ? item.browseId : (item is Playlist ? item.playlistId : item.toString())))).toList();
        }
      }
      
      searchResults.forEach((key, value) {
        if (!orderedResults.containsKey(key) && key != 'searchEndpoint') {
          orderedResults[key] = value;
        }
      });
      
      return orderedResults;
    }

    return searchResults;
  }

  void _addToSearchResults(Map<String, dynamic> searchResults, String category, List<dynamic> items) {
    if (searchResults.containsKey(category)) {
      (searchResults[category] as List).addAll(items);
    } else {
      searchResults[category] = List<dynamic>.from(items);
    }
  }

  void _groupResultsByType(List<dynamic> items, Map<String, dynamic> searchResults) {
    for (var item in items) {
      String itemType = "Other";
      if (item is MediaItem) {
        final String? resType = item.extras?['resultType'];
        if (resType == 'episode') {
          itemType = "Episodes";
        } else if (resType == 'song') {
          itemType = "Songs";
        } else if (resType == 'video') {
          itemType = "Videos";
        }
      } else if (item is Artist) {
        itemType = item.isProfile ? "Profiles" : "Artists";
      } else if (item is Album) {
        itemType = item.isPodcast ? "Podcasts" : "Albums";
      } else if (item is Playlist) {
        itemType = "Playlists";
      }
      
      if (!searchResults.containsKey(itemType)) {
        searchResults[itemType] = [];
      }
      
      if ((searchResults[itemType] as List).length < 10) {
        (searchResults[itemType] as List).add(item);
      }
    }
  }

  Future<void> _parseAndAddShelf(
    Map<String, dynamic> shelf,
    Map<String, dynamic> searchResults,
    String? filter,
    String? type,
    Map<String, dynamic> data,
    int limit,
  ) async {
    final itemResults = shelf['contents'];
    if (itemResults == null) return;
    
    final apiTitle = nav(shelf, title_text) ?? nav(shelf, ['header', 'musicCarouselShelfBasicHeaderRenderer', 'title', 'runs', 0, 'text']);
    final category = apiTitle ?? "mixed";

    final mixedItems = parseSearchResults(
      itemResults,
      ['artist', 'playlist', 'song', 'video', 'station', 'podcast', 'episode', 'profile'],
      type,
      category,
    );

    if (filter == null) {
      if (apiTitle != null) {
        _addToSearchResults(searchResults, apiTitle, mixedItems);
      } else {
        _groupResultsByType(mixedItems, searchResults);
      }
    } else {
      _addToSearchResults(searchResults, category, mixedItems);
    }

    if (filter != null) {
      requestFunc(additionalParams) async =>
          (await _sendRequest("search", data,
                  additionalParams: additionalParams))
              .data;
      parseFunc(contents) => parseSearchResults(contents,
          ['artist', 'playlist', 'song', 'video', 'station', 'podcast', 'episode', 'profile'], type, category);

      if (searchResults.containsKey(category)) {
        final x = await getContinuations(
            shelf,
            'musicShelfContinuation',
            limit - ((searchResults[category] as List).length),
            requestFunc,
            parseFunc,
            isAdditionparamReturnReq: true);

        searchResults["params"] = {
          'data': data,
          "type": type,
          "category": category,
          'additionalParams': x[1],
        };

        searchResults[category] = [
          ...(searchResults[category] as List),
          ...(x[0])
        ];
      }
    }
  }

  Future<Map<String, dynamic>> getSearchContinuation(Map additionalParamsNext,
      {int limit = 10}) async {
    final data = additionalParamsNext['data'];
    final type = additionalParamsNext['type'];
    final category = additionalParamsNext['category'];
    final Map<String, dynamic> searchResults = {};

    requestFunc(additionalParams) async =>
        (await _sendRequest("search", data, additionalParams: additionalParams))
            .data;

    parseFunc(contents) => parseSearchResults(contents,
        ['artist', 'playlist', 'song', 'video', 'station', 'podcast', 'episode', 'profile'], type, category);

    final x = await getContinuations(
        {}, 'musicShelfContinuation', limit, requestFunc, parseFunc,
        isAdditionparamReturnReq: true,
        additionalParams_: additionalParamsNext['additionalParams']);

    searchResults["params"] = {
      "data": data,
      "type": type,
      "category": category,
      'additionalParams': x[1],
    };

    searchResults[category] = x[0];
    return searchResults;
  }
  Future<Map<String, dynamic>> getArtist(String channelId) async {
    if (channelId.startsWith("MPLA")) {
      channelId = channelId.substring(4);
    }
    final data = Map.from(_context);
    data['context']['client']["hl"] = 'en';
    data['browseId'] = channelId;
    final response = (await _sendRequest("browse", data)).data;
    final results = nav(response, [...single_column_tab, ...section_list]) ?? [];

    final Map<String, dynamic> artist = {'description': null, 'views': null};
    
    // Header can be immersive, visual, or responsive (for profiles)
    final dynamic header = response['header']?['musicImmersiveHeaderRenderer'] ??
        response['header']?['musicVisualHeaderRenderer'] ??
        response['header']?['musicHeaderRenderer'] ??
        response['header']?['musicEditablePlaylistDetailHeaderRenderer']?['header']?['musicResponsiveHeaderRenderer'];

    if (header != null) {
      artist['name'] = nav(header, title_text) ?? nav(header, ['title', 'runs', 0, 'text']);
      artist['thumbnails'] = nav(header, thumbnails) ??
          nav(header, thumbnail_renderer) ??
          nav(header, ['thumbnail', 'thumbnails']) ??
          [{'url': ''}];
      
      final dynamic subscriptionButton = header['subscriptionButton'] != null
          ? header['subscriptionButton']['subscribeButtonRenderer']
          : null;
      
      artist['subscribers'] = subscriptionButton != null
          ? nav(subscriptionButton, ['subscriberCountText', 'runs', 0, 'text'])
          : null;
      
      artist['isSubscribed'] = subscriptionButton != null ? (nav(subscriptionButton, ['subscribed']) ?? false) : false;
      artist['monthlyListeners'] = nav(header, ['monthlyListenerCount', 'runs', 0, 'text']);
      
      artist['shuffleId'] = nav(header, ['playButton', 'buttonRenderer', ...navigation_watch_playlist_id]);
      artist['radioId'] = nav(header, ['startRadioButton', 'buttonRenderer'] + navigation_playlist_id);
    }

    artist['channelId'] = channelId;
    
    final descriptionShelf = findObjectByKey(results, description_shelf[0], isKey: true);
    if (descriptionShelf != null) {
      artist['description'] = nav(descriptionShelf, description);
      artist['views'] = descriptionShelf['subheader'] == null
          ? null
          : descriptionShelf['subheader']['runs'][0]['text'];
    }

    artist.addAll(parseArtistContents(results));
    return artist;
  }

  Future<Map<String, dynamic>> getArtistRealtedContent(
      Map<String, dynamic> browseEndpoint, String category,
      {String additionalParams = ""}) async {
    final Map<String, dynamic> result = {
      "results": [],
    };
    final data = Map.of(_context);
    browseEndpoint.remove("content");
    if (browseEndpoint.isEmpty) return result;
    data.addAll(browseEndpoint);
    final response =
        (await _sendRequest("browse", data, additionalParams: additionalParams))
            .data;

    List<dynamic> contentList = [];
    dynamic renderer;

    if (additionalParams.isNotEmpty) {
      contentList = nav(response, [
            'continuationContents',
            'gridContinuation',
            'items'
          ]) ??
          nav(response, [
            'continuationContents',
            'musicPlaylistShelfContinuation',
            'contents'
          ]) ??
          nav(response, [
            'continuationContents',
            'musicShelfContinuation',
            'contents'
          ]) ??
          nav(response, [
            'onResponseReceivedActions',
            0,
            'appendContinuationItemsAction',
            'continuationItems'
          ]) ??
          [];
      result['additionalParams'] = _continuationParamsFromResponse(response);
    } else {
      final firstSection = nav(response, [
        'contents',
        'singleColumnBrowseResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
        0,
      ]);
      renderer = firstSection?['gridRenderer'] ??
          firstSection?['musicCarouselShelfRenderer'] ??
          firstSection?['musicShelfRenderer'] ??
          firstSection?['musicPlaylistShelfRenderer'];
      contentList = renderer?['items'] ?? renderer?['contents'] ?? [];
      result['additionalParams'] = renderer == null
          ? '&ctoken=null&continuation=null'
          : _continuationParamsFromRenderer(renderer);
    }

    result['results'] = _parseArtistRelatedItems(contentList, category);
    return result;
  }

  List<dynamic> _parseArtistRelatedItems(List<dynamic> contentList, String category) {
    return contentList
        .map((item) {
          if (item.containsKey(mtrir)) {
            return category == 'Singles'
                ? parseSingle(item[mtrir])
                : parseTwoRowItem(item[mtrir]);
          }
          if (item.containsKey(mrlir)) {
            final renderer = Map<String, dynamic>.from(item[mrlir]);
            return isEpisodeRenderer(renderer)
                ? parseEpisodeFlat(renderer)
                : parseSongFlat(renderer);
          }
          if (item.containsKey(mmrlir)) {
            return parseMultiRowEpisode(item[mmrlir]);
          }
          return null;
        })
        .whereType<dynamic>()
        .toList();
  }

  Future<String?> getSongYear(String songId) async {
    final data = Map.from(_context);
    data['browseId'] = "MPTC$songId";
    try {
      final response = (await _sendRequest('browse', data)).data;
      String? year = nav(response, [
        "onResponseReceivedActions",
        0,
        "openPopupAction",
        "popup",
        "dismissableDialogRenderer",
        "metadata",
        "musicMultiRowListItemRenderer",
        "secondTitle",
        "runs",
        2,
        "text"
      ]);
      return year;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> home() async {
    final data = Map.from(_context);
    data["browseId"] = "FEmusic_home";
    final response = await _sendRequest("browse", data);
    final results = nav(response.data, single_column_tab + section_list) ?? [];
    return parseMixedContent(results);
  }

  Future<dynamic> explore({int limit = 4}) async {
    final data = Map.from(_context);
    data["browseId"] = "FEmusic_explore";
    final response = await _sendRequest("browse", data);
    final results = nav(response.data, single_column_tab + section_list) ?? [];
    return parseMixedContent(results).take(limit).toList();
  }

  Future<dynamic> podcastDiscover({int limit = 4}) async {
    final data = Map.from(_context);
    data["browseId"] = "FEmusic_non_music_audio";
    final response = await _sendRequest("browse", data);
    final results = nav(response.data, single_column_tab + section_list) ?? [];
    final home = [...parseMixedContent(results)];
    return home;
  }

  Future<Map<String, dynamic>> podcast(String channelId) async {
    final data = Map.from(_context);
    data['context']['client']["hl"] = 'en';
    data['browseId'] = channelId;
    final response = (await _sendRequest("browse", data)).data;

    final sectionListRenderer = nav(response, [
          'contents',
          'twoColumnBrowseResultsRenderer',
          'tabs',
          0,
          'tabRenderer',
          'content',
          'sectionListRenderer'
        ]) ??
        nav(response, [
          'contents',
          'singleColumnBrowseResultsRenderer',
          'tabs',
          0,
          'tabRenderer',
          'content',
          'sectionListRenderer'
        ]);
    final results = nav(sectionListRenderer, ['contents']) ?? [];

    final header = nav(results, [0, 'musicResponsiveHeaderRenderer']) ??
        response['header']?['podcastHeaderRenderer'] ??
        response['header']?['musicImmersiveHeaderRenderer'] ??
        response['header']?['musicVisualHeaderRenderer'];

    final secondarySections = nav(response, [
          'contents',
          'twoColumnBrowseResultsRenderer',
          'secondaryContents',
          'sectionListRenderer',
          'contents'
        ]) ??
        results;

    final descriptionShelf =
        findObjectByKey(results, description_shelf[0], isKey: true) ??
            findObjectByKey(secondarySections, description_shelf[0], isKey: true);

    final title = nav(header, title_text) ?? "";
    final authorRun = nav(header, ['straplineTextOne', 'runs', 0]);
    final thumbnailsList = nav(header, thumbnails) ??
        nav(header, thumbnail_renderer) ??
        nav(header, [
          'thumbnail',
          'musicThumbnailRenderer',
          'thumbnail',
          'thumbnails'
        ]) ??
        [{'url': ''}];

    List<dynamic>? episodeContents;
    dynamic episodeShelf;
    for (final section in secondarySections) {
      episodeShelf = section['musicShelfRenderer'] ??
          section['musicPlaylistShelfRenderer'];
      if (episodeShelf != null) {
        episodeContents = episodeShelf['contents'];
        if (episodeContents != null) break;
      }
    }

    final podcastRef = {'id': channelId, 'title': title};
    final episodes = (episodeContents ?? [])
        .map((item) {
          if (item.containsKey(mmrlir)) {
            return parseMultiRowEpisode(item[mmrlir], podcast: podcastRef);
          }
          if (item.containsKey(mrlir)) {
            return parseEpisodeFlat(Map<String, dynamic>.from(item[mrlir]));
          }
          if (item.containsKey(mtrir)) {
            return parseEpisode(item[mtrir]);
          }
          return null;
        })
        .whereType<MediaItem>()
        .toList();

    final Map<String, dynamic> podcastData = {
      'title': title,
      'name': title,
      'browseId': channelId,
      'channelId': channelId,
      'description': nav(descriptionShelf, description),
      'thumbnails': thumbnailsList,
      'isPodcast': true,
      'artists': authorRun == null
          ? [
              {'name': ''}
            ]
          : [
              {
                'name': authorRun['text'],
                'id': nav(authorRun, navigation_browse_id),
              }
            ],
      'episodeCount': nav(header, ['secondSubtitle', 'runs', 0, 'text']),
      'tracks': episodes,
      'Episodes': {
        'content': episodes,
        'additionalParams': episodeShelf == null
            ? '&ctoken=null&continuation=null'
            : _continuationParamsFromRenderer(episodeShelf),
      },
    };

    podcastData.addAll(parseArtistContents(results));
    podcastData['tracks'] = episodes;
    podcastData['Episodes'] = {
      'content': episodes,
      'additionalParams': episodeShelf == null
          ? '&ctoken=null&continuation=null'
          : _continuationParamsFromRenderer(episodeShelf),
    };

    return podcastData;
  }

  Future<List<dynamic>> getPodcastEpisodes(String browseId, String params, {int limit = 100}) async {
    final data = Map.from(_context);
    data['browseId'] = browseId;
    data['params'] = params;
    
    final response = (await _sendRequest("browse", data)).data;
    final results = nav(response, [...single_column_tab, ...section_list, 0, 'musicPlaylistShelfRenderer', 'contents']) ?? [];
    
    final episodes = parsePlaylistItems(results);
    return episodes;
  }

  Future<List<dynamic>> savedPodcastShows() async {
    final data = Map.from(_context);
    data['browseId'] = "FEmusic_library_non_music_audio_list";
    try {
      final response = (await _sendRequest("browse", data)).data;
      final contents = nav(response, [
        'contents',
        'singleColumnBrowseResultsRenderer',
        'tabs',
        0,
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
        0
      ]);

      List items = [];
      if (contents?['gridRenderer'] != null) {
        items = contents?['gridRenderer']['items']
            ?.map((item) => parseTwoRowItem(item['musicTwoRowItemRenderer']))
            ?.whereType<dynamic>()
            ?.toList() ?? [];
      } else if (contents?['musicShelfRenderer'] != null) {
        items = contents?['musicShelfRenderer']['contents']
            ?.map((item) => parseSongFlat(item['musicResponsiveListItemRenderer']))
            ?.whereType<dynamic>()
            ?.toList() ?? [];
      }
      return items.where((element) => element.isPodcast == true).toList();
    } catch (e) {
      printERROR("savedPodcastShows failed: $e");
      return [];
    }
  }

  Future<List<dynamic>> episodesForLater() async {
    final data = Map.from(_context);
    data['browseId'] = "VLSE";
    try {
      final response = (await _sendRequest("browse", data)).data;
      final contents = nav(response, [
        'contents',
        'twoColumnBrowseResultsRenderer',
        'secondaryContents',
        'sectionListRenderer',
        'contents',
        0
      ]);

      final shelfContents = contents?['musicPlaylistShelfRenderer']?['contents'] ??
          contents?['musicShelfRenderer']?['contents'];

      if (shelfContents == null) return [];

      return shelfContents
          .map((item) => parseEpisodeFlat(item['musicResponsiveListItemRenderer'] ?? item))
          .where((item) => item != null)
          .toList();
    } catch (e) {
      printERROR("episodesForLater failed: $e");
      return [];
    }
  }


  String _continuationParamsFromRenderer(dynamic renderer) {
    final continuationKey = nav(renderer, [
      'continuations',
      0,
      'nextContinuationData',
      'continuation'
    ]);
    return continuationKey == null
        ? '&ctoken=null&continuation=null'
        : '&ctoken=$continuationKey&continuation=$continuationKey';
  }

  String _continuationParamsFromResponse(Map<String, dynamic> response) {
    final appendedItems = nav(response, [
      'onResponseReceivedActions',
      0,
      'appendContinuationItemsAction',
      'continuationItems'
    ]);
    final appendedContinuationKey =
        appendedItems is List && appendedItems.isNotEmpty
            ? nav(appendedItems.last, [
                'continuationItemRenderer',
                'continuationEndpoint',
                'continuationCommand',
                'token'
              ])
            : null;
    final continuationKey = nav(response, [
          'continuationContents',
          'gridContinuation',
          'continuations',
          0,
          'nextContinuationData',
          'continuation'
        ]) ??
        nav(response, [
          'continuationContents',
          'musicPlaylistShelfContinuation',
          'continuations',
          0,
          'nextContinuationData',
          'continuation'
        ]) ??
        nav(response, [
          'continuationContents',
          'musicShelfContinuation',
          'continuations',
          0,
          'nextContinuationData',
          'continuation'
        ]) ??
        appendedContinuationKey;
    return continuationKey == null
        ? '&ctoken=null&continuation=null'
        : '&ctoken=$continuationKey&continuation=$continuationKey';
  }

  @override
  void onClose() {
    dio.close();
    super.onClose();
  }
}

class NetworkError implements Exception {
  NetworkError({
    this.statusCode,
    this.responseData,
    this.message = "Network Error !",
  });

  final int? statusCode;
  final dynamic responseData;
  final String message;

  @override
  String toString() {
    return 'NetworkError(statusCode: $statusCode, message: $message, responseData: $responseData)';
  }
}
