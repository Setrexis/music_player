import 'package:audio_service/audio_service.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

enum Playback {
  repeatSong,
  shuffle,
}

class QueueState {
  final List<MediaItem>? queue;
  final MediaItem? mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;
  final bool playing;

  MediaState(this.mediaItem, this.position, this.playing);
}

class SongAlbumStream {
  final List<SongModel> songs;
  final List<AlbumModel> albums;

  SongAlbumStream(this.songs, this.albums);
}

class ModelQueueStream {
  final List<SongModel> inbetweenqueue;
  final List<SongModel> playlist;

  ModelQueueStream(this.inbetweenqueue, this.playlist);
}

class CombinedSearchStream {
  late final List<dynamic> searchElements;

  CombinedSearchStream(
      songs, albums, artists, playlists, String search, List<bool> searchIn) {
    search = search.toLowerCase();
    searchElements = [];

    if (searchIn.any((element) => element)) {
      if (searchIn[0]) searchElements.addAll(songs);
      if (searchIn[1]) searchElements.addAll(albums);
      if (searchIn[2]) searchElements.addAll(artists);
      if (searchIn[3]) searchElements.addAll(playlists);
    } else {
      searchElements.addAll(songs);
      searchElements.addAll(albums);
      searchElements.addAll(artists);
      searchElements.addAll(playlists);
    }

    searchElements.sort((a, b) {
      int start_index_a;
      int start_index_b;
      switch (a.runtimeType) {
        case SongModel:
          start_index_a = (a as SongModel).title.toLowerCase().indexOf(search);
          break;
        case AlbumModel:
          start_index_a = (a as AlbumModel).album.toLowerCase().indexOf(search);
          break;
        case ArtistModel:
          start_index_a =
              (a as ArtistModel).artist.toLowerCase().indexOf(search);
          break;
        case PlaylistModel:
          start_index_a =
              (a as PlaylistModel).playlist.toLowerCase().indexOf(search);
          break;
        default:
          start_index_a = -1;
      }
      switch (b.runtimeType) {
        case SongModel:
          start_index_b = (b as SongModel).title.toLowerCase().indexOf(search);
          break;
        case AlbumModel:
          start_index_b = (b as AlbumModel).album.toLowerCase().indexOf(search);
          break;
        case ArtistModel:
          start_index_b =
              (b as ArtistModel).artist.toLowerCase().indexOf(search);
          break;
        case PlaylistModel:
          start_index_b =
              (b as PlaylistModel).playlist.toLowerCase().indexOf(search);
          break;
        default:
          start_index_b = -1;
      }

      return a == b
          ? 0
          : start_index_a == -1
              ? 1
              : start_index_b == -1
                  ? -1
                  : start_index_a - start_index_b;
    });
  }
}

class PlayerBloc {
  DeviceModel? deviceModel;
  late AudioPlayerHandler _audioHandler;
  late BehaviorSubject<List<SongModel>> _songs$;
  late BehaviorSubject<List<AlbumModel>> _albums$;
  late BehaviorSubject<List<PlaylistModel>> _playlists$;
  late BehaviorSubject<List<ArtistModel>> _artists$;
  late BehaviorSubject<List<SongModel>> _favorits$;
  late BehaviorSubject<List<SongModel>> _songsSearch$;
  late BehaviorSubject<List<AlbumModel>> _albumsSearch$;
  late BehaviorSubject<List<PlaylistModel>> _playlistsSearch$;
  late BehaviorSubject<List<ArtistModel>> _artistsSearch$;
  late BehaviorSubject<List<SongModel>> _playlist$;
  late BehaviorSubject<List<SongModel>> _queue$;
  late BehaviorSubject<List<SongModel>> _inbetweenqueue$;
  late BehaviorSubject<List<dynamic>> _searchHistory$;

