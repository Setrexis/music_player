import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';

class GradientButton extends StatelessWidget {
  final Function onpresss;
  final Gradient gradient;
  final Widget child;
  final double elevation;
  final ShapeBorder shape;

  const GradientButton({
    Key key,
    this.onpresss,
    this.gradient,
    this.elevation = 2.0,
    @required this.child,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: onpresss,
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
    Key key,
    @required this.audioQuery,
  }) : super(key: key);

  final FlutterAudioQuery audioQuery;

  @override
  _BottomPlayerBarState createState() => _BottomPlayerBarState();
}

class _BottomPlayerBarState extends State<BottomPlayerBar>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem>(
        stream: AudioService.currentMediaItemStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.none ||
              snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null) {
            return Container();
          }
          AnimationController animationController = AnimationController(
              vsync: this, duration: Duration(milliseconds: 250));
          return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 90,
            child: AlbumArtBackground(
              audioQuery: widget.audioQuery,
              id: snapshot.data.artUri,
              type: ResourceType.ALBUM,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(new MaterialPageRoute(
                    builder: (context) => PlayerSceen(),
                  )),
                  child: Container(
                    height: 80,
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
                                    snapshot.data.title ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    snapshot.data.artist ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Color(0xFF4e606e),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
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
                                          PlayerService.radioPlaying) {
                                        return Container();
                                      }

                                      return CircularProgressIndicator(
                                        backgroundColor: Color(0xFF4e606e),
                                        valueColor:
                                            new AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                        value: snapshot1.data == null
                                            ? 0
                                            : snapshot1.data.inMilliseconds /
                                                snapshot.data.duration
                                                    .inMilliseconds,
                                      );
                                    }),
                              ),
                              IconButton(
                                onPressed: () {
                                  AudioService.playbackState.playing
                                      ? animationController.forward()
                                      : animationController.reverse();
                                  AudioService.playbackState.playing
                                      ? AudioService.pause()
                                      : AudioService.play();
                                },
                                icon: AnimatedIcon(
                                  icon: AnimatedIcons.pause_play,
                                  progress: animationController,
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
  }
}
