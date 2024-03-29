import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/home.dart';
import 'package:music_player/src/ui/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:http/http.dart' as http;

class ArtistOverview extends StatefulWidget {
  final ArtistModel artist;

  const ArtistOverview({Key? key, required this.artist}) : super(key: key);

  @override
  _ArtistOverviewState createState() => _ArtistOverviewState();
}

class _ArtistOverviewState extends State<ArtistOverview>
    with TickerProviderStateMixin {
  String url =
      "https://cdns-images.dzcdn.net/images/artist//250x250-000000-80-0-0.jpg";
  List<SongModel> songs = [];

  @override
  void initState() {
    super.initState();

    try {
      http
          .get(Uri.parse(
              "https://api.deezer.com/search?q=" + widget.artist.artist))
          .then((value) {
        url = jsonDecode(value.body)["data"][0]["artist"]["picture_medium"];
        setState(() {});
      });
    } on Exception catch (e) {
      print(e);
    }
  }

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
    return StreamBuilder<SongAlbumStream>(
        stream: _playerBloc.songAlbumStream,
        builder: (context, snapshot) {
          songs = [];
          List<AlbumModel> albums = [];
          Map<String, List<SongModel>> songMap = {};
          if (snapshot.hasData) {
            for (SongModel song in snapshot.data!.songs) {
              if (song.artistId == widget.artist.id) {
                songs.add(song);
                if (songMap.containsKey(song.album)) {
                  songMap[song.album]!.add(song);
                } else {
                  songMap[song.album!] = [song];
                }
              }
            }
            for (AlbumModel album in snapshot.data!.albums) {
              if (album.artistId == widget.artist.id.toString()) {
                albums.add(album);
              }
            }
          }

          List<Widget> listItems = [];
          for (String album in songMap.keys) {
            listItems.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              child: ListTile(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumOverview(
                          album: albums
                              .firstWhere((element) => element.album == album)),
                    )),
                title: Text(album),
                subtitle: Text(songMap[album]!.length.toString() + " Songs"),
                trailing: IconButton(
                    onPressed: () => _playerBloc.startPlayback(songMap[album]!),
                    icon: Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).colorScheme.secondary,
                    )),
              ),
            ));
            for (SongModel s in songMap[album]!) {
              listItems.add(Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                child: SongListItem(
                  playerBloc: _playerBloc,
                  song: s,
                  onTap: playSong,
                  artist: false,
                ),
              ));
            }
          }

          return Scaffold(
            extendBodyBehindAppBar: false,
            appBar: AppBar(
              backgroundColor: Theme.of(context).canvasColor,
              elevation: 0.0,
              title: Text("Artist"),
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    url,
                                    height: 180,
                                    width: 180,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            QueryArtworkWidget(
                                      artworkBorder: BorderRadius.circular(10),
                                      artworkHeight: 180,
                                      artworkWidth: 180,
                                      id: songs[0].id,
                                      type: ArtworkType.AUDIO,
                                      keepOldArtwork: true,
                                    ),
                                  ),
                                )),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                              child: Container(
                                width: MediaQuery.of(context).size.width - 235,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.artist.artist,
                                      overflow: TextOverflow.clip,
                                      maxLines: 4,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36),
                                    ),
                                    Padding(padding: EdgeInsets.only(top: 8)),
                                    Text(
                                      widget.artist.numberOfTracks.toString() +
                                          " Songs",
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .color!
                                              .withAlpha(122)),
                                    ),
                                    Text(
                                      widget.artist.numberOfAlbums.toString() +
                                          " Albums",
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
                              padding: const EdgeInsets.fromLTRB(30, 8, 30, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    widget.artist.numberOfTracks.toString() +
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
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          Theme.of(context).primaryColorLight
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(80)),
                                    child: ElevatedButton(
                                      onPressed: () => playSong(songs.first,
                                          _playerBloc), // TODO change
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
                      return listItems[index];
                    }, childCount: listItems.length),
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
