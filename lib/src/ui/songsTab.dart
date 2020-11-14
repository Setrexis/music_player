import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';

class SongTab extends StatefulWidget {
  final Future songListFuture;
  final FlutterAudioQuery audioQuery;
  final bool removePaddingTop;
  final double bottomPadding;

  const SongTab(
      {Key key,
      this.songListFuture,
      this.audioQuery,
      this.removePaddingTop = true,
      this.bottomPadding})
      : super(key: key);

  @override
  _SongTabState createState() => _SongTabState();
}

class _SongTabState extends State<SongTab> {
  String curruntSong = AudioService.currentMediaItem?.genre ?? "0";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: widget.songListFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
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
                        PlayerService.startAudioPlay(snapshot.data, song);
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
                            ((curruntSong) == song.id)
                                ? Icon(
                                    Icons.bar_chart,
                                    color: Color(0xFF4989a2),
                                  )
                                : Text(
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
