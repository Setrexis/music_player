import 'package:equatable/equatable.dart';

import 'package:music_player/src/bloc/radio/station.dart';

abstract class StationState extends Equatable {
  const StationState();

  @override
  List<Object> get props => [];
}

class StationInitial extends StationState {}

class StationFailure extends StationState {}

class StationSuccess extends StationState {
  final List<Station> station;
  final bool hasReachedMax;

  const StationSuccess({
    this.station,
    this.hasReachedMax,
  });

  StationSuccess copyWith({
    List<Station> station,
    bool hasReachedMax,
  }) {
    return StationSuccess(
      station: station ?? this.station,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [station, hasReachedMax];

  @override
  String toString() =>
      'stationuccess { station: ${station.length}, hasReachedMax: $hasReachedMax }';
}
