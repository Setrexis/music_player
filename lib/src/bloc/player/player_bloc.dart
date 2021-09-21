import 'dart:ffi';

import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:music_player/src/bloc/player/player_state.dart';
import 'package:bloc/bloc.dart';
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

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
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

  BehaviorSubject<List<SongModel>> get songs$ => _songs$;
  BehaviorSubject<List<SongModel>> get playlist$ => _playlist$;
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
      await OnAudioQuery().permissionsRequest();
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
          (queue, mediaItem) => QueueState(queue, mediaItem));

  Stream<bool> get playingStream =>
      audioHandler.playbackState.map((s) => s.playing);

  PlayerBloc(AudioHandler _audioHandler)
      : super(_audioHandler.mediaItem.value != null
            ? PlayerPlaying()
            : PlayerEmpty()) {
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
    fetchMusicInformation();
    OnAudioQuery().queryDeviceInfo().then((value) => deviceModel = value);
    this._audioHandler.queue.listen((event) {
      updatePlaylist();
    });
    this._audioHandler.mediaItem.listen((event) {
      updatePlaylist();
    });
  }

  updatePlaylist() {
    List<SongModel> queue = [];
    List<SongModel> playlist = _songs$.value;
    this
        ._audioHandler
        .queue
        .value
        .skipWhile((value) => value == this._audioHandler.mediaItem.value)
        .forEach((element) {
      playlist.forEach((element2) {
        if (element.id == element2.uri) {
          queue.add(element2);
        }
      });
    });
    _playlist$.add(queue);
  }

  @override
  Stream<PlayerState> mapEventToState(PlayerEvent event) async* {
    final PlayerState currentState = state;

    if (event is PlayerPlay) {
      try {
        if (currentState is PlayerEmpty) {
          int sdk = deviceModel!.version;
          await _audioHandler.updateQueue(event.playlist
              .map((e) => MediaItem(
                  id: e.uri!,
                  title: e.title,
                  artUri: Uri.parse("content://media/external/audio/albumart/" +
                      e.id.toString()),
                  album: e.album,
                  artist: e.artist,
                  extras: Map.fromIterables(["id", "sdk"], [e.id, sdk]),
                  duration: Duration(milliseconds: e.duration!)))
              .toList());
          _playlist$.add(event.playlist.sublist(1));
        }
        if (currentState is PlayerPlaying) {}
      } catch (_) {
        yield PlayerFailure();
      }
    } else if (event is PlayerStop) {
      yield PlayerEmpty();
    }
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
    _audioHandler.removeQueueItem(
        _audioHandler.queue.value.firstWhere((element) => element.id == uri));
  }

  addItemToQuoue(SongModel song) {
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