  BehaviorSubject<List<SongModel>> get songs$ => _songs$;
  BehaviorSubject<List<SongModel>> get playlist$ => _playlist$;
  BehaviorSubject<List<SongModel>> get inbetweenqueue$ => _inbetweenqueue$;
  BehaviorSubject<List<AlbumModel>> get albums$ => _albums$;
  BehaviorSubject<List<ArtistModel>> get artists$ => _artists$;
  BehaviorSubject<List<PlaylistModel>> get playlists$ => _playlists$;
  BehaviorSubject<List<SongModel>> get songsSearch$ => _songsSearch$;
  BehaviorSubject<List<AlbumModel>> get albumsSearch$ => _albumsSearch$;
  BehaviorSubject<List<ArtistModel>> get artistsSearch$ => _artistsSearch$;
  BehaviorSubject<List<PlaylistModel>> get playlistsSearch$ =>
      _playlistsSearch$;
  BehaviorSubject<List<SongModel>> get favorits$ => _favorits$;
  BehaviorSubject<List<dynamic>> get searchHistory$ => _searchHistory$;
  AudioPlayerHandler get audioHandler => _audioHandler;

  String search_term = "";
  late final SharedPreferences prefs;

  Map<int, List<SongModel>> _playlistCache = {};

  Future<void> fetchMusicInformation() async {
    if (!await OnAudioQuery().permissionsStatus()) {
      print("requesting permission");
      print(await OnAudioQuery().permissionsRequest());
    }
    OnAudioQuery().queryArtists().then((value) => _artists$.add(value));
    OnAudioQuery().queryAlbums().then((value) => _albums$.add(value));
    OnAudioQuery().queryPlaylists().then((value) => _playlists$.add(value));
    OnAudioQuery().querySongs().then((value) async {
      _songs$.add(value);
      print(value.length);
      prefs = await SharedPreferences.getInstance();
      List<String> songIDs =
          prefs.getStringList("favorits")?.reversed.toList() ?? [];
      List<SongModel> favSongs = [];
      songIDs.forEach((element2) {
        value.forEach((element) {
          if (element.id.toString() == element2) {
            favSongs.add(element);
          }
        });
      });
      _favorits$.add(favSongs);
    });

    favorits$.listen((value) async {
      prefs.setStringList(
          "favorits", value.map((e) => e.id.toString()).toList());
    });

    searchHistory$.listen((value) {
      prefs.setStringList(
          "searchHistory",
          value.take(30).map((e) {
            if (e is SongModel) {
              return "s" + e.id.toString();
            } else if (e is AlbumModel) {
              return "a" + e.id.toString();
            } else if (e is ArtistModel) {
              return "r" + e.id.toString();
            } else if (e is PlaylistModel) {
              return "p" + e.id.toString();
            } else {
              return "";
            }
          }).toList());
    });

    Timer(Duration(milliseconds: 1000), () {
      List<dynamic> searchHistory = [];
      prefs.getStringList("searchHistory")?.forEach((element) {
        if (element.startsWith("s")) {
          int id = int.parse(element.substring(1));
          searchHistory
              .add(_songs$.value.firstWhere((element) => element.id == id));
        } else if (element.startsWith("a")) {
          int id = int.parse(element.substring(1));
          searchHistory
              .add(_albums$.value.firstWhere((element) => element.id == id));
        } else if (element.startsWith("r")) {
          int id = int.parse(element.substring(1));
          searchHistory
              .add(_artists$.value.firstWhere((element) => element.id == id));
        } else if (element.startsWith("p")) {
          int id = int.parse(element.substring(1));
          searchHistory
              .add(_playlists$.value.firstWhere((element) => element.id == id));
        }
      });
      _searchHistory$.add(searchHistory);
    });
  }

  Stream<CombinedSearchStream> combinedSearchStreams(isSelected) =>
      Rx.combineLatest4<List<SongModel>, List<AlbumModel>, List<ArtistModel>,
                  List<PlaylistModel>, CombinedSearchStream>(
              _songsSearch$,
              _albumsSearch$,
              _artistsSearch$,
              _playlistsSearch$,
              (a, b, c, d) =>
                  CombinedSearchStream(a, b, c, d, search_term, isSelected))
          .asBroadcastStream();

