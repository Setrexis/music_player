import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:meta/meta.dart';
import 'package:music_player/src/bloc/radio/station.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();
  @override
  List<Object> get props => [];
}

class PlayerPlayRadio extends PlayerEvent {
  final Station station;
  final List<Station> stations;

  PlayerPlayRadio(this.station, this.stations)
      : assert(station != null && stations != null);

  @override
  List<Object> get props => [station, stations];
}

class PlayerStop extends PlayerEvent {}

class PlayerPlay extends PlayerEvent {
  final SongInfo songInfo;
  final List<SongInfo> playlist;

  PlayerPlay(this.songInfo, this.playlist)
      : assert(songInfo != null && playlist != null);

  @override
  List<Object> get props => [songInfo, playlist];
}
