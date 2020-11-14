import 'package:equatable/equatable.dart';

class Station extends Equatable {
  final int id;
  final String title;
  final String genre;
  final String ct;
  final String logo;

  const Station({this.genre, this.ct, this.logo, this.id, this.title});

  @override
  List<Object> get props => [id, title, logo, ct, genre];

  @override
  String toString() => 'Station { id: $id, name: $title }';
}
