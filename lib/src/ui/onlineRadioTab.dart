import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:music_player/src/bloc/player/player_event.dart';
import 'package:music_player/src/bloc/radio/bloc.dart';
import 'package:music_player/src/bloc/radio/station.dart';
import 'package:music_player/src/net/radio.dart';
import 'package:music_player/src/Utility.dart';
import 'package:xml/xml.dart';

class OnlineRadioTabSearch extends StatefulWidget {
  final double bottomPadding;

  const OnlineRadioTabSearch({Key key, this.bottomPadding}) : super(key: key);
  @override
  _OnlineRadioTabSearchState createState() => _OnlineRadioTabSearchState();
}

class _OnlineRadioTabSearchState extends State<OnlineRadioTabSearch> {
  final OnlineRadio r = OnlineRadio();
  final _scrollController = ScrollController();
  final _scrollThreshold = 200.0;
  StationBloc _postBloc;
  PlayerBloc _playerBloc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController.addListener(_onScroll);
    _postBloc = BlocProvider.of<StationBloc>(context);
    _playerBloc = BlocProvider.of<PlayerBloc>(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= _scrollThreshold) {
      _postBloc.add(StationFetched());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StationBloc, StationState>(
      builder: (context, state) {
        if (state is StationInitial) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is StationFailure) {
          return Center(child: Text("Failed to load radio stations"));
        }

        if (state is StationSuccess) {
          if (state.station.isEmpty) {
            return Center(
              child: Text('no stations found'),
            );
          }

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: state.hasReachedMax
                    ? state.station.length
                    : state.station.length + 1,
                controller: _scrollController,
                shrinkWrap: false,
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
                itemBuilder: (context, index) {
                  return index >= state.station.length
                      ? BottomLoader()
                      : StationWidget(
                          station: state.station[index],
                          stations: state.station,
                          index: index,
                          playerBloc: _playerBloc,
                        );
                },
              ),
            ),
          );
        }
      },
    );
  }
}

class BottomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: SizedBox(
          width: 33,
          height: 33,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}

class StationWidget extends StatelessWidget {
  final Station station;
  final List<Station> stations;
  final PlayerBloc playerBloc;
  final int index;

  const StationWidget(
      {Key key,
      @required this.station,
      this.stations,
      this.playerBloc,
      this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          onTap: () => playerBloc.add(PlayerPlayRadio(
              station,
              stations
                  .getRange(
                      index,
                      index + 10 < stations.length
                          ? index + 10
                          : stations.length)
                  .toList())),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  child: station.logo == null
                      ? Icon(Icons.radio)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            station.logo,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.radio),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.65,
                        child: Text(
                          station.title ?? "",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.65,
                        child: Text(
                          station.ct ?? station.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Color(0xFF4e606e)),
                        ),
                      ),
                    ],
                  ),
                ),
                (AudioService.currentMediaItem?.genre ?? "0") == station.id
                    ? Icon(
                        Icons.bar_chart,
                        color: Color(0xFF4989a2),
                      )
                    : Container()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
