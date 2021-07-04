import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player/src/ui/widget/CommonWidgets.dart';

class DetailPage extends StatefulWidget {
  final Widget? child;
  final String? title;

  const DetailPage({Key? key, this.child, this.title}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: Text(widget.title!),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => print("Search"),
              color: Color(0xFF55889d),
            )
          ],
          leading: IconButton(
            color: Color(0xFF586a78),
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: StreamBuilder<bool>(
            stream: AudioService.runningStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.active) {
                // Don't show anything until we've ascertained whether or not the
                // service is running, since we want to show a different UI in
                // each case.
                return SizedBox();
              }
              final running = snapshot.data ?? false;

              return Stack(children: [
                Padding(
                  padding: EdgeInsets.only(bottom: (running ? 90 : 0)),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF374a59), Color(0xFF1a2a37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 1.0],
                            tileMode: TileMode.clamp)),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 90.0),
                      child: widget.child,
                    ),
                  ),
                ),
                BottomPlayerBar()
              ]);
            }));
  }
}
