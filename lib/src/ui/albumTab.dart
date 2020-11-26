import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player/src/ui/deteilsPage.dart';
import 'package:music_player/src/ui/songsTab.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';

class AlbumTab extends StatefulWidget {
  final Future albumListFuture;
  final bool removePaddingTop;
  final double bottomPadding;
  final Function resetSearch;
  final bool searching;

  const AlbumTab(
      {Key key,
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
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AlbumInfo>>(
        future: widget.albumListFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data.isEmpty) {
            if (widget.searching)
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
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
                itemCount: snapshot.data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 60,
                    crossAxisSpacing: 20),
                itemBuilder: (context, index) {
                  AlbumInfo album = snapshot.data[index];
                  return Container(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(new MaterialPageRoute(
                          builder: (context) => DetailPage(
                            title: album.title,
                            child: SongTab(
                              audioQuery: audioQuery,
                              songListFuture: audioQuery.getSongsFromAlbum(
                                  albumId: album.id),
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
                            child: AlbumArtworkImage(
                                album.id, album.albumArt, ResourceType.ALBUM,
                                audioQuery: audioQuery),
                          ),
                          Column(
                            children: [
                              Text(
                                album.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                album.artist +
                                    " | " +
                                    album.numberOfSongs +
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
