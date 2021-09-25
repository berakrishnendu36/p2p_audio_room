import 'package:audiochat/screens/chat_screen.dart';
import 'package:flutter/material.dart';

class JoinScreen extends StatefulWidget {
  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  TextEditingController _roomController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("P2P Audio Room"),
        ),
        body: Container(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Join a room",
                  style: TextStyle(fontSize: 28.0),
                ),
                SizedBox(
                  height: 20.0,
                  width: double.infinity,
                ),
                Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Room Id",
                          hintText: "Enter 4 digit room id (E.g.- 1234)",
                        ))),
                SizedBox(
                  height: 20.0,
                  width: double.infinity,
                ),
                SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                        child: Text("Join"),
                        onPressed: () async {
                          if (_roomController.text.length == 4) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                        room: _roomController.text)));
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                      title: Text("Error"),
                                      content: Text(
                                          "Please enter a 4 digit room id"),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text("Ok"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        )
                                      ]);
                                });
                          }
                        }))
              ]),
        ));
  }
}
