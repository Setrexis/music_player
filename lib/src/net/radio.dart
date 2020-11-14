import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class OnlineRadio {
  final top500url =
      "https://api.shoutcast.com/legacy/Top500?k=sh1t7hyn3Kh0jhlV";
  final searchurl =
      "https://api.shoutcast.com/legacy/stationsearch?k=sh1t7hyn3Kh0jhlV&search=";

  static final urlRegx = RegExp(
      r"http[s]?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)");

  Future<XmlDocument> getTop500() async {
    http.Response r = await fetchTop500();

    if (r.statusCode != 200) {
      return null;
    }

    return XmlDocument.parse(r.body);
  }

  Future<http.Response> fetchTop500() {
    return http.get(top500url);
  }

  static Future<http.Response> fetchStreamUrl(String id) {
    print(id);
    return http.post("https://directory.shoutcast.com/Player/GetStreamUrl",
        body: {'station': id});
  }

  static Future<http.Response> fetchCurrentTrak(String id) {
    print(id);
    return http.post("https://directory.shoutcast.com/Player/GetCurrentTrack",
        body: {'stationID': id});
  }

  static Future<String> getStreamPath(String id) async {
    print(id);
    http.Response r = await fetchStreamUrl(id);
    print(r.body);
    return r.body.replaceAll('"', "");
  }

  static Future<String> getCurantTrak(String id) async {
    print(id);
    http.Response r = await fetchCurrentTrak(id);
    print(r.body);
    return jsonDecode(r.body)["Station"]["CurrentTrack"];
  }
}
