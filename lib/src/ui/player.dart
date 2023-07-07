import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/wiedergabeListTab.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerOverview extends StatefulWidget {
  const PlayerOverview({Key? key}) : super(key: key);

  @override
  _PlayerOverviewState createState() => _PlayerOverviewState();
}

class _PlayerOverviewState extends State<PlayerOverview> {
  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant
            ])),
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
                        backgroundColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        child: Icon(
                          Icons.music_note,
                          size: 60,
                        ),
                        radius:
                            (MediaQuery.of(context).size.width - 100).toInt() /
                                2,
                      ),
                      id: mediaState.data!.extras!["id"],
                      type: ArtworkType.AUDIO,
                    ),
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
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(30, 0, 30, 25),
                              child: Text(
                                  mediaState.data!.artist! +
                                      " • " +
                                      mediaState.data!.album!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .color!
                                        .withAlpha(122),
                                  )),
                            )
                          ]),
                        ),
                        StreamBuilder<Duration>(
                            stream: AudioService.position,
                            builder: (context, position) {
                              return Container(
                                child: SeekBar(
                                  duration: !position.hasData
                                      ? Duration(seconds: 0)
                                      : mediaState.data!.duration!,
                                  position: !position.hasData
                                      ? Duration(seconds: 0)
                                      : position.data!,
                                  onChangeEnd: (value) => !position.hasData
                                      ? print("empty player")
                                      : _playerBloc.audioHandler.seek(value),
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
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StreamBuilder<PlaybackState>(
                stream: _playerBloc.audioHandler.playbackState,
                builder: (context, snapshot) {
                  Icon icon = snapshot.hasData
                      ? snapshot.data!.shuffleMode ==
                              AudioServiceShuffleMode.all
                          ? Icon(Icons.shuffle_on_outlined)
                          : Icon(Icons.shuffle)
                      : Icon(Icons.shuffle);
                  return IconButton(
                      onPressed: () => {
                            snapshot.data!.shuffleMode ==
                                    AudioServiceShuffleMode.all
                                ? _playerBloc.audioHandler.setShuffleMode(
                                    AudioServiceShuffleMode.none)
                                : _playerBloc.audioHandler
                                    .setShuffleMode(AudioServiceShuffleMode.all)
                          },
                      icon: icon,
                      color: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .color!
                          .withAlpha(122));
                }),
            IconButton(
                onPressed: () => _playerBloc.audioHandler.skipToPrevious(),
                icon: Icon(Icons.skip_previous),
                color: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .color!
                    .withAlpha(180)),
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 55,
              child: Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).colorScheme.secondary,
                      blurRadius: 50.0,
                      spreadRadius: 5.0)
                ]),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.onPrimary,
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
              color:
                  Theme.of(context).textTheme.bodyText1!.color!.withAlpha(180),
            ),
            IconButton(
                onPressed: () {
                  showSliderDialog(
                    context: context,
                    title: "Adjust volume",
                    divisions: 10,
                    min: 0.0,
                    max: 1.0,
                    value: _playerBloc.audioHandler.volume.value,
                    stream: _playerBloc.audioHandler.volume,
                    onChanged: _playerBloc.audioHandler.setVolume,
                  );
                },
                icon: Icon(Icons.volume_up),
                color: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .color!
                    .withAlpha(122)),
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
  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Container(
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, 30, 30, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 80,
            color: Theme.of(context).canvasColor,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => print("TODO"),
                  icon: Icon(Icons.play_for_work),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.of(context).push(new MaterialPageRoute(
                    builder: (context) => WiedergabeListe(),
                  )),
                  icon: Icon(Icons.playlist_play),
                ),
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
                        color: fav
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context)
                                .colorScheme
                                .secondary
                                .withAlpha(122),
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
              inactiveTrackColor: Theme.of(context).colorScheme.surface,
              activeTrackColor: Theme.of(context).colorScheme.secondary,
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
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyText1!
                      .color!
                      .withAlpha(122),
                  fontSize: 12)),
        ),
        Positioned(
          left: 30.0,
          bottom: 0.0,
          child: Text(
            RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                    .firstMatch("${widget.position}")
                    ?.group(1) ??
                '${widget.position}',
            style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyText1!
                    .color!
                    .withAlpha(122),
                fontSize: 12),
          ),
        ),
      ],
    );
  }
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
  // TODO: Replace these two by ValueStream.
  required double value,
  required Stream<double> stream,
  required ValueChanged<double> onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
        stream: stream,
        builder: (context, snapshot) => Container(
          height: 100.0,
          child: Column(
            children: [
              Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                  style: const TextStyle(
                      fontFamily: 'Fixed',
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0)),
              Slider(
                divisions: divisions,
                min: min,
                max: max,
                value: snapshot.data ?? value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
