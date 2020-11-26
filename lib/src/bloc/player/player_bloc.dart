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
import 'package:shared_preferences/shared_preferences.dart';

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc()
      : super(AudioService.currentMediaItem == null
            ? PlayerEmpty()
            : PlayerPlaying(null, null,
                AudioService.currentMediaItem.genre.contains("r"))) {
    AudioService.playbackStateStream.listen((PlaybackState state) async {
      print(state.processingState.toString());
      if (state == null) this.add(PlayerStop());
      if (state.processingState == AudioProcessingState.ready) {
        MediaItem cur = AudioService.currentMediaItem;
        print("Test sdfjsojf----------------------------------------------");
        if (cur != null) {
          if (cur.genre.contains("r"))
            return; // Only musik in recently played no radio.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          var recetplayed = prefs.getStringList("recentlyplayed");
          if (recetplayed != null) {
            recetplayed.remove(cur.genre);
            recetplayed.insert(0, cur.genre);
            if (recetplayed.length > 100) recetplayed.removeLast();
            prefs.setStringList("recentlyplayed", recetplayed);
          } else {
            prefs.setStringList("recentlyplayed", [cur.genre]);
          }
        }
      }
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
          await _addPlaylistToQueue(playlist.items);
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
          await _addPlaylistToQueue(playlist.items);
          yield PlayerPlaying(playlist.items, songInfo.items.first, false);
          return;
        }
        if (currentState is PlayerPlaying) {
          final songInfo = _loadMediaItem(event.songInfo);
          yield PlayerInitial(songInfo.items.first, false);
          await AudioService.updateQueue(songInfo.items);
          final playlist = _loadPlaylist(songInfo.items.first, event.playlist);
          await _addPlaylistToQueue(playlist.items);
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

  Future<void> _addPlaylistToQueue(List<MediaItem> playlist) async {
    return AudioService.addQueueItems(playlist);
  }

  static Future<bool> _audioManager(MediaLibrary first) {
    final Map<String, dynamic> params = {
      'playlist': first.toJson(),
    };
    return _startAudioManager(params);
  }

  static Future<bool> _startAudioManager(var params) async =>
      AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
        params: params,
        androidNotificationChannelName: 'Music Player',
        androidNotificationColor: 0xFF4989a2,
        androidNotificationIcon: 'drawable/ic_notification',
        androidEnableQueue: true,
      );

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
          genre: song.rid,
          artUri: song.logo ?? "",
          duration: Duration(milliseconds: 0)));
    }

    int i = playlist.indexWhere((element) => element.genre == stream.rid);

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
        genre: stream.rid,
        artUri: stream.logo ?? "",
        duration: Duration(milliseconds: 0)));
    return MediaLibrary(playlist);
  }
}