import 'package:audio_service/audio_service.dart';
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

class PlayerBloc {
  DeviceModel? deviceModel;
  late AudioHandler _audioHandler;
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
  AudioHandler get audioHandler => _audioHandler;

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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? songIDs = prefs.getStringList("favorits");
      List<SongModel> favSongs = [];
      if (songIDs != null) {
        value.forEach((element) {
          songIDs.forEach((element2) {
            if (element.id.toString() == element2) {
              favSongs.add(element);
            }
          });
        });
      }
      _favorits$.add(favSongs);
    });

    favorits$.listen((value) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList(
          "favorits", favorits$.value.map((e) => e.id.toString()).toList());
    });
  }

  void search(String search) {
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
        .toList());
  }

  void _searchAlbums(String search) async {
    _albumsSearch$.add(_albums$.value
        .where((element) =>
            element.album.toLowerCase().contains(search.toLowerCase()))
        .toList());
  }

  void _searchArtists(String search) async {
    _artistsSearch$.add(_artists$.value
        .where((element) =>
            element.artist.toLowerCase().contains(search.toLowerCase()))
        .toList());
  }

  void _searchPlaylists(String search) async {
    _playlistsSearch$.add(_playlists$.value
        .where((element) =>
            element.playlist.toLowerCase().contains(search.toLowerCase()))
        .toList());
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

  PlayerBloc(AudioHandler _audioHandler) {
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

  updatePlaylist() {
    int songIndex = inbetweenqueue$.value.indexWhere((element) =>
        element.id == this._audioHandler.mediaItem.value!.extras!['id']);
    if (songIndex == -1) {
      print("not in inbetweenque");
    } else {
      inbetweenqueue$.add(inbetweenqueue$.value..removeAt(songIndex));
    }
    print(songs$.hasValue);

    List<SongModel> songs = [];
    for (MediaItem i in _audioHandler.queue.value.skip(
        _audioHandler.queue.value.indexOf(this._audioHandler.mediaItem.value!) +
            1 +
            _inbetweenqueue$.value.length)) {
      songs.add(
          _songs$.value.firstWhere((element) => element.id == i.extras!['id']));
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
        _audioHandler.queue.value.indexOf(this._audioHandler.mediaItem.value!),
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
