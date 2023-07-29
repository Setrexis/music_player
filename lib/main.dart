import 'dart:async';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/src/bloc/InheritedProvider.dart';
import 'package:music_player/src/ui/home.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:on_audio_room/on_audio_room.dart';

late AudioPlayerHandler _audioHandler;

final _defaultLightColorScheme = ThemeData.light()
    .copyWith(
        colorScheme: ThemeData.light()
            .colorScheme
            .copyWith(secondary: Color(0xffF07300), primary: Color(0xfff2e7eb)),
        primaryColorDark: Color(0xFFE06A3A),
        iconTheme: IconThemeData().copyWith(color: Colors.black),
        primaryColor: Color(0xfff2e7eb),
        primaryColorLight: Color(0xffECA100),
        textTheme: GoogleFonts.mavenProTextTheme(),
        canvasColor: Color(0xfff2e7eb),
        backgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
            titleTextStyle: TextStyle(color: Colors.black),
            toolbarTextStyle: TextStyle(color: Colors.black),
            iconTheme: IconThemeData().copyWith(color: Colors.black),
            actionsIconTheme: IconThemeData().copyWith(color: Colors.black)))
    .colorScheme;

final _defaultDarkColorScheme = ThemeData.dark()
    .copyWith(
        colorScheme: ThemeData.dark()
            .colorScheme
            .copyWith(secondary: Color(0xffF07300), primary: Color(0xff1B0E13)),
        primaryColorDark: Color(0xFFE06A3A),
        iconTheme: IconThemeData().copyWith(color: Colors.white),
        primaryColor: Color(0xff1B0E13),
        primaryColorLight: Color(0xffECA100),
        textTheme: GoogleFonts.mavenProTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme),
        canvasColor: Color(0xff1B0E13),
        backgroundColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
            titleTextStyle: TextStyle(color: Colors.white),
            toolbarTextStyle: TextStyle(color: Colors.white),
            iconTheme: IconThemeData().copyWith(color: Colors.white),
            actionsIconTheme: IconThemeData().copyWith(color: Colors.white)))
    .colorScheme;

Future<void> main() async {
  // store this in a singleton
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
        androidNotificationChannelId: 'com.ryanheise.myapp.channel.audio',
        androidNotificationChannelName: 'Music Player',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidShowNotificationBadge: true),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => InheritedProvider(
        inheritedData: PlayerBloc(_audioHandler),
        child: App(darkDynamic: darkDynamic, lightDynamic: lightDynamic),
      ),
    );
  }
}

class App extends StatefulWidget {
  const App({
    Key? key,
    required this.lightDynamic,
    required this.darkDynamic,
  }) : super(key: key);

  final ColorScheme? lightDynamic;
  final ColorScheme? darkDynamic;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final PlayerBloc _playerBloc;
  late ColorScheme? lightDynamic;
  late ColorScheme? darkDynamic;

  Future<ColorScheme> colorScheme(
      ImageProvider image, Brightness brightness) async {
    return await ColorScheme.fromImageProvider(
        provider: image, brightness: brightness);
  }

  @override
  void initState() {
    lightDynamic = widget.lightDynamic;
    darkDynamic = widget.darkDynamic;
    super.initState();
    Timer(Duration(milliseconds: 300), () {
      setUpColorScheme();
    });
  }

  @override
  void dispose() {
    _playerBloc.dispose();
    super.dispose();
  }

  void setUpColorScheme() async {
    _playerBloc = InheritedProvider.of(context)!.inheritedData;
    _playerBloc.audioHandler.mediaItem.listen((event) async {
      if (event != null && event.extras != null) {
        Uint8List? image = await OnAudioQuery()
            .queryArtwork(event.extras!["id"], ArtworkType.AUDIO);
        if (image != null) {
          lightDynamic =
              await colorScheme(MemoryImage(image), Brightness.light);
          darkDynamic = await colorScheme(MemoryImage(image), Brightness.dark);
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: lightDynamic,
        useMaterial3: true,
        textTheme: GoogleFonts.mavenProTextTheme(),
        colorSchemeSeed:
            lightDynamic == null ? Color.fromRGBO(238, 99, 7, 1) : null,
      ),
      darkTheme: ThemeData(
          colorScheme: darkDynamic,
          useMaterial3: true,
          textTheme: GoogleFonts.mavenProTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme),
          colorSchemeSeed:
              darkDynamic == null ? Color.fromRGBO(238, 99, 7, 1) : null),
      home: Home(),
    );
  }
}
