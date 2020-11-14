import 'package:equatable/equatable.dart';

abstract class StationEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class StationFetched extends StationEvent {}
