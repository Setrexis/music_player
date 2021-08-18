import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/home.dart';
import 'package:music_player/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumOverview extends StatefulWidget {
  final AlbumModel album;

  const AlbumOverview({Key? key, required this.album}) : super(key: key);

  @override
  _AlbumOverviewState createState() => _AlbumOverviewState();
}

class _AlbumOverviewState extends State<AlbumOverview>
    with TickerProviderStateMixin {
  late PlayerBloc _playerBloc;
  List<SongModel> songs = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  void playSong(SongModel song) {
    if (songs == []) {
      return;
    }
    var i = songs.indexOf(song);
    _playerBloc
        .add(PlayerPlay(song, songs.sublist(i)..addAll(songs.sublist(0, i))));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SongModel>>(
        stream: _playerBloc.songs$.stream,
        builder: (context, snapshot) {
          songs = [];

          if (snapshot.hasData) {
            snapshot.data!.forEach((element) {
              if (element.albumId ==
                  int.tryParse(widget.album.albumId.toString())) {
                songs.add(element);
              }
            });
          }

          return Scaffold(
            backgroundColor: Color(0xFF260e43),
            extendBodyBehindAppBar: false,
            appBar: AppBar(
              backgroundColor: Color(0xFF3e235f),
              elevation: 0.0,
              title: Text("Album"),
              centerTitle: true,
              actions: [
                IconButton(
                    onPressed: () => print("object"),
                    icon: Icon(Icons.more_vert))
              ],
            ),
            body: PlayerWidget(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Material(
                      color: Color(0xFF3e235f),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 30),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Material(
                              borderRadius: BorderRadius.circular(10),
                              elevation: 20,
                              child: QueryArtworkWidget(
                                artworkBorder: BorderRadius.circular(10),
                                artworkHeight: 180,
                                artworkWidth: 180,
                                id: widget.album.albumId,
                                type: ArtworkType.ALBUM,
                                artwork: widget.album.artwork,
                                deviceSDK: _playerBloc.deviceModel!.sdk,
                                keepOldArtwork: true,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 30, 0),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 265,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.album.albumName,
                                      overflow: TextOverflow.clip,
                                      maxLines: 4,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36),
                                    ),
                                    Padding(padding: EdgeInsets.only(top: 8)),
                                    Text(
                                      widget.album.numOfSongs.toString() +
                                          " Songs",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      widget.album.artist +
                                          " · " +
                                          widget.album.lastYear.toString(),
                                      style: TextStyle(color: Colors.white70),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                          minHeight: 40,
                          maxHeight: 70,
                          child: Material(
                            elevation: 1,
                            color: Color(0xFF260e43),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(30, 8, 30, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.album.numOfSongs.toString() +
                                        " Songs",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Color(0xFF3e235f),
                                          Color(0xffff16ce)
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(80)),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _playerBloc.add(
                                            PlayerPlay(songs.first, songs));
                                      },
                                      style: ElevatedButton.styleFrom(
                                          primary: Colors.transparent,
                                          elevation: 0.0),
                                      child: Text('Play all'),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ))),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 30),
                        child: SongListItem(
                          playerBloc: _playerBloc,
                          song: songs[index],
                          onTap: () => playSong,
                        ),
                      );
                    }, childCount: songs.length),
                  )
                ],
              ),
            ),
          );
        });
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  // 2
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  // 3
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