  void search(String search) {
    search_term = search;
    /*if (search.trim() == "") {
      _songsSearch$.add([]);
      _albumsSearch$.add([]);
      _playlistsSearch$.add([]);
      _artistsSearch$.add([]);
      return;
    }*/
    _searchArtists(search);
    _searchPlaylists(search);
    _searchAlbums(search);
    _searchSongs(search);
  }

  void _searchSongs(String search) async {
    _songsSearch$.add(_songs$.value
        .where((element) =>
            element.title.toLowerCase().contains(search.toLowerCase()))
        .take(20)
        .toList());
  }

  void _searchAlbums(String search) async {
    _albumsSearch$.add(_albums$.value
        .where((element) =>
            element.album.toLowerCase().contains(search.toLowerCase()))
        .take(20)
        .toList());
  }

  void _searchArtists(String search) async {
    _artistsSearch$.add(_artists$.value
        .where((element) =>
            element.artist.toLowerCase().contains(search.toLowerCase()))
        .take(20)
        .toList());
  }

  void _searchPlaylists(String search) async {
    _playlistsSearch$.add(_playlists$.value
        .where((element) =>
            element.playlist.toLowerCase().contains(search.toLowerCase()))
        .take(20)
        .toList());
  }

  Future<List<SongModel>> getPlaylistSongs(int id) async {
    if (_playlistCache.containsKey(id)) {
      return _playlistCache[id]!;
    }

    List<SongModel> songs =
        await OnAudioQuery().queryAudiosFrom(AudiosFromType.PLAYLIST, id);

    _playlistCache[id] = songs;

    return songs;
  }

  Stream<ModelQueueStream> get modelQueueStram =>
      Rx.combineLatest2<List<SongModel>, List<SongModel>, ModelQueueStream>(
          _inbetweenqueue$.stream,
          _playlist$.stream,
          (a, b) => ModelQueueStream(a, b));

  Stream<SongAlbumStream> get songAlbumStream =>
      Rx.combineLatest2<List<SongModel>, List<AlbumModel>, SongAlbumStream>(
          _songs$.stream, _albums$.stream, (a, b) => SongAlbumStream(a, b));

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get mediaStateStream =>
      Rx.combineLatest3<MediaItem?, Duration, bool, MediaState>(
          _audioHandler.mediaItem,
          AudioService.position,
          playingStream,
          (mediaItem, position, playing) =>
              MediaState(mediaItem, position, playing));

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  Stream<QueueState> get queueStateStream =>
      Rx.combineLatest2<List<MediaItem>?, MediaItem?, QueueState>(
              _audioHandler.queue,
              _audioHandler.mediaItem,
              (queue, mediaItem) => QueueState(queue, mediaItem))
          .asBroadcastStream();

  Stream<bool> get playingStream =>
      audioHandler.playbackState.map((s) => s.playing);

  PlayerBloc(AudioPlayerHandler _audioHandler) {
    this._audioHandler = _audioHandler;
    _songs$ = BehaviorSubject();
    _albums$ = BehaviorSubject();
    _artists$ = BehaviorSubject();
    _playlists$ = BehaviorSubject();
    _playlist$ = BehaviorSubject();
    _favorits$ = BehaviorSubject();
    _songsSearch$ = BehaviorSubject();
    _albumsSearch$ = BehaviorSubject();
    _artistsSearch$ = BehaviorSubject();
    _playlistsSearch$ = BehaviorSubject();
    _inbetweenqueue$ = BehaviorSubject();
    _queue$ = BehaviorSubject();
    _searchHistory$ = BehaviorSubject();

    fetchMusicInformation();
    OnAudioQuery().queryDeviceInfo().then((value) => deviceModel = value);
    this.audioHandler.queue.listen((event) {
      updatePlaylist();
    });
    this.audioHandler.mediaItem.listen((event) {
      updatePlaylist();
    });
    this.audioHandler.queue.listen((value) {
      print("--- Playlist ---");
      print(value);
    });
  }

