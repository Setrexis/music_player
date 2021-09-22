import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  Widget build(BuildContext context) {
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
                stream: _playerBloc.playlist$,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return ReorderableListView(
                    padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
                    children: List<Widget>.generate(
                        snapshot.data!.length,
                        (index) => SongListItem(
                              playerBloc: _playerBloc,
                              song: snapshot.data![index],
                              key: Key('$index'),
                              left: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  _playerBloc.removeQueueItem(
                                      snapshot.data![index].uri!);
                                },
                              ),
                            )),
                    onReorder: (oldIndex, newIndex) {
                      _playerBloc.switchQueueItems(
                          newIndex, snapshot.data![oldIndex].uri!);
                    },
                  );
                }),
          ),
        ));
  }
}
