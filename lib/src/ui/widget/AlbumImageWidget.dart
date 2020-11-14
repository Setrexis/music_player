import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

// ignore: must_be_immutable
class AlbumArtworkImage extends StatelessWidget {
  final String id;
  final String albumArtwork;
  final ResourceType type;
  FlutterAudioQuery audioQuery;
  double borderRadius;
  Size size;

  AlbumArtworkImage(
    this.id,
    this.albumArtwork,
    this.type, {
    this.audioQuery,
    this.borderRadius,
    this.size,
    Key key,
  });

  @override
  Widget build(BuildContext context) {
    audioQuery ??= FlutterAudioQuery();
    size ??= Size(250, 250);
    borderRadius ??= 11;

    if (albumArtwork == null) {
      return FutureBuilder<Uint8List>(
          future: audioQuery.getArtwork(type: type, id: id, size: size),
          builder: (_, snapshot) {
            if (snapshot.data == null || !snapshot.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );

            if (snapshot.data.isEmpty) {
              return ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Container(child: Icon(Icons.music_note)));
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.memory(
                snapshot.data,
              ),
            );
          });
    } else {
      return ClipRRect(
        child: Image.file(
          File(albumArtwork),
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      );
    }
  }
}

// ignore: must_be_immutable
class AlbumArtBackground extends StatelessWidget {
  final Widget child;
  final String id;
  final ResourceType type;
  FlutterAudioQuery audioQuery;

  AlbumArtBackground({Key key, this.child, this.id, this.type, this.audioQuery})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    audioQuery ??= FlutterAudioQuery();

    return FutureBuilder(
        future: audioQuery.getArtwork(type: type, id: id, size: Size(100, 100)),
        builder: (context, snapshot) {
          return Container(
            height: 90,
            width: double.maxFinite,
            decoration: BoxDecoration(
              image: snapshot.hasData
                  ? DecorationImage(
                      image: MemoryImage(snapshot.data),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: snapshot.hasData ? null : Colors.transparent,
            ),
            child: ClipRRect(
              // make sure we apply clip it properly
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  alignment: Alignment.center,
                  color: Colors.grey.withOpacity(0.1),
                  child: child,
                ),
              ),
            ),
          );
        });
  }
}
