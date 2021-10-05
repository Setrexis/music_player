import 'package:flutter/material.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';

class InheritedProvider extends InheritedWidget {
  final PlayerBloc inheritedData;
  InheritedProvider({
     required Widget child,
      required this.inheritedData,
     }) : super(child: child);
  @override
  bool updateShouldNotify(InheritedProvider oldWidget) => inheritedData != oldWidget.inheritedData;
  static InheritedProvider? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<InheritedProvider>();
}