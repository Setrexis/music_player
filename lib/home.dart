import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/ui/playlistTab.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  TextEditingController _searchQueryController = TextEditingController();
  bool _isSearching = false;
  String searchQuery = "";

  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF260e43),
      body: PlayerWidget(
        child: ListView(
          primary: true,
          children: [
            HeadlineWidget(),
            SearchBarWidget(),
            RecentPlayedPlaylistWidget(),
            FavroritSongsWidget(),
          ],
        ),
      ),
    );
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
  }

  void resetSearchQuery() {
    _searchQueryController.clear();
  }
}

class HeadlineWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(30, 50, 10, 10),
      child: Text(
        "MUSIC PLAYER",
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
      child: Container(
        child: InkWell(
          onTap: () => showSearch(
              context: context, delegate: CoustomSearchDelegate(_playerBloc)),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: "Song, artist or album ..."),
          ),
        ),
      ),
    );
  }
}

class CoustomSearchDelegate extends SearchDelegate {
  final PlayerBloc _playerBloc;

  CoustomSearchDelegate(this._playerBloc);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    _playerBloc.search(query);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        children: [
          StreamBuilder<List>(
            stream: _playerBloc.songsSearch$,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return ExpandableListView(
                  itemBuilder: (context, index) => SongListItem(
                      playerBloc: _playerBloc, song: snapshot.data![index]),
                  separatorBuilder: (context, index) => SizedBox(height: 5),
                  itemCount: snapshot.data!.length);
            },
          ),
          StreamBuilder<List>(
            stream: _playerBloc.albumsSearch$,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return ExpandableListView(
                  itemBuilder: (context, index) =>
                      AlbumListItem(album: snapshot.data![index]),
                  separatorBuilder: (context, index) => SizedBox(height: 5),
                  itemCount: snapshot.data!.length);
            },
          ),
          StreamBuilder<List>(
            stream: _playerBloc.artistsSearch$,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return ExpandableListView(
                  itemBuilder: (context, index) =>
                      ArtistListItem(artist: snapshot.data![index]),
                  separatorBuilder: (context, index) => SizedBox(height: 5),
                  itemCount: snapshot.data!.length);
            },
          ),
          StreamBuilder<List>(
            stream: _playerBloc.playlistsSearch$,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return ExpandableListView(
                  itemBuilder: (context, index) =>
                      PlaylistListItem(playlist: snapshot.data![index]),
                  separatorBuilder: (context, index) => SizedBox(height: 5),
                  itemCount: snapshot.data!.length);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}

class ExpandableListView extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final int itemCount;
  const ExpandableListView(
      {Key? key,
      required this.itemBuilder,
      required this.separatorBuilder,
      required this.itemCount})
      : super(key: key);

  @override
  _ExpandableListViewState createState() => _ExpandableListViewState();
}

class _ExpandableListViewState extends State<ExpandableListView> {
  bool state = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          state ? widget.itemCount * 70 : min(3, widget.itemCount) * 70 + 48,
      child: Column(
        children: [
          Expanded(
              child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: widget.itemBuilder,
                  separatorBuilder: widget.separatorBuilder,
                  itemCount:
                      state ? widget.itemCount : min(3, widget.itemCount))),
          !state || widget.itemCount > 3
              ? TextButton(
                  onPressed: () => setState(() {
                        state = true;
                      }),
                  child: Text("Mehr anzeigen"))
              : Container()
        ],
      ),
    );
  }
}

class RecentPlayedPlaylistWidget extends StatefulWidget {
  const RecentPlayedPlaylistWidget({Key? key}) : super(key: key);

  @override
  _RecentPlayedPlaylistWidgetState createState() =>
      _RecentPlayedPlaylistWidgetState();
}

class _RecentPlayedPlaylistWidgetState
    extends State<RecentPlayedPlaylistWidget> {
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
      height: 370,
      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              child: Text(
                "Playlists",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            Container(
              height: 266,
              child: StreamBuilder<List<PlaylistModel>>(
                  stream: _playerBloc.playlists$.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox(
                        child: CircularProgressIndicator(),
                        height: 250,
                      );
                    }
                    return Container(
                      padding: EdgeInsets.only(left: 30),
                      child: Expanded(
                        child: ListView.separated(
                          separatorBuilder: (context, index) => SizedBox(
                            width: 10,
                          ),
                          shrinkWrap: true,
                          primary: false,
                          physics: ClampingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) => Container(
                            child: PlaylistWidget(snapshot.data![index]),
                            height: 250,
                            width: 220,
                          ),
                          itemCount: snapshot.data!.length,
                        ),
                      ),
                    );
                  }),
            ),
          ]),
    );
  }
}

