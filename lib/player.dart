import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:xml/xml.dart';
import 'package:palette_generator/palette_generator.dart';

class PlayerSceen extends StatefulWidget {
  const PlayerSceen();

  @override
  _PlayerSceenState createState() => _PlayerSceenState();
}

class _PlayerSceenState extends State<PlayerSceen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late StreamSubscription playinglisterner;
  Uint8List? cover;
  Color background = Color(0xFF374a59);
  Color textColor = Colors.grey;
  Color highcolor = Colors.lightBlueAccent;
  MediaItem? cur;

  @override
  void initState() {
    // needs to be in build

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

  bool comapareColors(Color a, Color b) {
    return (a.red - b.red).abs() > 40 ||
        ((a.green - b.green).abs() > 40 && (a.blue - b.blue).abs() > 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
          style: TextStyle(color: textColor, fontSize: 13),
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
          stream: AudioService.currentMediaItemStream.cast(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            if (cur != snapshot.data) {
              cur = snapshot.data;
              if (cur!.genre!.contains("r")) {
                //TODO
              } else {
                /*audioQuery
                    .getArtwork(
                        type: ResourceType.SONG,
                        id: cur!.genre!,
                        size: Size(500, 500))
                    .then((image) async {
                  setState(() {
                    cover = image;
                  });
                  var imageData = await decodeImageFromList(image);
                  PaletteGenerator platteBack =
                      await PaletteGenerator.fromImage(imageData);

                  double lum =
                      platteBack.dominantColor!.color.computeLuminance();
                  setState(() {
                    background = platteBack.dominantColor!.color;
                    if (lum > 0.5) {
                      highcolor = platteBack.vibrantColor!.color;
                      textColor = platteBack.darkVibrantColor!.color;
                    } else {
                      highcolor = platteBack.vibrantColor!.color;
                      textColor = platteBack.darkVibrantColor!.color;
                    }
                  });

                  List<PaletteFilter> l = List();
                  l.add((color) => comapareColors(background, color.toColor()));

                  PaletteGenerator platte =
                      await PaletteGenerator.fromImage(imageData, filters: l);

                  setState(() {
                    highcolor = platte.dominantColor.color;
                  });

                  List<PaletteFilter> ll = List();
                  l.add((color) =>
                      (comapareColors(background, color.toColor()) &&
                          comapareColors(highcolor, color.toColor())));

                  PaletteGenerator platteText =
                      await PaletteGenerator.fromImage(imageData, filters: ll);

                  setState(() {
                    textColor = platteText.dominantColor.color;
                  });
                });*/
              }
            }
            final duration = snapshot.data!.duration ?? Duration.zero;

            return Container(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.width,
                    child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width,
                        child: cover != null
                            ? Image.memory(
                                cover!,
                                fit: BoxFit.cover,
                              )
                            : Center(child: Icon(Icons.music_note))),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: MediaQuery.of(context).size.width,
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                            background,
                            Colors.transparent,
                            Colors.transparent,
                            background
                          ],
                              stops: [
                            0.0,
                            0.1,
                            0.9,
                            1.0
                          ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              tileMode: TileMode.clamp)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
                            child: Column(children: [
                              Text(
                                snapshot.data!.title,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: highcolor),
                              ),
                              Padding(
                                padding: EdgeInsets.all(3),
                              ),
                              Text(
                                snapshot.data!.album +
                                    " | " +
                                    snapshot.data!.artist!,
                                style: TextStyle(color: textColor),
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
                                        textColor,
                                        highcolor,
                                      ]),
                                  shape: CircleBorder(),
                                  child: AnimatedIcon(
                                    size: 50,
                                    progress: _animationController,
                                    icon: AnimatedIcons.play_pause,
                                    color: background,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.skip_next),
                                onPressed: () => AudioService.skipToNext(),
                                color: textColor,
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
                                color: textColor,
                              ),
                              IconButton(
                                icon: Icon(Icons.playlist_add),
                                onPressed: () => {/*Flutter audio querry*/},
                                color: textColor,
                              ),
                              IconButton(
                                icon: Icon(Icons.whatshot_outlined),
                                color: textColor,
                                onPressed: () => {
                                  /*
                                  audioQuery.getPlaylists().then((value) async {
                                    if (snapshot.data!.genre!.contains("r"))
                                      return;
                                    List<SongInfo> i =
                                        await audioQuery.getSongsById(
                                            ids: {snapshot.data!.genre}.toList()
                                                as List<String>);
                                    value
                                        ?.firstWhere((element) =>
                                            element.name == "Favoriten")
                                        .addSong(song: i[0]);
                                  })*/
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.repeat),
                                onPressed: () => AudioService.setRepeatMode(
                                    AudioServiceRepeatMode.all),
                                color: textColor,
                              ),
                            ],
                          )
                        ],
                      ),
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
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  SeekBar({
    required this.duration,
    required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final value = min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
        widget.duration.inMilliseconds.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    return Stack(
      children: [
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: value,
          onChanged: (value) {
            if (!_dragging) {
              _dragging = true;
            }
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged!(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd!(Duration(milliseconds: value.round()));
            }
            _dragging = false;
          },
        ),
        Positioned(
          right: 16.0,
          bottom: 0.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch("$_remaining")
                      ?.group(1) ??
                  '$_remaining',
              style: Theme.of(context).textTheme.caption),
        ),
      ],
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}
