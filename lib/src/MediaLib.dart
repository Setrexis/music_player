import 'dart:convert';

import 'package:audio_service/audio_service.dart';

/// Provides access to a library of media items. In your app, this could come
/// from a database or web service.
class MediaLibrary {
  List<MediaItem> _items = [];

  MediaLibrary();

  MediaLibrary.from(List items) {
    _items = items as List<MediaItem>;
  }

  Map<String, List<String>> toJson() {
    List<String> _i = [];
    _items.forEach((element) {
      _i.add(jsonEncode(element));
    });
    return {'items': _i};
  }

  MediaLibrary.fromJson(Map<String, List<String>> json) {
    _items = [];
    json[json.keys.first]?.forEach((element) {
      print(MediaItem.fromJson(jsonDecode(element)));
      _items.add(MediaItem.fromJson(jsonDecode(element)));
    });
  }

  List<MediaItem> get items => _items;

  clear() {
    _items = [];
  }
}
