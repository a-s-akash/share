import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:schnell_luminator/utils/error_messages.dart';

import '../utils/asset_folder.dart';

class UpdatePage extends ConsumerWidget {
  static final GlobalKey<FormState> _key = GlobalKey();

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final bool visible = true;

  UpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        body: Form(key: _key, child: _body(context, ref)),
      ),
    );
  }

  _body(BuildContext context, WidgetRef ref) => ListView(
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(15),
              alignment: Alignment.center,
              child: Column(children: <Widget>[_formUI(context, ref)]))
        ],
      );

  _formUI(BuildContext context, WidgetRef ref) {
    final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

    remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(milliseconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    remoteConfig.fetchAndActivate();
    String releaseNotes = remoteConfig.getString('release_notes');
    String latestVersion = remoteConfig.getString('app_version');
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    TextStyle featuresStyle = TextStyle(
      fontSize: 12.0,
      color: Theme.of(context).secondaryHeaderColor,
    );
    TextStyle featuresTitleStyle = TextStyle(
      fontSize: 14.0,
      color: Theme.of(context).secondaryHeaderColor,
      fontWeight: FontWeight.bold,
    );

    // Parse the releaseNotes JSON string
    Map<String, dynamic> releaseNotesMap = jsonDecode(releaseNotes);

    return Container(
      width: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: height * 0.3,
            width: width / 2,
            child: Image.asset(logoImage),
          ),
          Text('Luminator', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: height / 30),
          Text(ErrorMessages.updateAlert(latestVersion: latestVersion),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17)),
          SizedBox(height: height * 0.04),
          ElevatedButton(
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              backgroundColor:
                  WidgetStateProperty.all(Theme.of(context).primaryColor),
              foregroundColor:
                  WidgetStateProperty.all(Theme.of(context).canvasColor),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
            child: Text(
              "Update".toUpperCase(),
              style: const TextStyle(fontSize: 14),
            ),
            onPressed: () {
              ref.read(loginController).launchUrls();
            },
          ),
          const SizedBox(height: 35),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: width / 8),
                child: Text(
                  'Release Notes:',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                  textAlign: TextAlign.left,
                ),
              )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.only(left: 5),
              color: Theme.of(context)
                  .unselectedWidgetColor
                  .withValues(alpha: 0.1),
              width: width / 1.3,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                  children: [
                    for (String title in releaseNotesMap.keys) ...[
                      TextSpan(
                        text: '$title:\n', // title
                        style: featuresTitleStyle,
                      ),
                      for (String message in releaseNotesMap[title]) ...[
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.star,
                              size: 12,
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                          ),
                        ),
                        TextSpan(
                          text: " " + message + '\n', // message
                          style: featuresStyle,
                        ),
                      ],
                      if (releaseNotesMap.keys.last != title)
                        const WidgetSpan(
                          child: SizedBox(height: 25.0),
                        ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
