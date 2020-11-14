import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:music_player/src/bloc/radio/station.dart';

import 'package:music_player/src/bloc/radio/station_event.dart';
import 'package:music_player/src/bloc/radio/station_state.dart';
import 'dart:async';
import 'dart:convert';

class PostBloc extends Bloc<StationEvent, StationState> {
  final http.Client httpClient;

  PostBloc({@required this.httpClient}) : super(PostInitial());

  @override
  Stream<Transition<StationEvent, StationState>> transformEvents(
    Stream<StationEvent> events,
    TransitionFunction<StationEvent, StationState> transitionFn,
  ) {
    return super.transformEvents(
      events.debounceTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<StationState> mapEventToState(StationEvent event) async* {
    final currentState = state;
    if (event is StationFetched && !_hasReachedMax(currentState)) {
      try {
        if (currentState is PostInitial) {
          final station = await _fetchPosts(0, 20);
          yield StationSuccess(station: station, hasReachedMax: false);
          return;
        }
        if (currentState is StationSuccess) {
          final station = await _fetchPosts(currentState.station.length, 20);
          yield station.isEmpty
              ? currentState.copyWith(hasReachedMax: true)
              : StationSuccess(
                  station: currentState.station + station,
                  hasReachedMax: false,
                );
        }
      } catch (_) {
        yield PostFailure();
      }
    }
  }

  bool _hasReachedMax(StationState state) =>
      state is StationSuccess && state.hasReachedMax;

  Future<List<Station>> _fetchPosts(int startIndex, int limit) async {
    final response = await httpClient.get(
        'https://jsonplaceholder.typicode.com/station?_start=$startIndex&_limit=$limit');
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((rawPost) {
        return Station(
          id: rawPost['id'],
          title: rawPost['title'],
          genre: rawPost['body'],
        );
      }).toList();
    } else {
      throw Exception('error fetching station');
    }
  }
}
