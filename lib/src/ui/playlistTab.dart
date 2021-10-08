import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/home.dart';
import 'package:music_player/src/ui/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
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
  List<SongModel> songs = [];

  void playSong(SongModel song, PlayerBloc playerBloc) {
    if (songs == []) {
      return;
    }
    var i = songs.indexOf(song);
    playerBloc.startPlayback(songs.sublist(i)..addAll(songs.sublist(0, i)));
  }

  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: Theme.of(context).canvasColor,
          elevation: 0.0,
          title: Text("Playlist"),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () => print("object"), icon: Icon(Icons.more_vert))
          ],
        ),
        body: PlayerWidget(
            child: StreamBuilder<List<SongModel>>(
                stream: _playerBloc.songs$.stream,
                builder: (context, snapshot) {
                  songs = [];

                  if (snapshot.hasData) {
                    snapshot.data!.forEach((element) {
                      widget.playlist.memberIDs.forEach((element2) {
                        if (element.id == int.tryParse(element2.toString())) {
                          songs.add(element);
                        }
                      });
                    });
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Material(
                          color: Theme.of(context).canvasColor,
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
                                    id: widget.coverSong!.id,
                                    type: ArtworkType.AUDIO,
                                    keepOldArtwork: true,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 0, 30, 0),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width - 265,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          widget.playlist.playlist,
                                          overflow: TextOverflow.clip,
                                          maxLines: 4,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 36),
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(top: 8)),
                                        Text(
                                          widget.playlist.memberIDs.length
                                                  .toString() +
                                              " Songs",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1!
                                                  .color!
                                                  .withAlpha(122)),
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
                              minHeight: 50,
                              maxHeight: 50,
                              child: Material(
                                elevation: 0,
                                color: Theme.of(context).backgroundColor,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(30, 8, 30, 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widget.playlist.memberIDs.length
                                                .toString() +
                                            " Songs",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText1!
                                                .color!
                                                .withAlpha(122)),
                                      ),
                                      DecoratedBox(
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [
                                              Theme.of(context).accentColor,
                                              Theme.of(context)
                                                  .primaryColorLight
                                            ]),
                                            borderRadius:
                                                BorderRadius.circular(80)),
                                        child: ElevatedButton(
                                          onPressed: () => playSong(
                                              songs.first, _playerBloc),
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
                              onTap: playSong,
                            ),
                          );
                        }, childCount: songs.length),
                      )
                    ],
                  );
                })));
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
