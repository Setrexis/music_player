import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:music_player/player.dart';
import 'package:music_player/src/net/radio.dart';
import 'package:music_player/src/Utility.dart';
import 'package:xml/xml.dart';

class OnlineRadioTabSearch extends StatefulWidget {
  final double bottomPadding;

  const OnlineRadioTabSearch({Key key, this.bottomPadding}) : super(key: key);
  @override
  _OnlineRadioTabSearchState createState() => _OnlineRadioTabSearchState();
}

class _OnlineRadioTabSearchState extends State<OnlineRadioTabSearch> {
  final OnlineRadio r = OnlineRadio();
  Future<XmlDocument> data;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    data = r.getTop500();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<XmlDocument>(
      future: data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var data = snapshot.data
            .findElements("stationlist")
            .toList()[0]
            .findAllElements("station")
            .toList();
        print(data);

        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: false,
              padding: EdgeInsets.only(bottom: widget.bottomPadding),
              itemBuilder: (context, index) {
                XmlElement station = data[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: LinearGradient(
                            colors: [Color(0xFF2d4351), Color(0xFF1f313d)],
                            begin: Alignment.centerLeft,
                            end: Alignment.bottomRight,
                            stops: [0.0, 1.0],
                            tileMode: TileMode.clamp)),
                    child: InkWell(
                      onTap: () => PlayerService.startRadioPlay(data, station),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              child: station.getAttribute("logo") == null
                                  ? Icon(Icons.radio)
                                  : Image.network(
                                      station.getAttribute("logo"),
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.radio),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.getAttribute("name"),
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    station.getAttribute("ct") ??
                                        station.getAttribute("genre") ??
                                        "",
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(color: Color(0xFF4e606e)),
                                  ),
                                ],
                              ),
                            ),
                            (AudioService.currentMediaItem?.genre ?? 0) ==
                                    station.getAttribute("id")
                                ? Icon(
                                    Icons.bar_chart,
                                    color: Color(0xFF4989a2),
                                  )
                                : Container()
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              itemCount: data.length,
            ),
          ),
        );
      },
    );
  }
}
