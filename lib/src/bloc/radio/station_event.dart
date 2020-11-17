import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

abstract class StationEvent extends Equatable {
  const StationEvent();
  @override
  List<Object> get props => [];
}

class StationFetched extends StationEvent {}

class StationSearch extends StationEvent {
  final String search;

  const StationSearch({@required this.search}) : assert(search != null);

  @override
  List<Object> get props => [search];
}
