import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/deteilsPage.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';

class GenreTab extends StatefulWidget {
  final double bottomPadding;
  final Future genreData;
  final Function resetSearch;
  final bool searching;

  const GenreTab(
      {Key key,
      this.bottomPadding,
      this.genreData,
      this.resetSearch,
      this.searching})
      : super(key: key);

  @override
  _GenreTabState createState() => _GenreTabState();
}

class _GenreTabState extends State<GenreTab> {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder(
        future: widget.genreData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data.isEmpty) {
            if (widget.searching)
              return NoDataWidget(
                  title: "Not the Genre you've been looking for?",
                  subtitle: "We could not find a genre matching your search.",
                  actionIcon: Icon(Icons.search),
                  action: widget.resetSearch,
                  actionText: "New Search",
                  icon: Icons.not_listed_location_outlined);
            else
              return NoDataWidget(
                icon: Icons.music_off,
                title: "Ups!",
                subtitle: "We could not find any genres.",
              );
          }

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  GenreInfo genre = snapshot.data[index];
                  return GenreItem(
                    audioQuery: audioQuery,
                    genre: genre,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class GenreItem extends StatefulWidget {
  final GenreInfo genre;
  final FlutterAudioQuery audioQuery;

  const GenreItem({Key key, this.genre, this.audioQuery}) : super(key: key);

  @override
  _GenreItemState createState() => _GenreItemState();
}

class _GenreItemState extends State<GenreItem> {
  String albumid = "0";
  Future albumListFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    albumListFuture =
        widget.audioQuery.getAlbumsFromGenre(genre: widget.genre.name);
    albumListFuture.then((value) => setState(() {
          albumid = value[0].id;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: () => Navigator.of(context).push(new MaterialPageRoute(
          builder: (context) => DetailPage(
            child: AlbumTab(
              albumListFuture: albumListFuture,
            ),
            title: widget.genre.name,
          ),
        )),
        child: AlbumArtBackground(
          audioQuery: widget.audioQuery,
          child: Text(widget.genre.name),
          type: ResourceType.ALBUM,
          id: albumid,
        ),
      ),
    );
  }
}
