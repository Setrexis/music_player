import 'package:flutter/material.dart';
import 'package:music_player/src/ui/albumTab.dart';
import 'package:music_player/src/ui/deteilsPage.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:on_audio_query/on_audio_query.dart';

class GenreTab extends StatefulWidget {
  final double? bottomPadding;
  final Future<List<GenreModel>>? genreData;
  final Function? resetSearch;
  final bool? searching;

  const GenreTab(
      {Key? key,
      this.bottomPadding,
      this.genreData,
      this.resetSearch,
      this.searching})
      : super(key: key);

  @override
  _GenreTabState createState() => _GenreTabState();
}

class _GenreTabState extends State<GenreTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder<List<GenreModel>>(
        future: widget.genreData,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.isEmpty) {
            if (widget.searching!)
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
                padding: EdgeInsets.only(bottom: widget.bottomPadding!),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  GenreModel? genre = snapshot.data![index];
                  return GenreItem(
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
  final GenreModel? genre;

  const GenreItem({Key? key, this.genre}) : super(key: key);

  @override
  _GenreItemState createState() => _GenreItemState();
}

class _GenreItemState extends State<GenreItem> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: () => Navigator.of(context).push(new MaterialPageRoute(
          builder: (context) => DetailPage(
            child: AlbumTab(
              albumListFuture: OnAudioQuery().queryAlbums(),
            ),
            title: widget.genre!.genreName,
          ),
        )),
        child: AlbumArtBackground(
          child: Text(widget.genre!.genreName),
          id: widget.genre!.id.toString(),
          artwork: widget.genre!.artwork,
        ),
      ),
    );
  }
}
