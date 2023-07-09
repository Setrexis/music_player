import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

