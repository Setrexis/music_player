import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.info),
              onTap: () => showAboutDialog(
                  context: context,
                  applicationIcon: Icon(Icons.music_note),
                  applicationName: "Music Player",
                  applicationVersion: "0.01",
                  applicationLegalese: "bla bla bla Info Text"),
              title: Text("Moore info"),
            )
          ],
        ),
      ),
    );
  }
}
