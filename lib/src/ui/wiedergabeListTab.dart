import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/home.dart';
import 'package:music_player/src/ui/playerWidget.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

class WiedergabeListe extends StatefulWidget {
  const WiedergabeListe({Key? key}) : super(key: key);

  @override
  _WiedergabeListeState createState() => _WiedergabeListeState();
}

class _WiedergabeListeState extends State<WiedergabeListe> {

  @override
  Widget build(BuildContext context) {
    final _playerBloc = InheritedProvider.of(context)!.inheritedData;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          title: Text("Next up"),
        ),
        body: Container(
          padding: const EdgeInsets.only(top: 90),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                Theme.of(context).canvasColor,
                Theme.of(context).backgroundColor
              ])),
          child: PlayerWidget(
            child: StreamBuilder<List<SongModel>>(
              stream: _playerBloc.inbetweenqueue$,
              builder: (context, inbetweemque) {
                return StreamBuilder<List<SongModel>>(
                    stream: _playerBloc.playlist$,
                    builder: (context, playlist) {
                      if (!playlist.hasData) {
                        print(playlist.data);
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      print("object");
                      print(playlist.data!);
                      print(inbetweemque.data!);
                      List<Widget> listItems = [];

                      if (inbetweemque.data!.isNotEmpty) {
                        listItems.add(AbsorbPointer(
                          child: Text(
                            "In Queue",
                          ),
                          absorbing: true,
                          key: Key("text1"),
                        ));
                      }

                      listItems
                        ..addAll(List<Widget>.generate(
                            inbetweemque.data!.length,
                            (index) => SongListItem(
                                  playerBloc: _playerBloc,
                                  song: inbetweemque.data![index],
                                  key: Key('$index'),
                                  onTap:
                                      (SongModel song, PlayerBloc playerBloc) =>
                                          _playerBloc.startPlayback(
                                              inbetweemque.data!.sublist(index)
                                                ..addAll(inbetweemque.data!
                                                    .sublist(0, index))),
                                  left: IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      _playerBloc.removeQueueItem(
                                          inbetweemque.data![index].uri!);
                                    },
                                  ),
                                )))
                        ..add(AbsorbPointer(
                          child: Text(
                            "From Playlist",
                          ),
                          absorbing: true,
                          key: Key("text2"),
                        ))
                        ..addAll(List<Widget>.generate(
                            playlist.data!.length,
                            (index) => SongListItem(
                                  playerBloc: _playerBloc,
                                  song: playlist.data![index],
                                  key: Key('p$index'),
                                  onTap:
                                      (SongModel song, PlayerBloc playerBloc) =>
                                          _playerBloc.startPlayback(
                                              playlist.data!.sublist(index)
                                                ..addAll(playlist.data!
                                                    .sublist(0, index))),
                                  left: IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      _playerBloc.removeQueueItem(
                                          playlist.data![index].uri!);
                                    },
                                  ),
                                )));

                      return ReorderableListView(
                        padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
                        children: listItems,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex == 0) {
                            return;
                          }
                          //_playerBloc.switchQueueItems(
                          // newIndex, snapshot.data![oldIndex].uri!);
                        },
                      );
                    });
              },
            ),
          ),
        ));
  }
}
