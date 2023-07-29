import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/artistTab.dart';
import 'package:music_player/src/ui/playlistTab.dart';
import 'package:music_player/src/ui/settings.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:share_plus/share_plus.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  TextEditingController _searchQueryController = TextEditingController();
  String searchQuery = "";
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: PlayerWidget(
        child: ListView(
          primary: true,
          children: [
            HeadlineWidget(),
            SearchBarWidget(),
            RecentPlayedPlaylistWidget(),
            FavoriteSongsWidget(),
          ],
        ),
      ),
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
      padding: EdgeInsets.fromLTRB(30, 30, 10, 30),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "MUSIC PLAYER",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            IconButton(
                onPressed: () =>
                    Navigator.of(context).push(new MaterialPageRoute(
                      builder: (context) => Settings(),
                    )),
                icon: Icon(Icons.settings_outlined))
          ]),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
      child: Container(
        child: InkWell(
          onTap: () => showSearch(
              context: context, delegate: CoustomSearchDelegate(_playerBloc)),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  size: 30,
                ),
                filled: true,
                border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(25)),
                fillColor: Theme.of(context).colorScheme.secondaryContainer,
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
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          if (query == '') {
            close(context, null);
          }
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
    if (query != '') _playerBloc.search(query);

    return SearchResult(
      playerBloc: _playerBloc,
      query: query,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query != '') _playerBloc.search(query);

    return SearchResult(
      playerBloc: _playerBloc,
      query: query,
    );
  }
}

class SearchResult extends StatefulWidget {
  final PlayerBloc playerBloc;
  final String query;
  const SearchResult({Key? key, required this.playerBloc, required this.query})
      : super(key: key);

  @override
  _SearchResultState createState() => _SearchResultState();
}

class _SearchResultState extends State<SearchResult> {
  List<bool> _isSelected = [false, false, false, false];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: ListView(
        children: [
          Wrap(spacing: 8, children: [
            ChoiceChip(
              label: Text('Songs'),
              selected: _isSelected[0],
              onSelected: (bool selected) {
                setState(() {
                  _isSelected[0] = selected;
                });
              },
            ),
            ChoiceChip(
              label: Text('Albums'),
              selected: _isSelected[1],
              onSelected: (bool selected) {
                setState(() {
                  _isSelected[1] = selected;
                });
              },
            ),
            ChoiceChip(
              label: Text('Artists'),
              selected: _isSelected[2],
              onSelected: (bool selected) {
                setState(() {
                  _isSelected[2] = selected;
                });
              },
            ),
            ChoiceChip(
              label: Text('Playlists'),
              selected: _isSelected[3],
              onSelected: (bool selected) {
                setState(() {
                  _isSelected[3] = selected;
                });
              },
            ),
          ]),
          widget.query != ''
              ? StreamBuilder<CombinedSearchStream>(
                  stream: widget.playerBloc.combinedSearchStreams(_isSelected),
                  builder: (context, snapshot) {
                    return SearchResultList(
                        playerBloc: widget.playerBloc,
                        searchElements: snapshot.data?.searchElements);
                  },
                )
              : StreamBuilder<List<dynamic>>(
                  stream: widget.playerBloc.searchHistory$,
                  builder: (context, snapshot) {
                    return SearchResultList(
                        playerBloc: widget.playerBloc,
                        searchElements: snapshot.data);
                  },
                ),
        ],
      ),
    );
  }
}

class SearchResultList extends StatelessWidget {
  const SearchResultList({
    Key? key,
    required this.searchElements,
    required this.playerBloc,
  }) : super(key: key);

  final List<dynamic>? searchElements;
  final PlayerBloc playerBloc;

  @override
  Widget build(BuildContext context) {
    if (searchElements == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchElements!.isEmpty) {
      return Center(
        child: Text("No results found"),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      itemCount: searchElements!.length,
      itemBuilder: (context, index) {
        dynamic searchElement = searchElements![index];
        switch (searchElement.runtimeType) {
          case SongModel:
            SongModel song = searchElement as SongModel;
            return SongListItem(
              playerBloc: playerBloc,
              song: song,
              onTap: (song, _playerBloc) {
                List<SongModel> songs = [song];
                _playerBloc.startPlayback(songs);
                _playerBloc.addToSearchHistory(searchElement);
              },
            );
          case AlbumModel:
            return AlbumListItem(
              album: searchElement,
              onTap: (album) => {
                Navigator.of(context).push(new MaterialPageRoute(
                  builder: (context) => AlbumOverview(album: album),
                )),
                playerBloc.addToSearchHistory(searchElement),
              },
            );
          case ArtistModel:
            return ArtistListItem(
              artist: searchElement,
              onTap: (artist) {
                Navigator.of(context).push(new MaterialPageRoute(
                  builder: (context) => ArtistOverview(artist: artist),
                ));
                playerBloc.addToSearchHistory(searchElement);
              },
            );
          case PlaylistModel:
            return PlaylistListItem(
              playlist: searchElement,
              onTap: (playlist) {
                Navigator.of(context).push(new MaterialPageRoute(
                  builder: (context) => PlaylistOverview(playlist: playlist),
                ));
                playerBloc.addToSearchHistory(searchElement);
              },
            );
          default:
            return Container();
        }
      },
    );
  }
}

class ExpandableListView extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final int itemCount;
  final String name;
  const ExpandableListView(
      {Key? key,
      required this.itemBuilder,
      required this.separatorBuilder,
      required this.itemCount,
      required this.name})
      : super(key: key);

