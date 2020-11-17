import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object> get props => [];
}

class PlayerInitial extends PlayerState {
  final MediaItem curruentMediaItem;
  final bool radio;

  const PlayerInitial(this.curruentMediaItem, this.radio);

  @override
  List<Object> get props => [curruentMediaItem];
}

class PlayerEmpty extends PlayerState {}

class PlayerFailure extends PlayerState {}

class PlayerPlaying extends PlayerState {
  final List<MediaItem> currentMediaItemPlaylist;
  final MediaItem curruentMediaItem;
  final bool radio;

  const PlayerPlaying(
      this.currentMediaItemPlaylist, this.curruentMediaItem, this.radio);

  @override
  List<Object> get props => [curruentMediaItem, currentMediaItemPlaylist];
}
