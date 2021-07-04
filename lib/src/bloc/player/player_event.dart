import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();
  @override
  List<Object?> get props => [];
}

class PlayerStop extends PlayerEvent {}

class PlayerPlay extends PlayerEvent {
  final SongModel songInfo;
  final List<SongModel>? playlist;

  PlayerPlay(this.songInfo, this.playlist) : assert(playlist != null);

  @override
  List<Object?> get props => [songInfo, playlist];
}
