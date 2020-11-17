import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:music_player/src/bloc/radio/station.dart';
import 'package:xml/xml.dart';

import 'bloc.dart';
import 'dart:async';

class StationBloc extends Bloc<StationEvent, StationState> {
  final http.Client httpClient;

  StationBloc({@required this.httpClient}) : super(StationInitial());

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
        if (currentState is StationInitial) {
          final stations = await _fetchPosts(0, 20, null);
          yield StationSuccess(station: stations, hasReachedMax: false);
          return;
        }
        if (currentState is StationSuccess) {
          final station =
              await _fetchPosts(currentState.station.length, 20, null);
          yield station.isEmpty
              ? currentState.copyWith(hasReachedMax: true)
              : StationSuccess(
                  station: currentState.station + station,
                  hasReachedMax: false,
                );
        }
      } catch (_) {
        yield StationFailure();
      }
    } else if (event is StationSearch && !_hasReachedMax(currentState)) {
      try {
        if (currentState is StationInitial) {
          final stations = await _fetchPosts(0, 20, event.search);
          yield StationSuccess(station: stations, hasReachedMax: false);
          return;
        }
        if (currentState is StationSuccess) {
          final station =
              await _fetchPosts(currentState.station.length, 20, event.search);
          yield station.isEmpty
              ? currentState.copyWith(hasReachedMax: true)
              : StationSuccess(
                  station: currentState.station + station,
                  hasReachedMax: false,
                );
        }
      } catch (_) {
        yield StationFailure();
      }
    }
  }

  bool _hasReachedMax(StationState state) =>
      state is StationSuccess && state.hasReachedMax;

  Future<List<Station>> _fetchPosts(
      int startIndex, int limit, String search) async {
    http.Response r;

    if (search != null) {
      print("search");
      search.replaceAll(" ", "+");
      r = await httpClient.get(
          'http://api.shoutcast.com/legacy/stationsearch?k=sh1t7hyn3Kh0jhlV&search=$search&limit=$startIndex,$limit');
    } else {
      r = await httpClient
          .get('https://api.shoutcast.com/legacy/Top500?k=sh1t7hyn3Kh0jhlV');
    }

    if (r.statusCode == 200) {
      final data = XmlDocument.parse(r.body)
          .findElements("stationlist")
          .toList()[0]
          .findElements("station");
      return data.map((rawPost) {
        return Station(
            id: rawPost.getAttribute('id'),
            title: rawPost.getAttribute('name'),
            genre: rawPost.getAttribute('genre'),
            ct: rawPost.getAttribute('genre'),
            logo: rawPost.getAttribute('logo') ?? "");
      }).toList();
    } else {
      throw Exception('error fetching station');
    }
  }
}
