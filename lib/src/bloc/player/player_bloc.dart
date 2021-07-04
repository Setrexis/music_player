import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/src/MediaLib.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:music_player/src/bloc/player/player_state.dart';
import 'package:bloc/bloc.dart';

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  DeviceModel? deviceModel;

  PlayerBloc()
      : super(AudioService.currentMediaItem == null
            ? PlayerEmpty()
            : PlayerPlaying(null, null,
                AudioService.currentMediaItem!.genre!.contains("r"))) {
    AudioService.playbackStateStream.listen((PlaybackState state) async {
      print(state.processingState.toString());
      if (state == null) this.add(PlayerStop());
      if (state.processingState == AudioProcessingState.ready) {
        MediaItem? cur = AudioService.currentMediaItem;
        print("Test sdfjsojf----------------------------------------------");
        if (cur != null) {
          if (cur.genre!.contains("r"))
            return; // Only musik in recently played no radio.
          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String?>? recetplayed = prefs.getStringList("recentlyplayed");
          if (recetplayed != null) {
            recetplayed.remove(cur.genre);
            recetplayed.insert(0, cur.genre);
            if (recetplayed.length > 100) recetplayed.removeLast();
            prefs.setStringList("recentlyplayed", recetplayed as List<String>);
          } else {
            prefs.setStringList("recentlyplayed", [cur.genre!]);
          }
        }
      }
    });
    OnAudioQuery().queryDeviceInfo().then((value) => deviceModel = value);
  }

  @override
  Stream<PlayerState> mapEventToState(PlayerEvent event) async* {
    final PlayerState currentState = state;

    if (event is PlayerPlay) {
      try {
        if (currentState is PlayerEmpty) {
          final songInfo = _loadMediaItem(event.songInfo);
          yield PlayerInitial(songInfo.items.first, false);
          await _audioManager(songInfo);
          yield PlayerPlaying(null, songInfo.items.first, false);
          final playlist = _loadPlaylist(songInfo.items.first, event.playlist!);
          await _addPlaylistToQueue(playlist.items);
          yield PlayerPlaying(playlist.items, songInfo.items.first, false);
          return;
        }
        if (currentState is PlayerPlaying) {
          final songInfo = _loadMediaItem(event.songInfo);
          yield PlayerInitial(songInfo.items.first, false);
          await AudioService.updateQueue(songInfo.items);
          final playlist = _loadPlaylist(songInfo.items.first, event.playlist!);
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

  static MediaLibrary _loadPlaylist(MediaItem first, List<SongModel> songList) {
    List<MediaItem> playlist = [];

    for (SongModel song in songList) {
      //print(song);
      playlist.add(MediaItem(
          id: song.id.toString(),
          album: song.album,
          title: song.title,
          artist: song.artist,
          genre: song.composer,
          artUri:
              song.artwork != null ? Uri.dataFromString(song.artwork!) : null,
          duration: Duration(milliseconds: song.duration)));
    }

    int i = playlist.indexOf(first);

    if (i == 0) {
      playlist.removeAt(0);
      return MediaLibrary.from(playlist);
    }
    List<MediaItem> l1 = playlist.sublist(0, i - 1);
    List<MediaItem> l2 = playlist.sublist(i + 1, playlist.length);

    l2.addAll(l1);
    return MediaLibrary.from(l2);
  }

  static MediaLibrary _loadMediaItem(SongModel first) {
    List<MediaItem> playlist = [];
    playlist.add(MediaItem(
        id: first.id.toString(),
        album: first.album,
        title: first.title,
        artist: first.artist,
        genre: first.composer,
        artUri:
            first.artwork != null ? Uri.dataFromString(first.artwork!) : null,
        duration: Duration(milliseconds: first.duration)));
    return MediaLibrary.from(playlist);
  }
}
