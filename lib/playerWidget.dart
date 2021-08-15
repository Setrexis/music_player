import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerWidget extends StatefulWidget {
  final Widget child;

  const PlayerWidget({Key? key, required this.child}) : super(key: key);

  @override
  _PlayerWidgetState createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
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
      child: StreamBuilder<bool>(
        stream: _playerBloc.playingStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!) {
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
                        Color(0xFF260e43).withOpacity(0.0),
                        Color(0xFF260e43),
                      ])),
                ),
                bottom: 99,
                left: 0,
                right: 0,
              ),
              Positioned(bottom: 0, child: BottomPlayerWidget())
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
          return Container(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                    left: 20,
                    right: 20,
                    bottom: 10,
                    child: ClipRRect(
                      child: Container(
                        height: 80,
                        color: Color(0xFF3e235f),
                      ),
                      borderRadius: BorderRadius.circular(50),
                    )),
                Positioned(
                  left: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      height: 90,
                      width: 90,
                      color: Color(0xFF3e235f),
                      child: QueryArtworkWidget(
                        id: snapshot.data!.mediaItem!.extras!["id"],
                        type: ArtworkType.AUDIO,
                        artwork: snapshot.data!.mediaItem!.album,
                        deviceSDK: _playerBloc.deviceModel!.sdk,
                        keepOldArtwork: true,
                      ),
                    ),
                  ),
                ),
                Positioned(
                    left: 20,
                    child: SizedBox(
                      height: 92,
                      width: 92,
                      child: CircularProgressIndicator(
                        value: snapshot.data!.position.inMilliseconds /
                            snapshot.data!.mediaItem!.duration!.inMilliseconds,
                        color: Color(0xffff16ce),
                        backgroundColor: Color(0xFF3e235f),
                      ),
                    )),
                Positioned(
                    left: 130,
                    right: 100,
                    child: Text(
                      snapshot.data!.mediaItem!.title,
                      style: TextStyle(color: Colors.white),
                    )),
                Positioned(
                  right: 30,
                  child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xffff16ce),
                      child: IconButton(
                        onPressed: () => !snapshot.data!.playing
                            ? _playerBloc.audioHandler.play()
                            : _playerBloc.audioHandler.pause(),
                        icon: AnimatedIcon(
                          progress: animation,
                          icon: AnimatedIcons.pause_play,
                          color: Colors.white,
                        ),
                        iconSize: 30,
                      )),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