  @override
  _ExpandableListViewState createState() => _ExpandableListViewState();
}

class _ExpandableListViewState extends State<ExpandableListView> {
  bool state = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: state
          ? widget.itemCount * 71 + 24
          : min(3, widget.itemCount) * 71 + 76,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.itemCount > 0
              ? Text(widget.name,
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
              : Container(),
          ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemBuilder: widget.itemBuilder,
              separatorBuilder: widget.separatorBuilder,
              itemCount: state ? widget.itemCount : min(3, widget.itemCount)),
          (!state && widget.itemCount != 0) && widget.itemCount > 3
              ? Center(
                  child: TextButton(
                      onPressed: () => setState(() {
                            state = true;
                          }),
                      child: Text("Mehr anzeigen")),
                )
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
  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
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
                style: TextStyle(fontSize: 20),
              ),
            ),
            Container(
              height: 270,
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

  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
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
              child: FutureBuilder<List<SongModel>>(
                  future: _playerBloc.getPlaylistSongs(widget.playlist.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        child: Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Theme.of(context).colorScheme.background),
                      );
                    }

                    firstPlaylistSong = snapshot.data!.last;
                    print(firstPlaylistSong);

                    return QueryArtworkWidget(
                      id: firstPlaylistSong!.albumId ?? -1,
                      type: ArtworkType.ALBUM,
                      keepOldArtwork: true,
                      nullArtworkWidget: Icon(Icons.music_note),
                    );
                  }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 5, 0),
              child: Text(
                widget.playlist.playlist,
              ),
            ),
            Text(
              widget.playlist.numOfSongs.toString() + " Songs",
            )
          ]),
    );
  }
}

class FavoriteSongsWidget extends StatefulWidget {
  const FavoriteSongsWidget({Key? key}) : super(key: key);

  @override
  _FavoriteSongWidgetState createState() => _FavoriteSongWidgetState();
}

