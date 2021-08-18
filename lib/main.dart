import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/home.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:audio_session/audio_session.dart';

late AudioHandler _audioHandler;

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
    return BlocProvider(
      create: (context) => PlayerBloc(_audioHandler),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData.light().copyWith(
          accentColor: Color(0xffff16ce),
          iconTheme: IconThemeData().copyWith(color: Colors.white),
          primaryColor: Color(0xFF260e43),
          textTheme: GoogleFonts.mavenProTextTheme(),
        ),
        home: Home(),
      ),
    );
  }
}
