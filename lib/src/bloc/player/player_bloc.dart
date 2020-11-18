import 'package:audio_service/audio_service.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/src/MediaLib.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:music_player/src/bloc/player/player_state.dart';
import 'package:bloc/bloc.dart';

import 'dart:async';

import 'package:music_player/src/bloc/radio/station.dart';
import 'package:music_player/src/net/radio.dart';

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc() : super(PlayerEmpty()) {
    AudioService.playbackStateStream.listen((PlaybackState state) {
      if (state == null) this.add(PlayerStop());
    });
  }

  @override
  Stream<PlayerState> mapEventToState(PlayerEvent event) async* {
    final currentState = state;

    if (event is PlayerPlayRadio) {
      try {
        if (currentState is PlayerEmpty) {
          final songInfo = await _loadStation(event.station);
          yield PlayerInitial(songInfo.items.first, true);
          await _audioManager(songInfo);
          yield PlayerPlaying(null, songInfo.items.first, true);
          final playlist = await _loadStations(event.stations, event.station);
          await addPlaylistToQueue(playlist.items);
          yield PlayerPlaying(playlist.items, songInfo.items.first, true);
          return;
        }
        if (currentState is PlayerPlaying) {
          final songInfo = await _loadStation(event.station);
          yield PlayerInitial(songInfo.items.first, true);
          final playlist = await _loadStations(event.stations, event.station);
          await AudioService.updateQueue(playlist.items);
          yield PlayerPlaying(playlist.items, songInfo.items.first, true);
          return;
        }
      } catch (_) {
        yield PlayerFailure();
      }
    } else if (event is PlayerPlay) {
      try {
        if (currentState is PlayerEmpty) {
          final songInfo = _loadMediaItem(event.songInfo);
          yield PlayerInitial(songInfo.items.first, false);
          await _audioManager(songInfo);
          yield PlayerPlaying(null, songInfo.items.first, false);
          final playlist = _loadPlaylist(songInfo.items.first, event.playlist);
          await addPlaylistToQueue(playlist.items);
          yield PlayerPlaying(playlist.items, songInfo.items.first, false);
          return;
        }
        if (currentState is PlayerPlaying) {
          final songInfo = _loadMediaItem(event.songInfo);
          yield PlayerInitial(songInfo.items.first, false);
          await AudioService.updateQueue(songInfo.items);
          final playlist = _loadPlaylist(songInfo.items.first, event.playlist);
          await addPlaylistToQueue(playlist.items);
          yield PlayerPlaying(playlist.items, songInfo.items.first, false);
          return;
        }
      } catch (_) {
        yield PlayerFailure();
      }
    } else if (event is PlayerStop) {
      yield PlayerEmpty();
    }
  }

  Future<void> addPlaylistToQueue(List<MediaItem> playlist) async {
    return AudioService.addQueueItems(playlist);
  }

  /*void startAudioPlay(List<SongInfo> playlist, SongInfo first) {
    var d = DateTime.now();
    _timer?.cancel();
    radioPlaying = false;
    print("Start audio");
    if (AudioService.playbackState == null ||
        !(AudioService.playbackState?.playing ?? true)) {
      _audioManager(first).then((value) {
        print(d.difference(DateTime.now()).inSeconds.toString() +
            " seconds till pre load load and start");
        if (playlist.length > 300) playlist.removeRange(300, playlist.length);
        if (value)
          AudioService.addQueueItems(_loadPlaylist(first, playlist).items).then(
              (value) => print(
                  d.difference(DateTime.now()).inSeconds.toString() +
                      " sconds till playlist load complete"));
      });
    } else if (AudioService.playbackState.playing) {
      if (playlist.length > 300) playlist.removeRange(300, playlist.length);
      if (UnorderedIterableEquality()
          .equals(AudioService.queue, _loadPlaylist(first, playlist).items)) {
        if (first != null) {
          if (first.id != AudioService.currentMediaItem.genre) {
            AudioService.skipToQueueItem(AudioService.queue
                .firstWhere((element) => element.genre == first.id)
                .id);
          }
        } else {
          AudioService.updateQueue(_loadMediaItem(first).items).then((value) =>
              AudioService.addQueueItems(_loadPlaylist(first, playlist).items));
        }
      } else {
        AudioService.updateQueue(_loadMediaItem(first).items).then((value) =>
            AudioService.addQueueItems(_loadPlaylist(first, playlist).items));
      }
    }
    print(d.difference(DateTime.now()));
  }*/

  /*static void startRadioPlay(List<Station> streams, Station stream) {
    radioPlaying = true;
    _timer?.cancel();

    if (streams.length > 20) {
      streams.removeRange(20, streams.length);
    }

    if (stream != null) {
      _streamManager(stream).then((value) async {
        AudioService.addQueueItems(await _loadStreams(streams, stream));
        //startMediaItemUpdate();
      });
    }
  }

  static startMediaItemUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      updateMediaItem(timer);
    });
  }

  static updateMediaItem(Timer timer) async {
    if (radioPlaying || !AudioService.running) {
      MediaItem i = AudioService.currentMediaItem;
      String s = await OnlineRadio.getCurantTrak(i.genre);
      MediaItem newItem = MediaItem(
          id: i.id,
          album: s,
          title: i.title,
          artUri: i.artUri,
          artist: i.artist,
          genre: i.genre);
      AudioService.updateMediaItem(newItem);
    } else {
      timer.cancel();
    }
  }*/

  static Future<bool> _audioManager(MediaLibrary first) {
    final Map<String, dynamic> params = {
      'playlist': first.toJson(),
    };
    return startAudioManager(params);
  }

  static Future<bool> startAudioManager(var params) async {
    return AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
      params: params,
      androidNotificationChannelName: 'Music Player',
      androidNotificationColor: 0xFF4989a2,
      androidNotificationIcon: 'drawable/ic_notification',
      androidEnableQueue: true,
    );
  }

  static MediaLibrary _loadPlaylist(MediaItem first, List<SongInfo> songList) {
    List<MediaItem> playlist = List();

    for (SongInfo song in songList) {
      //print(song);
      playlist.add(MediaItem(
          id: "file://${song.filePath}",
          album: song.album,
          title: song.title,
          artist: song.artist,
          genre: song.id,
          artUri: song.albumArtwork ?? song.albumId,
          duration: Duration(milliseconds: int.parse(song.duration ?? "0"))));
    }

    int i = playlist.indexOf(first);

    if (i == 0) {
      playlist.removeAt(0);
      return MediaLibrary(playlist);
    }
    List<MediaItem> l1 = playlist.sublist(0, i - 1);
    List<MediaItem> l2 = playlist.sublist(i + 1, playlist.length);

    l2.addAll(l1);
    return MediaLibrary(l2);
  }

  static MediaLibrary _loadMediaItem(SongInfo first) {
    List<MediaItem> playlist = List();
    playlist.add(MediaItem(
        id: "file://${first.filePath}",
        album: first.album,
        title: first.title,
        artist: first.artist,
        genre: first.id,
        artUri: first.albumArtwork ?? first.albumId,
        duration: Duration(milliseconds: int.parse(first.duration ?? "0"))));
    return MediaLibrary(playlist);
  }

  static Future<MediaLibrary> _loadStations(
      List<Station> streams, Station stream) async {
    List<MediaItem> playlist = List();

    for (Station song in streams) {
      playlist.add(MediaItem(
          id: await OnlineRadio.getStreamPath(song.id),
          album: song.id ?? "",
          title: song.title,
          artist: song.ct ?? "",
          genre: song.id,
          artUri: song.logo ?? "",
          duration: Duration(milliseconds: 0)));
    }

    int i = playlist.indexWhere((element) => element.genre == stream.id);

    if (i != null) {
      playlist.removeAt(i);
    }

    return MediaLibrary(playlist);
  }

  static Future<MediaLibrary> _loadStation(Station stream) async {
    List<MediaItem> playlist = List();

    playlist.add(MediaItem(
        id: await OnlineRadio.getStreamPath(stream.id),
        album: stream.id ?? "",
        title: stream.title,
        artist: stream.ct ?? "",
        genre: stream.id,
        artUri: stream.logo ?? "",
        duration: Duration(milliseconds: 0)));
    return MediaLibrary(playlist);
  }
}
