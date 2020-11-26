import 'package:equatable/equatable.dart';

class Station extends Equatable {
  final String id;
  final String rid;
  final String title;
  final String genre;
  final String ct;
  final String logo;

  const Station({
    this.genre,
    this.ct,
    this.logo,
    this.id,
    this.title,
    this.rid,
  });

  @override
  List<Object> get props => [id, rid, title, logo, ct, genre];

  @override
  String toString() => 'Station { id: $id, name: $title }';
}
