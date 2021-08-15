import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerOverview extends StatefulWidget {
  const PlayerOverview({Key? key}) : super(key: key);

  @override
  _PlayerOverviewState createState() => _PlayerOverviewState();
}

class _PlayerOverviewState extends State<PlayerOverview> {
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF260e43),
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: StreamBuilder<MediaItem?>(
            stream: _playerBloc.audioHandler.mediaItem,
            builder: (context, mediaState) {
              if (!mediaState.hasData || mediaState.data == null) {
                return CircularProgressIndicator();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    child: QueryArtworkWidget(
                        size: (MediaQuery.of(context).size.width - 100).toInt(),
                        artworkHeight: MediaQuery.of(context).size.width - 100,
                        artworkWidth: MediaQuery.of(context).size.width - 100,
                        artworkBorder: BorderRadius.circular(100000000),
                        nullArtworkWidget: CircleAvatar(
                          backgroundColor: Colors.pink,
                          child: Icon(
                            Icons.music_note,
                            size: 60,
                          ),
                          radius: (MediaQuery.of(context).size.width - 100)
                                  .toInt() /
                              2,
                        ),
                        id: mediaState.data!.extras!["id"],
                        type: ArtworkType.AUDIO,
                        artwork: mediaState.data!.artUri.toString(),
                        deviceSDK: _playerBloc.deviceModel!.sdk),
                  ),
                  Container(
                    child: Column(
                      children: [
                        Container(
                          child: Column(children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(30, 20, 30, 10),
                              child: Text(
                                mediaState.data!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(30, 0, 30, 25),
                              child: Text(
                                  mediaState.data!.artist! +
                                      " | " +
                                      mediaState.data!.album!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                  )),
                            )
                          ]),
                        ),
                        StreamBuilder<Duration>(
                            stream: AudioService.position,
                            builder: (context, position) {
                              if (!position.hasData) {
                                return CircularProgressIndicator();
                              }
                              return Container(
                                child: SeekBar(
                                  duration: mediaState.data!.duration!,
                                  position: position.data!,
                                  onChangeEnd: (value) =>
                                      _playerBloc.audioHandler.seek(value),
                                ),
                              );
                            }),
                        PlayControlls(),
                        FutherActions(id: mediaState.data!.extras!["id"])
                      ],
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }
}

class PlayControlls extends StatefulWidget {
  const PlayControlls({Key? key}) : super(key: key);

  @override
  _PlayControllsState createState() => _PlayControllsState();
}

class _PlayControllsState extends State<PlayControlls>
    with SingleTickerProviderStateMixin {
  late PlayerBloc _playerBloc;
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: () => _playerBloc.audioHandler
                    .setRepeatMode(AudioServiceRepeatMode.one),
                icon: Icon(Icons.loop),
                color: Colors.white70),
            IconButton(
                onPressed: () => _playerBloc.audioHandler.skipToPrevious(),
                icon: Icon(Icons.skip_previous),
                color: Colors.white70),
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 55,
              child: Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      color: Color(0xffff16ce),
                      blurRadius: 50.0,
                      spreadRadius: 5.0)
                ]),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xffff16ce),
                  child: StreamBuilder<bool>(
                      stream: _playerBloc.audioHandler.playbackState
                          .map((state) => state.playing)
                          .distinct(),
                      builder: (context, snapshot) {
                        animationController.animateTo(
                            snapshot.hasData && snapshot.data! ? 0.0 : 1.0);
                        return IconButton(
                          onPressed: () => snapshot.hasData && !snapshot.data!
                              ? _playerBloc.audioHandler.play()
                              : _playerBloc.audioHandler.pause(),
                          icon: AnimatedIcon(
                            progress: animation,
                            icon: AnimatedIcons.pause_play,
                            color: Colors.white,
                          ),
                          iconSize: 30,
                        );
                      }),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _playerBloc.audioHandler.skipToNext(),
              icon: Icon(Icons.skip_next),
              color: Colors.white70,
            ),
            IconButton(
                onPressed: () => print("TODO"),
                icon: Icon(Icons.volume_up),
                color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class FutherActions extends StatefulWidget {
  final int id;
  const FutherActions({Key? key, required this.id}) : super(key: key);

  @override
  _FutherActionsState createState() => _FutherActionsState();
}

class _FutherActionsState extends State<FutherActions> {
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, 30, 30, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 80,
            color: Color(0xFF3e235f),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => print("play/pause"),
                  icon: Icon(Icons.play_for_work),
                  color: Colors.white,
                ),
                IconButton(
                    onPressed: () => print("forward"),
                    icon: Icon(Icons.playlist_play),
                    color: Colors.white),
                StreamBuilder<List<SongModel>>(
                    stream: _playerBloc.favorits$.stream,
                    builder: (context, snapshot) {
                      bool fav = !snapshot.hasData ||
                          snapshot.data!
                              .any((element) => element.id == widget.id);

                      return IconButton(
                        onPressed: () => fav
                            ? _playerBloc.removeFromFavorits(widget.id)
                            : _playerBloc.addToFavorits(widget.id),
                        icon: Icon(Icons.favorite),
                        color: fav ? Color(0xffff16ce) : Colors.white70,
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 1.5,
              inactiveTrackColor: Color(0xFF3e235f),
              activeTrackColor: Color(0xffff16ce),
              thumbShape: SliderComponentShape.noThumb,
            ),
            child: Slider(
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
          ),
        ),
        Positioned(
          right: 30.0,
          bottom: 0.0,
          child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch("${widget.duration}")
                      ?.group(1) ??
                  '${widget.duration}',
              style: TextStyle(color: Color(0xFF3e235f), fontSize: 12)),
        ),
        Positioned(
          left: 30.0,
          bottom: 0.0,
          child: Text(
            RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                    .firstMatch("${widget.position}")
                    ?.group(1) ??
                '${widget.position}',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