class PlaylistWidget extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistWidget(this.playlist, {Key? key}) : super(key: key);

  @override
  _PlaylistWidgetState createState() => _PlaylistWidgetState();
}

class _PlaylistWidgetState extends State<PlaylistWidget> {
  SongModel? firstPlaylistSong;
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PlaylistOverview(
            playlist: widget.playlist, coverSong: firstPlaylistSong),
      )),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 220,
              width: 220,
              child: StreamBuilder<List<SongModel>>(
                  stream: _playerBloc.songs$.stream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData ||
                        widget.playlist.memberIDs.isEmpty) {
                      return Icon(Icons.music_note);
                    }

                    firstPlaylistSong = snapshot.data!.firstWhere((element) =>
                        element.id.toString() ==
                        widget.playlist.memberIDs[0].toString());

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                          alignment: Alignment.topLeft,
                          height: 220,
                          width: 220,
                          color: Color(0xFF3e235f),
                          child: firstPlaylistSong!.artwork == null
                              ? FutureBuilder<Uint8List?>(
                                  builder: (context, snapshot) =>
                                      snapshot.hasData
                                          ? Image.memory(
                                              snapshot.data!,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(Icons.music_note),
                                  future: OnAudioQuery().queryArtworks(
                                      firstPlaylistSong!.id, ArtworkType.AUDIO),
                                )
                              : Image.file(File(firstPlaylistSong!.artwork!))),
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
              child: Text(
                widget.playlist.playlistName,
                style: TextStyle(color: Colors.white),
              ),
            ),
            Text(widget.playlist.memberIDs.length.toString() + " Songs",
                style: TextStyle(color: Colors.white70))
          ]),
    );
  }
}

class FavroritSongsWidget extends StatefulWidget {
  const FavroritSongsWidget({Key? key}) : super(key: key);

  @override
  _FavroritSongWidgetState createState() => _FavroritSongWidgetState();
}

class _FavroritSongWidgetState extends State<FavroritSongsWidget> {
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Text(
                "Favorits",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            StreamBuilder<List<SongModel>>(
                stream: _playerBloc.favorits$.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  return Column(
                    children: new List.generate(
                        snapshot.data!.length,
                        (index) => SongListItem(
                              playerBloc: _playerBloc,
                              song: snapshot.data![index],
                            )),
                  );
                }),
          ]),
    );
  }
}

class SongListItem extends StatelessWidget {
  const SongListItem({
    Key? key,
    required PlayerBloc playerBloc,
    required this.song,
  })  : _playerBloc = playerBloc,
        super(key: key);

  final PlayerBloc _playerBloc;
  final SongModel song;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              QueryArtworkWidget(
                id: song.id,
                type: ArtworkType.AUDIO,
                artwork: song.artwork,
                deviceSDK: _playerBloc.deviceModel!.sdk,
                artworkBorder: BorderRadius.circular(20),
                keepOldArtwork: true,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 186,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        song.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
          StreamBuilder<List<SongModel>>(
              stream: _playerBloc.favorits$.stream,
              builder: (context, snapshot) {
                bool fav = !snapshot.hasData ||
                    snapshot.data!.any((element) => element.id == song.id);
                return IconButton(
                  onPressed: fav
                      ? _playerBloc.removeFromFavorits(song.id)
                      : _playerBloc.addToFavorits(song.id),
                  icon: Icon(Icons.favorite),
                  color: fav ? Color(0xffff16ce) : Colors.white70,
                );
              })
        ],
      ),
    );
  }
}

class ArtistListItem extends StatelessWidget {
  const ArtistListItem({
    Key? key,
    required this.artist,
  }) : super(key: key);

  final ArtistModel artist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.amber,
                  child: Icon(Icons.person),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        artist.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        artist.numberOfAlbums + " Albums",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class AlbumListItem extends StatelessWidget {
  const AlbumListItem({
    Key? key,
    required this.album,
  }) : super(key: key);

  final AlbumModel album;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.amber,
                  child: Icon(Icons.album),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        album.albumName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class PlaylistListItem extends StatelessWidget {
  const PlaylistListItem({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.amber,
                  child: Icon(Icons.playlist_play),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        playlist.playlistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        playlist.memberIDs.length.toString() + " Songs",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class SongListWidget extends StatelessWidget {
  final List<SongModel> songList;
  final int deviceSDK;

  SongListWidget({required this.songList, required this.deviceSDK});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: ClampingScrollPhysics(),
      primary: false,
      shrinkWrap: true,
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
