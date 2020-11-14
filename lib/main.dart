import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/home.dart';
import 'package:music_player/src/bloc/AplicationBloc.dart';
import 'package:music_player/src/bloc/BlocProvider.dart';

void main() {
  runApp(MyApp());
}

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class MyApp extends StatelessWidget {
  final ApplicationBloc bloc = ApplicationBloc();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark().copyWith(
          accentColor: Color(0xFF4989a2),
          iconTheme: IconThemeData().copyWith(color: Color(0xFF4e606e)),
          primaryColor: Colors.white,
          textTheme: GoogleFonts.rubikTextTheme()),
      home: AudioServiceWidget(child: BlocProvider(bloc: bloc, child: Home())),
    );
  }
}