class _FavoriteSongWidgetState extends State<FavoriteSongsWidget> {
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
                style: TextStyle(fontSize: 20),
              ),
            ),
            StreamBuilder<List<SongModel>>(
                stream: _playerBloc.favorits$.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  songs = snapshot.data!;
                  if (songs.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          IconButton(
                              onPressed: () => print("add songs"),
                              icon: Icon(
                                Icons.favorite,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              )),
                          Padding(padding: const EdgeInsets.all(20)),
                          Text("Tap the heart to add songs to your favorites"),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: new List.generate(
                        snapshot.data!.length,
                        (index) => SongListItem(
                              playerBloc: _playerBloc,
                              song: snapshot.data![index],
                              onTap: playSong,
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
    this.onTap,
    this.left,
    this.artist = true,
    this.album = true,
  })  : _playerBloc = playerBloc,
        super(key: key);

  final PlayerBloc _playerBloc;
  final SongModel song;
  final Function? onTap;
  final Widget? left;

  final bool artist;
  final bool album;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: InkWell(
        onTap: () => onTap == null
            ? _playerBloc.startPlayback([song])
            : onTap!(song, _playerBloc),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(20),
                  keepOldArtwork: true,
                  size: 150,
                  nullArtworkWidget: QueryArtworkWidget(
                    id: song.albumId ?? -1,
                    type: ArtworkType.ALBUM,
                    artworkBorder: BorderRadius.circular(20),
                    keepOldArtwork: true,
                    size: 150,
                    nullArtworkWidget: Icon(
                      Icons.music_note,
                      size: 50,
                    ),
                  ),
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
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          song.artist ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            /*StreamBuilder<List<SongModel>>(
                stream: _playerBloc.favorits$.stream,
                builder: (context, snapshot) {
                  bool fav = !snapshot.hasData ||
                      snapshot.data!.any((element) => element.id == song.id);
                  return IconButton(
                    onPressed: fav
                        ? _playerBloc.removeFromFavorits(song.id)
                        : _playerBloc.addToFavorits(song.id),
                    icon: Icon(Icons.favorite),
                    color: fav ? Color(0xffff16ce) : Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .color!
                                        .withAlpha(122),
                  );
                })*/
            left == null
                ? PopupMenuButton<SongOptions>(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    onSelected: (value) {
                      switch (value) {
                        case SongOptions.share:
                          Share.shareFiles([song.data],
                              text: song.title + " by " + song.artist!);
                          break;
                        case SongOptions.favorits:
                          _playerBloc.addToFavorits(song.id);
                          break;
                        case SongOptions.addToPlaylist:
                          List<PlaylistModel> p = _playerBloc.playlists$.value;
                          showDialog(
                            context: context,
                            builder: (context) => SimpleDialog(
                                children: List.generate(
                              p.length,
                              (index) => SimpleDialogOption(
                                child: Text(p[index].playlist),
                                onPressed: () {
                                  OnAudioQuery()
                                      .addToPlaylist(p[index].id, song.id);
                                },
                              ),
                            )),
                          );
                          break;
                        case SongOptions.addToQueue:
                          _playerBloc.addItemToQueue(song);
                          break;
                        case SongOptions.album:
                          Navigator.of(context).push(new MaterialPageRoute(
                            builder: (context) => AlbumOverview(
                              album: _playerBloc.albums$.value.firstWhere(
                                  (element) => element.id == song.albumId),
                            ),
                          ));
                          break;
                        case SongOptions.artist:
                          Navigator.of(context).push(new MaterialPageRoute(
                            builder: (context) => ArtistOverview(
                                artist: _playerBloc.artists$.value.firstWhere(
                                    (element) => element.id == song.artistId)),
                          ));
                          break;
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<SongOptions>>[
                      const PopupMenuItem(
                        child: Text("Share"),
                        value: SongOptions.share,
                      ),
                      const PopupMenuItem(
                        child: Text("Add to favorits"),
                        value: SongOptions.favorits,
                      ),
                      const PopupMenuItem(
                        child: Text("Add to playlist"),
                        value: SongOptions.addToPlaylist,
                      ),
                      const PopupMenuItem(
                        child: Text("Add to queue"),
                        value: SongOptions.addToQueue,
                      ),
                      if (album)
                        const PopupMenuItem(
                          child: Text("Album"),
                          value: SongOptions.album,
                        ),
                      if (artist)
                        const PopupMenuItem(
                          child: Text("Artist"),
                          value: SongOptions.artist,
                        ),
                    ],
                  )
                : left!,
          ],
        ),
      ),
    );
  }
}

enum SongOptions { share, favorits, addToPlaylist, addToQueue, album, artist }

class ArtistListItem extends StatelessWidget {
  const ArtistListItem({
    Key? key,
    required this.artist,
    this.onTap,
  }) : super(key: key);

  final ArtistModel artist;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: InkWell(
        onTap: () => onTap == null
            ? Navigator.of(context).push(new MaterialPageRoute(
                builder: (context) => ArtistOverview(artist: artist),
              ))
            : onTap!(artist),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Theme.of(context).primaryColorLight,
                    child: Icon(Icons.person, size: 50),
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
                          artist.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          artist.numberOfAlbums.toString() + " Albums",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

class AlbumListItem extends StatelessWidget {
  const AlbumListItem({
    Key? key,
    required this.album,
    this.onTap,
  }) : super(key: key);

  final AlbumModel album;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: InkWell(
        onTap: () => onTap == null
            ? Navigator.of(context).push(new MaterialPageRoute(
                builder: (context) => AlbumOverview(album: album),
              ))
            : onTap!(album),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Theme.of(context).primaryColorLight,
                    child: Icon(Icons.album, size: 50),
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
                          album.album,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          album.artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}

class PlaylistListItem extends StatelessWidget {
  const PlaylistListItem({
    Key? key,
    required this.playlist,
    this.onTap,
  }) : super(key: key);

  final PlaylistModel playlist;
  final Function? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: InkWell(
        onTap: () => onTap == null
            ? Navigator.of(context).push(new MaterialPageRoute(
                builder: (context) => PlaylistOverview(playlist: playlist),
              ))
            : onTap!(playlist),
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
                    child: Icon(Icons.playlist_play, size: 50),
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
                          playlist.playlist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          playlist.numOfSongs.toString() + " Songs",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          ],
        ),
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
        leading: FutureBuilder<Uint8List?>(
            future: OnAudioQuery()
                .queryArtwork(songList[index].id, ArtworkType.ALBUM),
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
            }),
        title: Text(songList[index].title),
        subtitle: Text(songList[index].artist!),
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
