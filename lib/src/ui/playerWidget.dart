import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Container(
      child: StreamBuilder<MediaState>(
        stream: _playerBloc.mediaStateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.mediaItem == null) {
            return widget.child;
          }
          return Stack(
            children: [
              Positioned(
                child: widget.child,
                bottom: 100,
                left: 0,
                top: 0,
                right: 0,
              ),
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
                            .scaffoldBackgroundColor
                            .withOpacity(0.0),
                        Theme.of(context).scaffoldBackgroundColor,
                      ])),
                ),
                bottom: 99,
                left: 0,
                right: 0,
              ),
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

class _BottomPlayerWidgetState extends State<BottomPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
  }

  @override
  Widget build(BuildContext context) {
    final PlayerBloc _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Container(
      height: 100,
      width: MediaQuery.of(context).size.width,
      child: StreamBuilder<MediaState>(
        stream: _playerBloc.mediaStateStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container();
          }
          animationController.animateTo(
              snapshot.hasData && snapshot.data!.playing ? 0.0 : 1.0);
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
                          color: Theme.of(context).canvasColor,
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
                        color: Theme.of(context).canvasColor,
                        child: QueryArtworkWidget(
                          id: snapshot.data!.mediaItem!.extras!["id"],
                          type: ArtworkType.AUDIO,
                          artwork: snapshot.data!.mediaItem!.album,
                          deviceSDK: _playerBloc.deviceModel!.sdk,
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
                      child: SizedBox(
                        height: 92,
                        width: 92,
                        child: CircularProgressIndicator(
                          value: snapshot.data!.position.inMilliseconds /
                              snapshot
                                  .data!.mediaItem!.duration!.inMilliseconds,
                          color: Theme.of(context).accentColor,
                          backgroundColor: Theme.of(context).backgroundColor,
                        ),
                      )),
                  Positioned(
                      left: 130,
                      right: 100,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.data!.mediaItem!.title,
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              snapshot.data!.mediaItem!.artist! +
                                  " · " +
                                  snapshot.data!.mediaItem!.album!,
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
                    child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).accentColor,
                        child: IconButton(
                          onPressed: () => !snapshot.data!.playing
                              ? _playerBloc.audioHandler.play()
                              : _playerBloc.audioHandler.pause(),
                          icon: AnimatedIcon(
                            progress: animation,
                            icon: AnimatedIcons.pause_play,
                            color: Theme.of(context).backgroundColor,
                          ),
                          iconSize: 30,
                        )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
