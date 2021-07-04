import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/bloc/player/player_state.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';

class GradientButton extends StatelessWidget {
  final Function? onpresss;
  final Gradient? gradient;
  final Widget child;
  final double elevation;
  final ShapeBorder? shape;

  const GradientButton({
    Key? key,
    this.onpresss,
    this.gradient,
    this.elevation = 2.0,
    required this.child,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: onpresss as void Function()?,
      elevation: elevation,
      padding: EdgeInsets.all(0),
      shape: shape,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: gradient,
        ),
        child: child,
      ),
    );
  }
}

class BottomPlayerBar extends StatefulWidget {
  const BottomPlayerBar({
    Key? key,
  }) : super(key: key);

  @override
  _BottomPlayerBarState createState() => _BottomPlayerBarState();
}

class _BottomPlayerBarState extends State<BottomPlayerBar>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  StreamSubscription? playing;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    playing?.cancel();
    animationController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
        stream: AudioService.currentMediaItemStream,
        builder: (context, snapshot) {
          return BlocBuilder<PlayerBloc, PlayerState>(
              builder: (context, state) {
            if (state is PlayerEmpty && !snapshot.hasData) {
              print("What up!");
              return Container();
            }
            MediaItem? mediaItem;
            bool radio = true;
            if (state is PlayerInitial) {
              mediaItem = state.curruentMediaItem;
              radio = state.radio;
            }
            if (state is PlayerPlaying) {
              mediaItem = snapshot.data;
              radio = state.radio;
            }
            if (mediaItem == null) {
              return Container();
            }
            animationController = AnimationController(
                vsync: this, duration: Duration(milliseconds: 250));
            playing = AudioService.playbackStateStream.listen((event) {
              if (event.playing)
                animationController!.reverse();
              else
                animationController!.forward();
            });
            return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 90,
              child: AlbumArtBackground(
                id: mediaItem.id,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        Navigator.of(context).push(new MaterialPageRoute(
                      builder: (context) => PlayerSceen(),
                    )),
                    child: Container(
                      height: 90,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.expand_less,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.64,
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mediaItem.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Text(
                                      mediaItem.artist ?? "",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          state is PlayerInitial
                              ? Container()
                              : Container(
                                  width: 70,
                                  height: 70,
                                  alignment: Alignment.center,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        height: 70,
                                        width: 70,
                                        child: StreamBuilder<Duration>(
                                            stream: AudioService.positionStream,
                                            builder: (context, snapshot1) {
                                              if (snapshot1.data == null ||
                                                  radio) {
                                                return Container();
                                              }

                                              return CircularProgressIndicator(
                                                backgroundColor: Colors.white12,
                                                valueColor:
                                                    new AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                                value: snapshot1.data == null
                                                    ? 0
                                                    : snapshot1.data!
                                                            .inMilliseconds /
                                                        mediaItem!.duration!
                                                            .inMilliseconds,
                                              );
                                            }),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          AudioService.playbackState.playing
                                              ? AudioService.pause()
                                              : AudioService.play();
                                        },
                                        icon: AnimatedIcon(
                                          icon: AnimatedIcons.pause_play,
                                          progress: animationController!,
                                          size: 25,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
        });
  }
}

class NoDataWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Function? action;
  final String? actionText;
  final Widget? actionIcon;

  NoDataWidget(
      {required this.title,
      this.subtitle,
      this.icon,
      this.action,
      this.actionText,
      this.actionIcon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(20),
          ),
          Icon(
            icon,
            size: 90,
            color: Colors.grey,
          ),
          Text(
            title,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
          Padding(
            padding: EdgeInsets.all(3),
          ),
          subtitle != null
              ? Text(
                  subtitle!,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                )
              : Container(),
          Padding(
            padding: EdgeInsets.all(10),
          ),
          action != null
              ? RaisedButton.icon(
                  label: Text(actionText!),
                  icon: actionIcon!,
                  onPressed: action as void Function()?,
                )
              : Container(),
        ],
      ),
    );
  }
}
