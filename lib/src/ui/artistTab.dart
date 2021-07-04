import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/deteilsPage.dart';
import 'package:music_player/src/ui/songsTab.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtistTab extends StatefulWidget {
  final double? bottomPadding;
  final Future? data;
  final Function? resetSearch;
  final bool? searching;

  const ArtistTab(
      {Key? key,
      this.bottomPadding,
      this.data,
      this.resetSearch,
      this.searching})
      : super(key: key);

  @override
  _ArtistTabState createState() => _ArtistTabState();
}

class _ArtistTabState extends State<ArtistTab> {
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
      child: FutureBuilder<List<ArtistModel>>(
          future: widget.data?.then((value) => value as List<ArtistModel>),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.isEmpty) {
              if (widget.searching!)
                return NoDataWidget(
                    title: "Not the artist you've been looking for?",
                    subtitle:
                        "We could not find a artist matching your search.",
                    actionIcon: Icon(Icons.search),
                    action: widget.resetSearch,
                    actionText: "New Search",
                    icon: Icons.not_listed_location_outlined);
              else
                return NoDataWidget(
                  icon: Icons.music_off,
                  title: "Ups!",
                  subtitle: "We could not find any artists.",
                );
            }

            List<ArtistModel> artists = snapshot.data!;

            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  padding: EdgeInsets.only(bottom: widget.bottomPadding!),
                  itemBuilder: (context, index) {
                    ArtistModel artist = artists[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                                colors: [Color(0xFF2d4351), Color(0xFF1f313d)],
                                begin: Alignment.centerLeft,
                                end: Alignment.bottomRight,
                                stops: [0.0, 1.0],
                                tileMode: TileMode.clamp)),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(new MaterialPageRoute(
                                builder: (context) => DetailPage(
                                      title: artist.artistName,
                                      child: ArtistInfoDeteils(
                                        info: artist,
                                      ),
                                    )));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      child: QueryArtworkWidget(id: artist.id, type: ArtworkType.ALBUM, artwork: artist.artwork, deviceSDK: _playerBloc.deviceModel!.sdk)
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            artist.artistName,
                                            overflow: TextOverflow.clip,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                          Text(
                                            artist.numberOfAlbums +
                                                " | " +
                                                artist.numberOfTracks!,
                                            style: TextStyle(
                                                color: Color(0xFF4e606e)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: artists.length,
                ),
              ),
            );
          }),
    );
  }
}

class ArtistInfoDeteils extends StatelessWidget {
  final ArtistModel? info;

  const ArtistInfoDeteils({Key? key, this.info}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AlbumTab(
            removePaddingTop: false,
            albumListFuture: OnAudioQuery().queryAlbums(),
          ),
        ),
        Expanded(
          child: SongTab(
            removePaddingTop: false,
            songListFuture:
                OnAudioQuery().querySongsBy(SongsByType.ID, [info!.id]),
          ),
        )
      ],
    );
  }
}
