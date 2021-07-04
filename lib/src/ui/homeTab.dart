import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/src/Utility.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:music_player/src/ui/widget/AlbumImageWidget.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends StatefulWidget {
  final double? bottomPadding;

  const HomeTab({Key? key, this.bottomPadding}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  PlayerBloc? _playerBloc;

  @override
  Widget build(BuildContext context) {
    _playerBloc ??= BlocProvider.of<PlayerBloc>(context);

    return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<List<PlaylistModel>?>(
            future: OnAudioQuery().queryPlaylists(),
            builder: (context, snapshot) {
              print(snapshot);
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              print(snapshot.data!.length);

              if (snapshot.data!.length == 0 ||
                  snapshot.data!
                          .where(
                              (element) => element.playlistName == "Favoriten")
                          .length !=
                      1) {
                OnAudioQuery().createPlaylist("Favoriten");
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              List<PlaylistModel> playlistInfos = snapshot.data!;

              return ListView(children: [
                Container(
                  height: 250,
                  child: ListView.separated(
                      separatorBuilder: (context, index) => Container(
                            padding: EdgeInsets.all(20),
                          ),
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        double size = 250;
                        double size1 = size * 0.93;
                        double size2 = size1 * 0.93;
                        double size3 = size2 * 0.93;
                        double left1 = (size - size * 0.955) * 2;

                        if (index == playlistInfos.length) {
                          return Container(
                            height: size,
                            width: size,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Add Playlist",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      Text(
                                        "Click the plus to add a new playlist",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF4e606e)),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.more_vert),
                                        iconSize: 25,
                                        onPressed: () =>
                                            print("Playist settings"),
                                      ),
                                      GradientButton(
                                        child: Icon(
                                          Icons.add,
                                          size: 25.0,
                                        ),
                                        shape: CircleBorder(),
                                        elevation: 2.0,
                                        gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF64a0a8),
                                              Color(0xFF3383a4),
                                            ]),
                                        onpresss: () {},
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            decoration: BoxDecoration(
                                color: Color(0xFF324452),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25))),
                          );
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [/*
                            playlistInfos[index].memberIds.length > 2
                                ? Positioned(
                                    left: left1 * 3,
                                    child: Container(
                                      height: size3,
                                      width: size3,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: AlbumArtworkImage(
                                          playlistInfos[index].memberIds![2],
                                          null,
                                          ResourceType.SONG,
                                          borderRadius: 25,
                                          audioQuery: audioQuery,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(),
                            playlistInfos[index].memberIds!.length > 1
                                ? Positioned(
                                    left: left1 * 2,
                                    child: Container(
                                      height: size2,
                                      width: size2,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: AlbumArtworkImage(
                                          playlistInfos[index].memberIds![1],
                                          null,
                                          ResourceType.SONG,
                                          borderRadius: 25,
                                          audioQuery: audioQuery,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(),
                            playlistInfos[index].memberIds!.length > 0
                                ? Positioned(
                                    left: left1,
                                    child: Container(
                                      height: size1,
                                      width: size1,
                                      child: AlbumArtworkImage(
                                        playlistInfos[index].memberIds![0],
                                        null,
                                        ResourceType.SONG,
                                        borderRadius: 25,
                                        audioQuery: audioQuery,
                                      ),
                                    ),
                                  )
                                : Container(),*/
                            Container(
                              height: size,
                              width: size,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlistInfos[index].playlistName,
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        Text(
                                          playlistInfos[index].id.toString() +
                                              " Songs",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF4e606e)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          color: Colors.white,
                                          icon: Icon(Icons.more_vert),
                                          iconSize: 25,
                                          onPressed: () =>
                                              print("Playist settings"),
                                        ),
                                        GradientButton(
                                          child: Icon(
                                            Icons.play_arrow,
                                            size: 25.0,
                                          ),
                                          shape: CircleBorder(),
                                          elevation: 2.0,
                                          gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF64a0a8),
                                                Color(0xFF3383a4),
                                              ]),
                                          onpresss: () async {/*
                                            var playlist = await audioQuery
                                                .getSongsFromPlaylist(
                                                    playlist:
                                                        playlistInfos[index]);
                                            _playerBloc!.add(PlayerPlay(
                                                playlist.first, playlist));
                                          */},
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF324452).withOpacity(1),
                                        Color(0xFF324452).withOpacity(0.6)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: [0.0, 1.0],
                                      tileMode: TileMode.clamp),
                                  /*boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 1,
                                        offset: Offset(
                                            0, 0), // changes position of shadow
                                      ),
                                    ],*/
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25))),
                            ),
                          ],
                        );
                      },
                      itemCount: playlistInfos.length + 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "Recently played",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF4e606e)),
                  ),
                ),
                RecentlyPlayedSongsList(
                  bottomPadding: widget.bottomPadding,
                  playerBloc: BlocProvider.of<PlayerBloc>(context),
                ),
              ]);
            },
          ),
        ));
  }
}

// ignore: must_be_immutable
class RecentlyPlayedSongsList extends StatefulWidget {
  final double? bottomPadding;
  final PlayerBloc? playerBloc;

  RecentlyPlayedSongsList({Key? key, this.bottomPadding, this.playerBloc})
      : super(key: key);

  @override
  _RecentlyPlayedSongsListState createState() =>
      _RecentlyPlayedSongsListState();
}

class _RecentlyPlayedSongsListState extends State<RecentlyPlayedSongsList> {
  Future? songs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SharedPreferences.getInstance().then((instance) {
      List<String>? ids = instance.getStringList("recentlyplayed");
      if (ids == null) {
        songs = Future<List<SongModel>>.value([]);
      } else
        songs = OnAudioQuery().querySongsBy(SongsByType.ID, ids);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongModel>>(
        future: songs?.then((value) => value as List<SongModel>),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text("You never played musik!",
                  style: TextStyle(
                    color: Colors.white,
                  )),
            );
          }

          List<SongModel> songs = snapshot.data!.reversed.toList();
          return ListView.builder(
            padding: EdgeInsets.only(bottom: widget.bottomPadding!),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              SongModel song = songs[index];
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
                    onTap: () =>
                        widget.playerBloc!.add(PlayerPlay(song, songs)),
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
                                child: QueryArtworkWidget(id: song.id, type: ArtworkType.ALBUM, artwork: song.artwork, deviceSDK: widget.playerBloc!.deviceModel!.sdk),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title!,
                                      overflow: TextOverflow.clip,
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    Text(
                                      song.artist!,
                                      style:
                                          TextStyle(color: Color(0xFF4e606e)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(Utility.parseToMinutesSeconds(
                                    song.duration),
                            style: TextStyle(color: Color(0xFF4e606e)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            itemCount: songs.length,
          );
        });
  }
}
