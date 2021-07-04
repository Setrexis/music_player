import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/bloc/radio/station_bloc.dart';
import 'package:music_player/src/bloc/radio/station_event.dart';
import 'package:music_player/src/ui/artistTab.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/genreTab.dart';
import 'package:music_player/src/ui/homeTab.dart';
import 'package:music_player/src/ui/onlineRadioTab.dart';
import 'package:music_player/src/ui/songsTab.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  TextEditingController _searchQueryController = TextEditingController();
  bool _isSearching = false;
  String searchQuery = "";
  StationBloc? _stationBolc;

  @override
  Widget build(BuildContext context) {
    _stationBolc ??= BlocProvider.of(context);

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
                      _isSearching
                          ? IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => setState(() {
                                _isSearching = false;
                                _searchQueryController.clear();
                              }),
                            )
                          : IconButton(
                              icon: Icon(Icons.search),
                              onPressed: () => setState(() {
                                _isSearching = true;
                              }),
                              color: Color(0xFF55889d),
                            )
                    ],
                    leading: _isSearching
                        ? Icon(Icons.search)
                        : IconButton(
                            color: Color(0xFF586a78),
                            icon: Icon(Icons.sort),
                            onPressed: () {},
                          ),
                    title: _isSearching ? _buildSearchField() : Container(),
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
                            _isSearching ? "Search" : "Discover",
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
                                    bottomPadding: paddingBottom,
                                  ),
                                ),
                                ArtistTab(
                                  bottomPadding: paddingBottom,
                                  data: _isSearching
                                      ? OnAudioQuery().queryArtists()
                                      //query: searchQuery)
                                      : OnAudioQuery().queryArtists(),
                                  resetSearch: resetSearchQuery,
                                  searching: _isSearching,
                                ),
                                AlbumTab(
                                  albumListFuture: _isSearching
                                      ? OnAudioQuery().queryAlbums()
                                      //query: searchQuery)
                                      : OnAudioQuery().queryAlbums(),
                                  bottomPadding: paddingBottom,
                                  resetSearch: resetSearchQuery,
                                  searching: _isSearching,
                                ),
                                GenreTab(
                                  bottomPadding: paddingBottom,
                                  genreData: _isSearching
                                      ? OnAudioQuery().queryGenres()
                                      //query: searchQuery)
                                      : OnAudioQuery().queryGenres(),
                                  resetSearch: resetSearchQuery,
                                  searching: _isSearching,
                                ),
                                SongTab(
                                  songListFuture: _isSearching
                                      ? OnAudioQuery().queryWithFilters(
                                          searchQuery,
                                          WithFiltersType.AUDIOS,
                                          "")
                                      : OnAudioQuery().querySongs(),
                                  bottomPadding: paddingBottom,
                                  searching: _isSearching,
                                  resetSearch: resetSearchQuery,
                                ),
                                OnlineRadioTabSearch(
                                  bottomPadding: paddingBottom,
                                  search: searchQuery,
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  )),
            ),
            BottomPlayerBar()
          ]);
        });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search ...",
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white),
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => updateSearchQuery(query),
    );
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
    _stationBolc!.add(StationSearch(search: newQuery));
  }

  void resetSearchQuery() {
    _searchQueryController.clear();
  }
}

class SongListWidget extends StatelessWidget {
  final List<SongModel> songList;
  final int deviceSDK;

  SongListWidget(
      {required Key key, required this.songList, required this.deviceSDK})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: songList.length,
      itemBuilder: (context, index) => ListTile(
        leading: (songList[index].artwork == null)
            ? FutureBuilder<Uint8List?>(
                future: OnAudioQuery()
                    .queryArtworks(songList[index].id, ArtworkType.ALBUM),
                builder: (_, snapshot) {
                  if (snapshot.data == null || !snapshot.hasData)
                    return Center(
                      child: CircularProgressIndicator(),
                    );

                  if (snapshot.data!.isEmpty) {
                    return Icon(Icons.music_note);
                  }

                  return Container(
                    height: 80,
                    width: 80,
                    child: Image.memory(
                      snapshot.data!,
                    ),
                  );
                })
            : Image.file(File(songList[index].artwork!)),
        title: Text(songList[index].title),
        subtitle: Text(songList[index].artist),
      ),
    );
  }
}

class CircleTabIndicator extends Decoration {
  final BoxPainter _painter;

  CircleTabIndicator({required Color color, required double radius})
      : _painter = _CirclePainter(color, radius);

  void nothing() {}

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _painter;
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
        offset + Offset(cfg.size!.width / 2, cfg.size!.height - radius - 5);
    canvas.drawCircle(circleOffset, radius, _paint);
  }
}