  void addToSearchHistory(dynamic element) {
    _searchHistory$.add(_searchHistory$.value..insert(0, element));
  }

  updatePlaylist() {
    if (!inbetweenqueue$.hasValue) {
      return;
    }
    int songIndex = inbetweenqueue$.value.indexWhere((element) =>
        element.id == this._audioHandler.mediaItem.value!.extras!['id']);
    if (songIndex == -1) {
      print("not in inbetweenque");
    } else {
      inbetweenqueue$.add(inbetweenqueue$.value..removeAt(songIndex));
    }
    print(songs$.hasValue);

    List<SongModel> songs = [];
    if (this._audioHandler.mediaItem.value != null) {
      for (MediaItem i in _audioHandler.queue.value.skip(_audioHandler
              .queue.value
              .indexOf(this._audioHandler.mediaItem.value!) +
          1 +
          _inbetweenqueue$.value.length)) {
        songs.add(_songs$.value
            .firstWhere((element) => element.id == i.extras!['id']));
      }
    }

    _playlist$.add(songs);

    /*_queue$.add(_songs$.value
        .where((element) => _audioHandler.queue.value
            .any((element2) => element.id == element2.extras!['id']))
        .toList());*/
  }

  void startPlayback(List<SongModel> playlist) async {
    int sdk = deviceModel!.version;
    inbetweenqueue$.add([]);
    await _audioHandler.updateQueue(playlist
        .map((e) => MediaItem(
            id: e.uri!,
            title: e.title,
            artUri: Uri.parse(
                "content://media/external/audio/albumart/" + e.id.toString()),
            album: e.album,
            artist: e.artist,
            extras: Map.fromIterables(["id", "sdk"], [e.id, sdk]),
            duration: Duration(milliseconds: e.duration!)))
        .toList());
    await _audioHandler.play();
  }

  addToFavorits(int id) {
    favorits$.add(favorits$.value
      ..add(songs$.value.firstWhere((element) => element.id == id)));
  }

  removeFromFavorits(int id) {
    favorits$.add(favorits$.value
      ..remove(songs$.value.firstWhere((element) => element.id == id)));
  }

  switchQueueItems(int newIndex, String uri) async {
    print("ksjfklsdf");
    MediaItem m =
        _audioHandler.queue.value.firstWhere((element) => element.id == uri);
    await _audioHandler.removeQueueItem(m);
    print("sakdfkl");
    _audioHandler.insertQueueItem(
        newIndex +
            _audioHandler.queue.value
                .indexOf(this._audioHandler.mediaItem.value!),
        m);
  }

  removeQueueItem(String uri) {
    int songIndex =
        _inbetweenqueue$.value.indexWhere((element) => element.uri == uri);
    if (songIndex == -1) {
      print("Error Song not in Queue");
    } else {
      _inbetweenqueue$.add(_inbetweenqueue$.value..removeAt(songIndex));
    }
    _audioHandler.removeQueueItem(
        _audioHandler.queue.value.firstWhere((element) => element.id == uri));
  }

  addItemToQuoue(SongModel song) {
    print("Add to queue");
    print(song);
    _inbetweenqueue$.add(_inbetweenqueue$.value..add(song));
    _audioHandler.insertQueueItem(
        _audioHandler.queue.value.indexOf(this._audioHandler.mediaItem.value!) +
            _inbetweenqueue$.value.length,
        MediaItem(
            id: song.uri!,
            title: song.title,
            artUri: Uri.parse("content://media/external/audio/albumart/" +
                song.id.toString()),
            album: song.album,
            artist: song.artist,
            extras: Map.fromIterables(
                ["id", "sdk"], [song.id, deviceModel!.version]),
            duration: Duration(milliseconds: song.duration!)));
  }
}
