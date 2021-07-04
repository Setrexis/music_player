import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_player/AudioPlayer.dart';
import 'package:music_player/home.dart';
import 'package:music_player/src/bloc/player/player_bloc.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(),
      child: BlocProvider(
        create: (context) => PlayerBloc(),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData.dark().copyWith(
              accentColor: Color(0xFF4989a2),
              iconTheme: IconThemeData().copyWith(color: Color(0xFF4e606e)),
              primaryColor: Colors.white,
              textTheme: GoogleFonts.rubikTextTheme()),
          home: AudioServiceWidget(
            child: Home(),
          ),
        ),
      ),
    );
  }
}
