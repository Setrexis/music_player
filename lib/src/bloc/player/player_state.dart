import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerEmpty extends PlayerState {}

class PlayerFailure extends PlayerState {}

class PlayerPlaying extends PlayerState {}
