import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/ui/deteilsPage.dart';
import 'package:music_player/src/ui/songsTab.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AlbumTab extends StatefulWidget {
  final Future? albumListFuture;
  final bool removePaddingTop;
  final double? bottomPadding;
  final Function? resetSearch;
  final bool? searching;

  const AlbumTab(
      {Key? key,
      this.albumListFuture,
      this.removePaddingTop = true,
      this.bottomPadding,
      this.resetSearch,
      this.searching})
      : super(key: key);

  @override
  _AlbumTabState createState() => _AlbumTabState();
}

class _AlbumTabState extends State<AlbumTab> {
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AlbumModel>>(
        future:
            widget.albumListFuture?.then((value) => value as List<AlbumModel>),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.isEmpty) {
            if (widget.searching!)
              return NoDataWidget(
                  title: "Not the album you've been looking for?",
                  subtitle: "We could not find a album matching your search.",
                  actionIcon: Icon(Icons.search),
                  action: widget.resetSearch,
                  actionText: "New Search",
                  icon: Icons.not_listed_location_outlined);
            else
              return NoDataWidget(
                icon: Icons.music_off,
                title: "Ups!",
                subtitle: "We could not find any albums.",
              );
          }

          return MediaQuery.removePadding(
            context: context,
            removeTop: widget.removePaddingTop,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GridView.builder(
                padding: EdgeInsets.only(bottom: widget.bottomPadding!),
                itemCount: snapshot.data!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 60,
                    crossAxisSpacing: 20),
                itemBuilder: (context, index) {
                  AlbumModel album = snapshot.data![index];
                  return Container(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(new MaterialPageRoute(
                          builder: (context) => DetailPage(
                            title: album.albumName,
                            child: SongTab(
                              removePaddingTop: false,
                            ),
                          ),
                        ));
                      },
                      child: Wrap(
                        direction: Axis.horizontal,
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                              child: QueryArtworkWidget(
                                  id: album.id,
                                  type: ArtworkType.ALBUM,
                                  artwork: album.artwork,
                                  deviceSDK: _playerBloc.deviceModel!.sdk)),
                          Column(
                            children: [
                              Text(
                                album.albumName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                album.artist +
                                    " | " +
                                    album.numOfSongs +
                                    " Songs",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        });
  }
}
