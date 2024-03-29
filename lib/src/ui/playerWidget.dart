import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/player.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerWidget extends StatefulWidget {
  final Widget child;

  const PlayerWidget({Key? key, required this.child}) : super(key: key);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Container(
      child: StreamBuilder<MediaState>(
        stream: _playerBloc.mediaStateStream,
        builder: (context, snapshot) {
          double offset = 100;
          if (!snapshot.hasData || snapshot.data!.mediaItem == null) {
            offset = 0;
          }
          return Stack(
            children: [
              Positioned(
                child: widget.child,
                bottom: offset,
                left: 0,
                top: 0,
                right: 0,
              ),
              if (offset != 0)
                Positioned(
                  child: Container(
                    height: 41,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            tileMode: TileMode.decal,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                          Theme.of(context)
                              .colorScheme
                              .background
                              .withOpacity(0.0),
                          Theme.of(context).colorScheme.background,
                        ])),
                  ),
                  bottom: 99,
                  left: 0,
                  right: 0,
                ),
              if (offset != 0)
                Positioned(bottom: 10, child: BottomPlayerWidget())
            ],
          );
        },
      ),
    );
  }
}

class BottomPlayerWidget extends StatefulWidget {
  const BottomPlayerWidget({Key? key}) : super(key: key);

  @override
  _BottomPlayerWidgetState createState() => _BottomPlayerWidgetState();
}

class _BottomPlayerWidgetState extends State<BottomPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final PlayerBloc _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // Swiping in right direction.
        if (details.primaryVelocity! < 0) {
          _playerBloc.audioHandler.skipToNext();
        }

        // Swiping in left direction.
        if (details.primaryVelocity! > 0) {
          _playerBloc.audioHandler.skipToPrevious();
        }
      },
      child: Container(
        height: 100,
        width: MediaQuery.of(context).size.width,
        child: StreamBuilder<MediaItem?>(
          stream: _playerBloc.audioHandler.mediaItem,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Container();
            }
            return InkWell(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PlayerOverview())),
              child: Container(
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                        left: 25,
                        right: 25,
                        bottom: 10,
                        child: ClipRRect(
                          child: Container(
                            height: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                          ),
                          borderRadius: BorderRadius.circular(50),
                        )),
                    Positioned(
                      left: 25,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          height: 90,
                          width: 90,
                          color: Theme.of(context).colorScheme.surface,
                          child: QueryArtworkWidget(
                            id: snapshot.data!.extras!["id"],
                            type: ArtworkType.AUDIO,
                            keepOldArtwork: true,
                            nullArtworkWidget: Icon(
                              Icons.music_note,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        left: 25,
                        child: CircularProgressSeeker(
                          mediaItem: snapshot.data!,
                        )),
                    Positioned(
                        left: 130,
                        right: 100,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.data!.title,
                                maxLines: 2,
                                overflow: TextOverflow.clip,
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                snapshot.data!.artist! +
                                    " · " +
                                    snapshot.data!.album!,
                                maxLines: 1,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .color!
                                        .withAlpha(122)),
                              )
                            ])),
                    Positioned(
                      right: 35,
                      child: AnimatedPlayPauseButton(playerBloc: _playerBloc),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CircularProgressSeeker extends StatelessWidget {
  const CircularProgressSeeker({
    Key? key,
    required MediaItem mediaItem,
  })  : _mediaItem = mediaItem,
        super(key: key);
  final MediaItem _mediaItem;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
        stream: AudioService.position,
        builder: (context, snapshot) {
          return SizedBox(
            height: 92,
            width: 92,
            child: CircularProgressIndicator(
              value: !snapshot.hasData || _mediaItem.duration == null
                  ? 0
                  : snapshot.data!.inMilliseconds /
                      _mediaItem.duration!.inMilliseconds,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        });
  }
}

class AnimatedPlayPauseButton extends StatefulWidget {
  const AnimatedPlayPauseButton({
    Key? key,
    required PlayerBloc playerBloc,
  })  : _playerBloc = playerBloc,
        super(key: key);

  final PlayerBloc _playerBloc;

  @override
  _AnimatedPlayPauseButtonState createState() =>
      _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<AnimatedPlayPauseButton>
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
    return StreamBuilder<bool>(
        stream: widget._playerBloc.playingStream,
        builder: (context, snapshot) {
          animationController
              .animateTo(snapshot.hasData && snapshot.data! ? 0.0 : 1.0);
          return CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                onPressed: () => !snapshot.data!
                    ? widget._playerBloc.audioHandler.play()
                    : widget._playerBloc.audioHandler.pause(),
                icon: AnimatedIcon(
                  progress: animation,
                  icon: AnimatedIcons.pause_play,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                iconSize: 30,
              ));
        });
  }
}
