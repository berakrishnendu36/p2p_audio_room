import 'package:audiochat/models/connection.dart';
import 'package:audiochat/models/socket_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ignore: must_be_immutable
class ChatScreen extends StatefulWidget {
  ChatScreen({Key? key, required String room})
      : roomId = room,
        super(key: key);
  String roomId;
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _offer = false;
  bool _isAudioEnabled = true;
  //RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  //RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();

  late IO.Socket _socket;

  //final String socketId = "1011";

  final Map<String, dynamic> configuration = {
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
      {
        "url": 'turn:192.158.29.39:3478?transport=udp',
        "credential": 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
        "username": '28224511:1379330808'
      }
    ]
  };

  final Map<String, dynamic> offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
    },
    "optional": [],
  };

  Map<String, Connection> connections = {};

  //These are for manual testing without a heroku server

  @override
  dispose() {
    //print("disconnected");
    _socket.disconnect();
    super.dispose();
  }

  @override
  void initState() {
    initRenderer();
    //print(widget.roomId);

    _socket = IO.io(
      'https://p2paudio-server.herokuapp.com',
      //'http://10.0.2.2:5000',
      //'http://localhost:5000',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      },
    );
    _socket.connect();

    _socket.onConnect((data) async {
      //print('Socket connected');
      _socket.emit("join", widget.roomId);
    });

    //Offer received from other client which is set as remote description and answer is created and transmitted
    _socket.on("receiveOffer", (data) async {
      //print("Offer received");
      SocketId id = SocketId.fromJson(data["socketId"]);
      await _createConnection(id);
      String sdp = write(data["session"], null);

      RTCSessionDescription description =
          new RTCSessionDescription(sdp, 'offer');

      await connections[id.destinationId]!
          .peer
          .setRemoteDescription(description);

      RTCSessionDescription description2 = await connections[id.destinationId]!
          .peer
          .createAnswer({'offerToReceiveAudio': 1});

      var session = parse(description2.sdp.toString());

      connections[id.destinationId]!.peer.setLocalDescription(description2);
      _socket
          .emit("createAnswer", {"session": session, "socketId": id.toJson()});
    });

    //Answer received from originating client which is set as remote description
    _socket.on("receiveAnswer", (data) async {
      //print("Answer received");
      String sdp = write(data["session"], null);

      RTCSessionDescription description =
          new RTCSessionDescription(sdp, 'answer');

      await connections[data["socketId"]["destinationId"]]!
          .peer
          .setRemoteDescription(description);
    });

    //Candidate received from answerer which is added to the peer connection
    //THIS COMPELETES THE CONNECTION PROCEDURE
    _socket.on("receiveCandidate", (data) async {
      //print("Candidate received");
      dynamic candidate = new RTCIceCandidate(data['candidate']['candidate'],
          data['candidate']['sdpMid'], data['candidate']['sdpMlineIndex']);
      await connections[data['socketId']['destinationId']]!
          .peer
          .addCandidate(candidate);
    });

    _socket.on("userDisconnected", (id) async {
      await connections[id]!.renderer.dispose();
      await connections[id]!.peer.close();
      connections.remove(id);
    });

    _socket.onConnectError((data) {
      //print(data);
    });
    super.initState();
  }

  Future<void> _createConnection(id) async {
    //print("Create connection");
    connections[id.destinationId] = new Connection();
    connections[id.destinationId]!.renderer = new RTCVideoRenderer();
    await connections[id.destinationId]!.renderer.initialize();
    connections[id.destinationId]!.peer =
        await createPeerConnection(configuration, offerSdpConstraints);
    connections[id.destinationId]!.peer.addStream(_localStream!);

    connections[id.destinationId]!.peer.onIceCandidate = (e) {
      //Transmitting candidate data from answerer to caller
      if (e.candidate != null && !_offer) {
        _socket.emit("sendCandidate", {
          "candidate": {
            'candidate': e.candidate.toString(),
            'sdpMid': e.sdpMid.toString(),
            'sdpMlineIndex': e.sdpMlineIndex,
          },
          "socketId": id.toJson(),
        });
      }
    };

    connections[id.destinationId]!.peer.onIceConnectionState = (e) {
      //print(e);
    };

    connections[id.destinationId]!.peer.onAddStream = (stream) {
      //print('addStream: ' + stream.id);
      connections[id.destinationId]!.renderer.srcObject = stream;
    };
  }

  initRenderer() async {
    await _localRenderer.initialize();
    _localStream = await _getUserMedia();
  }

  //Get audio stream and save to local
  _getUserMedia() async {
    final Map<String, dynamic> constraints = {'audio': true, 'video': false};

    MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);

    _localRenderer.srcObject = stream;
    // _localRenderer.mirror = true;

    return stream;
  }

  Future<void> createOffer(id) async {
    RTCSessionDescription description = await connections[id.destinationId]!
        .peer
        .createOffer({'offerToReceiveAudio': 1});
    var session = parse(description.sdp.toString());
    _socket.emit("createOffer", {"session": session, "socketId": id.toJson()});
    setState(() {
      _offer = true;
    });

    connections[id.destinationId]!.peer.setLocalDescription(description);
  }

//This is the method that initiates the connection
  void _createOfferAndConnect() async {
    _socket.emitWithAck("newConnect", widget.roomId, ack: (data) async {
      // print(
      //     "OriginId: ${data["originId"]}, DestinationIds: ${data["destinationIds"]}");

      data["destinationIds"].forEach((destinationId) async {
        if (connections[destinationId] == null) {
          SocketId id = new SocketId(
              originId: data["originId"], destinationId: destinationId);
          await _createConnection(id);
          await createOffer(id);
        }
      });
      // await _createConnection(socketId);
      // await createOffer(socketId);
    });
  }

  //enable audio
  void _enableAudio() async {
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = true;
    });
  }

  //disable audio
  void _disableAudio() async {
    _localStream!.getAudioTracks().forEach((track) {
      track.enabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _socket.disconnect();
        await _localRenderer.dispose();
        for (var key in connections.keys) {
          await connections[key]!.renderer.dispose();
          await connections[key]!.peer.close();
          connections.remove(key);
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("P2P Audio Room"),
        ),
        body: Container(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              height: 40,
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: ElevatedButton(
                onPressed: _createOfferAndConnect,
                child: Text('Connect'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 20,
            ),
            SizedBox(
                height: 50,
                width: 150,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isAudioEnabled) {
                      _disableAudio();
                    } else {
                      _enableAudio();
                    }
                    setState(() {
                      _isAudioEnabled = !_isAudioEnabled;
                    });
                  },
                  child:
                      Text('Mic is ${_isAudioEnabled == true ? "on" : "off"}'),
                ))
          ],
        )),
      ),
    );
  }
}
