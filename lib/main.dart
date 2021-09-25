import 'dart:convert';
// import 'dart:html';

import 'package:audiochat/screens/chat_screen.dart';
import 'package:audiochat/screens/join_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:flutter/services.dart';

import 'models/connection.dart';
import 'models/socket_id.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: JoinScreen(),
    );
  }
}
