import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/src/MediaLib.dart';
import 'package:music_player/src/net/radio.dart';
import 'package:xml/xml.dart';

class Utility {
  /// Simple method to format milliseconds time in mm:ss  minutes:seconds format.
  /// [ms] milliseconds number
  static String parseToMinutesSeconds(int ms) {
    String data;
    Duration duration = Duration(milliseconds: ms);

    int minutes = duration.inMinutes;
    int seconds = (duration.inSeconds) - (minutes * 60);

    data = minutes.toString() + ":";
    if (seconds <= 9) data += "0";

    data += seconds.toString();
    return data;
  }

  static Widget createDefaultInfoWidget(final Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Center(
          child: child,
        ),
      ],
    );
  }
}

class Seeker {
  final AudioPlayer player;
  final Duration positionInterval;
  final Duration stepInterval;
  final MediaItem mediaItem;
  bool _running = false;

  Seeker(
    this.player,
    this.positionInterval,
    this.stepInterval,
    this.mediaItem,
  );

  start() async {
    _running = true;
    while (_running) {
      Duration newPosition = player.position + positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
      player.seek(newPosition);
      await Future.delayed(stepInterval);
    }
  }

  stop() {
    _running = false;
  }
}

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class PlayerService {
  static bool radioPlaying;
  static Timer _timer;

  static void startAudioPlay(List<SongInfo> playlist, SongInfo first) {
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
          AudioService.updateQueue(_loadPlaylistPre(first).items).then(
              (value) => AudioService.addQueueItems(
                  _loadPlaylist(first, playlist).items));
        }
      } else {
        AudioService.updateQueue(_loadPlaylistPre(first).items).then((value) =>
            AudioService.addQueueItems(_loadPlaylist(first, playlist).items));
      }
    }
    print(d.difference(DateTime.now()));
  }

  static void startRadioPlay(List<XmlElement> streams, XmlElement stream) {
    radioPlaying = true;
    _timer?.cancel();

    if (streams.length > 20) {
      streams.removeRange(20, streams.length);
    }

    if (stream != null) {
      _streamManager(stream).then((value) async {
        AudioService.addQueueItems(await _loadStreams(streams, stream));
        startMediaItemUpdate();
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
    if (radioPlaying) {
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
  }

  static Future<bool> _audioManager(SongInfo first) {
    MediaLibrary library = _loadPlaylistPre(first);
    final Map<String, dynamic> params = {
      'playlist': library.toJson(),
    };
    return startAudioManager(params);
  }

  static Future<bool> _streamManager(XmlElement stream) async {
    print("Load Streams");
    MediaLibrary library = await _loadStreamsPre(stream);
    print("Strams Loaded");
    final Map<String, dynamic> params = {
      'playlist': library.toJson(),
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

  static MediaLibrary _loadPlaylist(SongInfo first, List<SongInfo> songList) {
    var d = DateTime.now();

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

    int i = playlist
        .indexOf(playlist.firstWhere((element) => element.genre == first.id));

    if (i == 0) {
      playlist.removeAt(0);
      return MediaLibrary(playlist);
    }
    List<MediaItem> l1 = playlist.sublist(0, i - 1);
    List<MediaItem> l2 = playlist.sublist(i + 1, playlist.length);

    l2.addAll(l1);

    print(d.difference(DateTime.now()));
    return MediaLibrary(l2);
  }

  static MediaLibrary _loadPlaylistPre(SongInfo first) {
    var d = DateTime.now();

    List<MediaItem> playlist = List();

    playlist.add(MediaItem(
        id: "file://${first.filePath}",
        album: first.album,
        title: first.title,
        artist: first.artist,
        genre: first.id,
        artUri: first.albumArtwork ?? first.albumId,
        duration: Duration(milliseconds: int.parse(first.duration ?? "0"))));

    print(d.difference(DateTime.now()));
    return MediaLibrary(playlist);
  }

  static Future<List<MediaItem>> _loadStreams(
      List<XmlElement> streams, XmlElement stream) async {
    List<MediaItem> playlist = List();

    for (XmlElement song in streams) {
      playlist.add(MediaItem(
          id: await OnlineRadio.getStreamPath(song.getAttribute("id")),
          album: song.getAttribute("genre") ?? "",
          title: song.getAttribute("name"),
          artist: song.getAttribute("ct") ?? "",
          genre: song.getAttribute("id"),
          artUri: song.getAttribute("logo") ?? "",
          duration: Duration(milliseconds: 0)));
    }

    int i = playlist
        .indexWhere((element) => element.genre == stream.getAttribute("id"));

    if (i != null) {
      playlist.removeAt(i);
    }

    return playlist;
  }

  static Future<MediaLibrary> _loadStreamsPre(XmlElement stream) async {
    List<MediaItem> playlist = List();

    playlist.add(MediaItem(
        id: await OnlineRadio.getStreamPath(stream.getAttribute("id")),
        album: stream.getAttribute("genre") ?? "",
        title: stream.getAttribute("name"),
        artist: stream.getAttribute("ct") ?? "",
        genre: stream.getAttribute("id"),
        artUri: stream.getAttribute("logo") ?? "",
        duration: Duration(milliseconds: 0)));
    return MediaLibrary(playlist);
  }
}
