import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
/*
// ignore: must_be_immutable
class AlbumArtworkImage extends StatelessWidget {
  final String id;
  final String? albumArtwork;
  double? borderRadius;
  Size? size;

  AlbumArtworkImage(
    this.id,
    this.albumArtwork, {
    this.borderRadius,
    this.size,
    Key? key,
  });

  DeviceModel deviceInfo = await OnAudioQuery().queryDeviceInfo();

  @override
  Widget build(BuildContext context) {
    size ??= Size(250, 250);
    borderRadius ??= 11;

    
  }
}*/

// ignore: must_be_immutable
class AlbumArtBackground extends StatelessWidget {
  final Widget child;
  final String id;
  final String? artwork;

  AlbumArtBackground(
      {Key? key, required this.child, required this.id, this.artwork})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.maxFinite,
      decoration: BoxDecoration(
        image: artwork == null
            ? DecorationImage(
                image: FileImage(File(artwork!)),
                fit: BoxFit.cover,
              )
            : DecorationImage(
                image: FileImage(File(artwork!)),
                fit: BoxFit.cover,
              ),
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
  }
}
