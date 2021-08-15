import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/home.dart';
import 'package:music_player/player.dart';
import 'package:music_player/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlaylistOverview extends StatefulWidget {
  final SongModel? coverSong;
  final PlaylistModel playlist;

  const PlaylistOverview({Key? key, this.coverSong, required this.playlist})
      : super(key: key);

  @override
  _PlaylistOverviewState createState() => _PlaylistOverviewState();
}

class _PlaylistOverviewState extends State<PlaylistOverview>
    with TickerProviderStateMixin {
  late PlayerBloc _playerBloc;
  late AnimationController _fadeAnimationControler;
  late AnimationController _positionAnimationControler;
  late Animation _colorTween, _fadeTween;
  late Animation<double> _positionTween;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
    _fadeAnimationControler =
        AnimationController(vsync: this, duration: Duration(seconds: 0));
    _positionAnimationControler =
        AnimationController(vsync: this, duration: Duration(seconds: 0));
    _colorTween = ColorTween(
            begin: Color(0xffff16ce).withAlpha(30),
            end: Color(0xffff16ce).withAlpha(200))
        .animate(_positionAnimationControler);
    _fadeTween = Tween(begin: 1.0, end: 0.0).animate(_fadeAnimationControler);
    _positionTween =
        Tween(begin: 0.0, end: 30.0).animate(_positionAnimationControler);
  }

  bool _scrollListerner(ScrollNotification scrollNotification) {
    if (scrollNotification.metrics.axis == Axis.vertical) {
      _fadeAnimationControler
          .animateTo(scrollNotification.metrics.pixels / 100);
      _positionAnimationControler
          .animateTo(scrollNotification.metrics.pixels / 220);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SongModel>>(
        stream: _playerBloc.songs$.stream,
        builder: (context, snapshot) {
          List<SongModel> songs = [];

          print(widget.coverSong);

          if (snapshot.hasData) {
            snapshot.data!.forEach((element) {
              widget.playlist.memberIDs.forEach((element2) {
                if (element.id == int.tryParse(element2.toString())) {
                  songs.add(element);
                }
              });
            });
          }

          return Scaffold(
            backgroundColor: Color(0xFF260e43),
            extendBodyBehindAppBar: true,
            appBar: null,
            body: PlayerWidget(
              child: NotificationListener<ScrollNotification>(
                onNotification: _scrollListerner,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0.0,
                      shadowColor: Colors.transparent,
                      expandedHeight: 330,
                      collapsedHeight: 150,
                      pinned: true,
                      snap: true,
                      floating: true,
                      actions: [],
                      flexibleSpace: Stack(children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 30,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(60)),
                            child: Stack(fit: StackFit.expand, children: [
                              widget.coverSong == null
                                  ? Icon(Icons.music_note)
                                  : QueryArtworkWidget(
                                      artworkBorder: BorderRadius.circular(0),
                                      id: widget.coverSong!.id,
                                      type: ArtworkType.AUDIO,
                                      artwork: widget.coverSong!.artwork,
                                      deviceSDK: _playerBloc.deviceModel!.sdk,
                                      artworkFit: BoxFit.cover,
                                      keepOldArtwork: true,
                                    ),
                              AnimatedBuilder(
                                  animation: _positionAnimationControler,
                                  builder: (context, child) => ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                            _colorTween.value,
                                            BlendMode.darken),
                                        child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 300),
                                      ))
                            ]),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _positionAnimationControler,
                          builder: (context, child) => Positioned(
                              bottom: _positionTween.value * 1.7,
                              right: 0,
                              left: _positionTween.value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Opacity(
                                      opacity: _fadeTween.value,
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Color(0xffff16ce),
                                        child: IconButton(
                                            onPressed: () {
                                              _playerBloc.add(PlayerPlay(
                                                  songs.first, songs));
                                              Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    PlayerOverview(),
                                              ));
                                            },
                                            color: Colors.white,
                                            icon: Icon(Icons.play_arrow)),
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width -
                                          120,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            widget.playlist.playlistName,
                                            softWrap: true,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 28),
                                          ),
                                          Text(
                                              widget.playlist.memberIDs.length
                                                      .toString() +
                                                  " Songs",
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16))
                                        ],
                                      ),
                                    ),
                                    Opacity(
                                      opacity: _fadeTween.value,
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Color(0xffff16ce),
                                        child: IconButton(
                                            onPressed: () {
                                              _playerBloc.add(PlayerPlay(
                                                  songs.first, songs));
                                              Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    PlayerOverview(),
                                              ));
                                            },
                                            color: Colors.white,
                                            icon: Icon(Icons.play_arrow)),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        )
                      ]),
                    ),
                    SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 30),
                        child: SongListItem(
                            playerBloc: _playerBloc, song: songs[index]),
                      );
                    }, childCount: songs.length))
                  ],
                ),
              ),
            ),
          );
        });
  }
}
