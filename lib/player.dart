import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:xml/xml.dart';

class PlayerSceen extends StatefulWidget {
  const PlayerSceen();

  @override
  _PlayerSceenState createState() => _PlayerSceenState();
}

class _PlayerSceenState extends State<PlayerSceen>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  StreamSubscription playinglisterner;
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));

    playinglisterner = AudioService.playbackStateStream.listen((event) {
      if (event.playing)
        _animationController.forward();
      else
        _animationController.reverse();
    });
  }

  @override
  void dispose() {
    super.dispose();
    playinglisterner.cancel();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Now playing",
          style: TextStyle(color: Color(0xFF4e606e), fontSize: 13),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            color: Color(0xFF4e606e),
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<MediaItem>(
          stream: AudioService.currentMediaItemStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            final duration = snapshot.data.duration ?? Duration.zero;

            return Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF374a59), Color(0xFF1a2a37)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 1.0],
                      tileMode: TileMode.clamp)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(40, 120, 40, 10),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width,
                    child: Center(
                      child: Container(
                        child: AlbumArtworkImage(
                          snapshot.data.genre.replaceAll("r", ""),
                          null,
                          ResourceType.SONG,
                          borderRadius: 400,
                          audioQuery: FlutterAudioQuery(),
                          size: Size(500, 500),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
                          child: Column(children: [
                            Text(
                              snapshot.data.title,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Padding(
                              padding: EdgeInsets.all(3),
                            ),
                            Text(
                              snapshot.data.album +
                                  " | " +
                                  snapshot.data.artist,
                              style: TextStyle(color: Color(0xFF4e606e)),
                            )
                          ]),
                        ),
                        StreamBuilder<Duration>(
                          stream: AudioService.positionStream,
                          builder: (context, snapshot1) {
                            var position = snapshot1.data ?? Duration.zero;
                            if (position > duration) {
                              position = duration;
                            }
                            return SeekBar(
                              duration: duration,
                              position: position,
                              onChangeEnd: (newPosition) {
                                AudioService.seekTo(newPosition);
                              },
                            );
                          },
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.skip_previous),
                              onPressed: () => AudioService.skipToPrevious(),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: GradientButton(
                                onpresss: () {
                                  AudioService.playbackState.playing
                                      ? AudioService.pause()
                                      : AudioService.play();
                                },
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF64a0a8),
                                      Color(0xFF3383a4),
                                    ]),
                                shape: CircleBorder(),
                                child: AnimatedIcon(
                                  size: 50,
                                  progress: _animationController,
                                  icon: AnimatedIcons.play_pause,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next),
                              onPressed: () => AudioService.skipToNext(),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.shuffle),
                              onPressed: () => AudioService.setShuffleMode(
                                  AudioServiceShuffleMode.all),
                            ),
                            IconButton(
                              icon: Icon(Icons.playlist_add),
                              onPressed: () => {/*Flutter audio querry*/},
                            ),
                            IconButton(
                              icon: Icon(Icons.whatshot_outlined),
                              onPressed: () => {
                                audioQuery.getPlaylists().then((value) async {
                                  if (snapshot.data.genre.contains("r")) return;
                                  List<SongInfo> i =
                                      await audioQuery.getSongsById(
                                          ids: {snapshot.data.genre}.toList());
                                  value
                                      .firstWhere((element) =>
                                          element.name == "Favoriten")
                                      .addSong(song: i[0]);
                                })
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.repeat),
                              onPressed: () => AudioService.setRepeatMode(
                                  AudioServiceRepeatMode.all),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
              widget.duration.inMilliseconds.toDouble()),
          onChanged: (value) {
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd(Duration(milliseconds: value.round()));
            }
            _dragValue = null;
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Utility.parseToMinutesSeconds(
                    widget.position?.inMilliseconds ?? 0),
                style: TextStyle(color: Color(0xFF4e606e)),
              ),
              Text(
                Utility.parseToMinutesSeconds(
                    widget.duration?.inMilliseconds ?? 0),
                style: TextStyle(color: Color(0xFF4e606e)),
              )
            ],
          ),
        )
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}
