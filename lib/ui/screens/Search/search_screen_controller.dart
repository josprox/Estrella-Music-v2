import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:harmonymusic/generated/l10n.dart';

import '/utils/app_link_controller.dart' show ProcessLink;
import '/services/music_service.dart';

class SearchCategory {
  final String name;
  final Color color;
  final String imageUrl;

  const SearchCategory({
    required this.name,
    required this.color,
    required this.imageUrl,
  });
}

class SearchScreenController extends GetxController with ProcessLink {
  final textInputController = TextEditingController();
  final musicServices = Get.find<MusicServices>();
  final suggestionList = [].obs;
  final historyQuerylist = [].obs;
  late Box<dynamic> queryBox;
  final urlPasted = false.obs;
  final searchText = ''.obs;

  final categories = [
    SearchCategory(
      name: S.current.genre_pop,
      color: const Color(0xFFFF007F),
      imageUrl: 'https://images.unsplash.com/photo-1514525253361-bee8a187c9bc?q=80&w=250&auto=format&fit=crop',
    ),
    SearchCategory(
      name: S.current.genre_rock,
      color: const Color(0xFF0056D2),
      imageUrl: 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?q=80&w=250&auto=format&fit=crop',
    ),
    SearchCategory(
      name: S.current.genre_hiphop,
      color: const Color(0xFFF16E00),
      imageUrl: 'https://images.unsplash.com/photo-1547153760-18fc86324498?q=80&w=250&auto=format&fit=crop',
    ),
    SearchCategory(
      name: S.current.genre_electronic,
      color: const Color(0xFF8A2BE2),
      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=250&auto=format&fit=crop',
    ),
    SearchCategory(
      name: S.current.genre_jazz,
      color: const Color(0xFFD4AF37),
      imageUrl: 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?q=80&w=250&auto=format&fit=crop',
    ),
    SearchCategory(
      name: S.current.genre_latin,
      color: const Color(0xFF008080),
      imageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?q=80&w=250&auto=format&fit=crop',
    ),
  ];

  // Desktop search bar related
  final focusNode = FocusNode();
  final isSearchBarInFocus = false.obs;

  @override
  onInit() {
    _init();
    super.onInit();
  }

  _init() async {
    if(GetPlatform.isDesktop){
      focusNode.addListener((){
        isSearchBarInFocus.value = focusNode.hasFocus;
      });
    }
    queryBox = await Hive.openBox("searchQuery");
    historyQuerylist.value = queryBox.values.toList().reversed.toList();
  }

  Future<void> onChanged(String text) async {
    searchText.value = text;
    if(text.contains("https://")){
      urlPasted.value = true; 
      return;
    }
    urlPasted.value = false;
    suggestionList.value = await musicServices.getSearchSuggestion(text);
  }

  Future<void> suggestionInput(String txt) async {
    textInputController.text = txt;
    textInputController.selection =
        TextSelection.collapsed(offset: textInputController.text.length);
    await onChanged(txt);
  }

  Future<void> addToHistryQueryList(String txt) async {
    if (historyQuerylist.length > 9) {
      final queryForRemoval = queryBox.getAt(0);
      await queryBox.deleteAt(0);
      historyQuerylist.removeWhere((element) => element == queryForRemoval);
    }
    if (!historyQuerylist.contains(txt)) {
      await queryBox.add(txt);
      historyQuerylist.insert(0, txt);
    }

    //reset current query and suggestionlist
    reset();
  }

  void reset() {
    urlPasted.value = false;
    searchText.value = "";
    textInputController.text = "";
    suggestionList.clear();
  }

  Future<void> removeQueryFromHistory(String txt) async {
    final index = queryBox.values.toList().indexOf(txt);
    await queryBox.deleteAt(index);
    historyQuerylist.remove(txt);
  }

  @override
  void dispose() {
    focusNode.dispose();
    textInputController.dispose();
    queryBox.close();
    super.dispose();
  }
}
