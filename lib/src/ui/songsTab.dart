import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/home.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';

class SongTab extends StatefulWidget {
  final Future songListFuture;
  final FlutterAudioQuery audioQuery;
  final bool removePaddingTop;
  final double bottomPadding;
  final bool searching;
  final Function resetSearch;

  const SongTab(
      {Key key,
      this.songListFuture,
      this.audioQuery,
      this.removePaddingTop = true,
      this.bottomPadding = 0.0,
      this.searching,
      this.resetSearch})
      : super(key: key);

  @override
  _SongTabState createState() => _SongTabState();
}

class _SongTabState extends State<SongTab> {
  String curruntSong = AudioService.currentMediaItem?.genre ?? "0";
  PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongInfo>>(
      future: widget.songListFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data.isEmpty) {
          if (widget.searching)
            return NoDataWidget(
                title: "Not the Song you've been looking for?",
                subtitle: "We could not find a song matching your search.",
                actionIcon: Icon(Icons.search),
                action: widget.resetSearch,
                actionText: "New Search",
                icon: Icons.not_listed_location_outlined);
          else
            return NoDataWidget(
              icon: Icons.music_off,
              title: "Ups!",
              subtitle: "We could not find any musik.",
            );
        }

        return MediaQuery.removePadding(
          context: context,
          removeTop: widget.removePaddingTop,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: false,
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              itemBuilder: (context, index) {
                SongInfo song = snapshot.data[index];
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
                        _playerBloc.add(PlayerPlay(song, snapshot.data));
                        setState(() {
                          curruntSong = song.id;
                        });
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
                                  child: AlbumArtworkImage(song.id,
                                      song.albumArtwork, ResourceType.SONG,
                                      audioQuery: widget.audioQuery),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        song.title,
                                        overflow: TextOverflow.clip,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      Text(
                                        song.artist,
                                        style:
                                            TextStyle(color: Color(0xFF4e606e)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              song.duration == null
                                  ? Utility.parseToMinutesSeconds(0)
                                  : Utility.parseToMinutesSeconds(
                                      int.tryParse(song.duration)),
                              style: TextStyle(color: Color(0xFF4e606e)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: snapshot.data.length,
            ),
          ),
        );
      },
    );
  }
}
