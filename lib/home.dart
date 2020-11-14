import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/bloc/AplicationBloc.dart';
import 'package:music_player/src/bloc/BlocProvider.dart';
import 'package:music_player/src/ui/ArtistTab.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/genreTab.dart';
import 'package:music_player/src/ui/homeTab.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/src/ui/onlineRadioTab.dart';
import 'package:music_player/src/ui/songsTab.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:rxdart/rxdart.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  ApplicationBloc bloc;
  FlutterAudioQuery audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    bloc ??= BlocProvider.of<ApplicationBloc>(context);

    return StreamBuilder<bool>(
        stream: AudioService.runningStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            // Don't show anything until we've ascertained whether or not the
            // service is running, since we want to show a different UI in
            // each case.
            return SizedBox();
          }
          final running = snapshot.data ?? false;
          double paddingBottom = running ? 80 : 0;

          return Stack(children: [
            DefaultTabController(
              length: 6,
              initialIndex: 0,
              child: Scaffold(
                  extendBodyBehindAppBar: true,
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    actions: [
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => print("Search"),
                        color: Color(0xFF55889d),
                      )
                    ],
                    leading: IconButton(
                      color: Color(0xFF586a78),
                      icon: Icon(Icons.sort),
                      onPressed: () {},
                    ),
                  ),
                  body: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF374a59), Color(0xFF1a2a37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 1.0],
                            tileMode: TileMode.clamp)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 90, 16, 0),
                          child: Text(
                            "Discover",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          height: 60,
                          child: TabBar(
                            indicatorColor: Color(0xFF55889d),
                            labelColor: Color(0xFF55889d),
                            unselectedLabelColor: Color(0xFF4e606e),
                            labelStyle: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            isScrollable: true,
                            indicator: CircleTabIndicator(
                                color: Color(0xFF55889d), radius: 3),
                            tabs: [
                              Tab(
                                text: "My Playlists",
                              ),
                              Tab(
                                text: "Artists",
                              ),
                              Tab(
                                text: "Albums",
                              ),
                              Tab(
                                text: "Genres",
                              ),
                              Tab(
                                text: "Songs",
                              ),
                              Tab(
                                text: "Online Radio",
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            child: TabBarView(
                              children: [
                                Container(
                                  child: HomeTab(
                                    bloc: bloc,
                                    bottomPadding: paddingBottom,
                                  ),
                                ),
                                ArtistTab(
                                  bloc: bloc,
                                  bottomPadding: paddingBottom,
                                ),
                                AlbumTab(
                                  bloc: bloc,
                                  albumListFuture: audioQuery.getAlbums(),
                                  bottomPadding: paddingBottom,
                                ),
                                GenreTab(
                                  bloc: bloc,
                                  bottomPadding: paddingBottom,
                                ),
                                SongTab(
                                  audioQuery: audioQuery,
                                  songListFuture: audioQuery.getSongs(),
                                  bottomPadding: paddingBottom,
                                ),
                                OnlineRadioTabSearch(
                                  bottomPadding: paddingBottom,
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
            ),
            BottomPlayerBar(audioQuery: audioQuery)
          ]);
        });
  }
}

class SongListWidget extends StatelessWidget {
  final List<SongInfo> songList;
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  SongListWidget({Key key, this.songList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songList.length,
      itemBuilder: (context, index) => ListTile(
        leading: (songList[index].albumArtwork == null)
            ? FutureBuilder<Uint8List>(
                future: audioQuery.getArtwork(
                    type: ResourceType.SONG, id: songList[index].id),
                builder: (_, snapshot) {
                  if (snapshot.data == null || !snapshot.hasData)
                    return Center(
                      child: CircularProgressIndicator(),
                    );

                  if (snapshot.data.isEmpty) {
                    return Icon(Icons.music_note);
                  }

                  return Container(
                    height: 80,
                    width: 80,
                    child: Image.memory(
                      snapshot.data,
                    ),
                  );
                })
            : Image.file(File(songList[index].albumArtwork)),
        title: Text(songList[index].title),
        subtitle: Text(songList[index].artist),
      ),
    );
  }
}

class NoDataWidget extends StatelessWidget {
  final String title;

  NoDataWidget({this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            iconSize: 120,
            onPressed: null,
            icon: Icon(Icons.not_interested),
          ),
          Text(
            title,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }
}

class CircleTabIndicator extends Decoration {
  final BoxPainter _painter;

  CircleTabIndicator({@required Color color, @required double radius})
      : _painter = _CirclePainter(color, radius);

  @override
  BoxPainter createBoxPainter([onChanged]) => _painter;
}

class _CirclePainter extends BoxPainter {
  final Paint _paint;
  final double radius;

  _CirclePainter(Color color, this.radius)
      : _paint = Paint()
          ..color = color
          ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final Offset circleOffset =
        offset + Offset(cfg.size.width / 2, cfg.size.height - radius - 5);
    canvas.drawCircle(circleOffset, radius, _paint);
  }
}

//// code snipsets
/*FutureBuilder(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<SongInfo> songList =
                  snapshot.data; //.where((a) => a.isMusik).toList();
              return ListView.builder(
                itemBuilder: (context, index) => ListTile(
                  leading: (songList[index].albumArtwork == null)
                      ? FutureBuilder<Uint8List>(
                          future: audioQuery.getArtwork(
                              type: ResourceType.SONG, id: songList[index].id),
                          builder: (_, snapshot) {
                            if (snapshot.data == null || !snapshot.hasData)
                              return Center(
                                child: CircularProgressIndicator(),
                              );

                            if (snapshot.data.isEmpty) {
                              return Icon(Icons.music_note);
                            }

                            return Container(
                              height: 80,
                              width: 80,
                              child: Image.memory(
                                snapshot.data,
                              ),
                            );
                          })
                      : Image.file(File(songList[index].albumArtwork)),
                  title: Text(songList[index].title),
                  subtitle: Text(songList[index].artist),
                ),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
          future: albumList,
        ),
              StreamBuilder<List<SongInfo>>(
                  stream: bloc.songStream,
                  builder: (context, snapshot) {
                    print(snapshot.data);
                    if (snapshot.hasError)
                      return Center(child: Text("${snapshot.error}"));

                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());

                    return (snapshot.data.isEmpty)
                        ? NoDataWidget(
                            title: "There are no Songs",
                          )
                        : SongListWidget(songList: snapshot.data);
                  }));*/
